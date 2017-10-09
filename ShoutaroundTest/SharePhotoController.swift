//
//  SharePhotoController.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/28/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import GeoFire
import GoogleMaps
import SwiftyJSON
import SwiftLocation
import Alamofire

class SharePhotoController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate,UICollectionViewDataSource, UITextViewDelegate, CLLocationManagerDelegate, LocationSearchControllerDelegate {
   
    
    
    func didUpdate(lat: Double?, long: Double?, locationAdress: String?, locationName: String?, locationGooglePlaceID: String?) {
        self.selectedImageLocation = CLLocation.init(latitude: lat!, longitude: long!)
        self.selectedPostGooglePlaceID = locationGooglePlaceID
        self.selectedImageLocationName = locationName
        self.selectedImageLocationAdress = locationAdress
        
    }

    
    
    let locationCellID = "locationCellID"
    let emojiCellID = "emojiCellID"
    let captionDefault = "Insert Caption Here"
    let emojiDefault = "😍🐮🍔🇺🇸🔥"
    
    var selectedPostLocation: CLLocation? = nil {
        
        didSet{
            
            if selectedPostLocation == nil {
                
                self.locationNameLabel.text =  "No GPS Location"
                self.locationAdressLabel.text = ""
                self.locationCancelButton.alpha = 0
            }
            else {
                self.locationCancelButton.alpha = 1
            }
            
        }
        
    }
    
    var selectedPostGooglePlaceID: String? = nil
    var selectedGoogleLocationIndex: Int? = nil
    
    var emojiViews: Array<UICollectionView>?
    let maxEmojis = 5
    
    var selectedEmojis: String = "" {
        
        didSet{
            self.emojiTextView.text = selectedEmojis
            
            if selectedEmojis.characters.count > 0 {
                self.emojiCancelButton.alpha = 1
                self.emojiTextView.alpha = 1
            } else {
                self.emojiCancelButton.alpha = 0
                self.emojiTextView.alpha = 0.25
                self.resetEmojiTextView()
            }
        
            
            print(selectedEmojis)
            
            for views in emojiViews! {
                views.reloadData()
            }
        }
    }
    
    
    var selectedImage: UIImage? {
        didSet{
            self.imageView.image = selectedImage
        }
    }
    
    
    var selectedImageLocationName:String?{
        didSet {
            locationNameLabel.text = selectedImageLocationName
        }
    }
    
    
    var selectedImageLocationAdress:String?{
        didSet {
            locationAdressLabel.text = selectedImageLocationAdress
        }
    }

    
    var selectedImageLocation:CLLocation?{

        didSet {

            let postLatitude:String! = String(format:"%.4f",(selectedImageLocation?.coordinate.latitude)!)
            let postLongitude:String! = String(format:"%.4f",(selectedImageLocation?.coordinate.longitude)!)
            var GPSLabelText:String?
            
            if selectedImageLocation?.coordinate.latitude != 0 && selectedImageLocation?.coordinate.longitude != 0 {
                
                self.selectedImageLocationName = "GPS: " + " (" + postLatitude + "," + postLongitude + ")"
                self.selectedPostLocation = selectedImageLocation
                //self.locationCancelButton.alpha = 1
                
                googleReverseGPS(GPSLocation: selectedImageLocation!)
                googleLocationSearch(GPSLocation: selectedImageLocation!)
                
                //appleCurrentLocation(selectedImageLocation!)
                
                // Default Location is selectedImageLocation
                
                self.placesCollectionView.reloadData()

            } else {

                locationNameLabel.text =  "No GPS Location"
                self.selectedImageLocationAdress = ""
                self.selectedPostLocation = nil
                
                // No Geofire Data is saved if location is empty
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handleShare))
        
        setupImageAndTextViews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {

        // Invalidate Layout so that after location search it will not crash
        
        print("View will appear")
        self.placesCollectionView.collectionViewLayout.invalidateLayout()
        self.Emoji1CollectionView.collectionViewLayout.invalidateLayout()
        self.Emoji2CollectionView.collectionViewLayout.invalidateLayout()
        self.Emoji3CollectionView.collectionViewLayout.invalidateLayout()
        self.Emoji4CollectionView.collectionViewLayout.invalidateLayout()
        
    }
    

    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .red
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    
    let captionTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 14)
        return tv
    }()
    
    let emojiTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 20)
        tv.textAlignment = NSTextAlignment.right
        
        return tv
    }()
    
    let emojiCancelButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "cancel_shadow").withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.backgroundColor = UIColor.gray
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        
        button.addTarget(self, action: #selector(cancelEmoji), for: .touchUpInside)
        return button
        
    } ()
    
    func cancelEmoji(){
        
        emojiTextView.text = nil
        self.resetSelectedEmojis()
        
    }
    
    func resetSelectedEmojis(){
        self.selectedEmojis = ""
    }
    
    let locationNameLabel: UILabel = {
        let tv = LocationLabel()
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.backgroundColor = UIColor.white
        return tv
    }()
    
    let locationIcon: UILabel = {
        let tv = UILabel()
        tv.font = UIFont.systemFont(ofSize: 30)
        tv.text = "📍"
        tv.textAlignment = NSTextAlignment.center
        tv.backgroundColor = UIColor.white
        return tv
    }()

    
    let locationAdressLabel: UILabel = {
        let tv = LocationLabel()
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.backgroundColor = UIColor.white
        return tv
    }()
    
    let locationCancelButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "cancel_shadow").withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.backgroundColor = UIColor.gray
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        
        button.addTarget(self, action: #selector(cancelLocation), for: .touchUpInside)
        return button
        
    } ()
    
    func cancelLocation(){
        
        selectedPostLocation = nil
        
    }
    
    let locationSearchButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.backgroundColor = UIColor.gray
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        
        button.addTarget(self, action: #selector(locationSearch), for: .touchUpInside)
        return button
        
    } ()
    
    func locationSearch(){
        
        let locationSearchController = LocationSearchController()

        locationSearchController.selectedLocation = self.selectedPostLocation
        locationSearchController.refreshMap(long: (self.selectedPostLocation?.coordinate.longitude)!, lat: (self.selectedPostLocation?.coordinate.latitude)!, name: self.locationNameLabel.text, adress: self.locationAdressLabel.text)
        locationSearchController.selectedGooglePlaceID = self.selectedPostGooglePlaceID
        locationSearchController.delegate = self
        
        navigationController?.pushViewController(locationSearchController, animated: true)
        
    }
    
    let adressIcon: UILabel = {
        let tv = UILabel()
        tv.font = UIFont.systemFont(ofSize: 30)
        tv.text = "📮"
        tv.textAlignment = NSTextAlignment.center
        tv.backgroundColor = UIColor.white
        return tv
    }()
    
    let placesCollectionView: UICollectionView = {

        let uploadLocationTagList = UploadLocationTagList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        
        return cv
    }()
    
    let Emoji1CollectionView: UICollectionView = {
        
        let uploadEmojiList = UploadEmojiList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.tag = 0
        
        return cv
    }()
    
    let Emoji2CollectionView: UICollectionView = {
        
        let uploadEmojiList = UploadEmojiList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.tag = 1
        
        return cv
    }()
    
    let Emoji3CollectionView: UICollectionView = {
        
        let uploadEmojiList = UploadEmojiList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.tag = 2
        
        return cv
    }()
    
    let Emoji4CollectionView: UICollectionView = {
        
        let uploadEmojiList = UploadEmojiList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.tag = 3
        
        return cv
    }()
    
    fileprivate func setupImageAndTextViews() {
        let containerView = UIView()
        containerView.backgroundColor = .white

// Photo and Caption Container View
        
        view.addSubview(containerView)
        containerView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 100)
        
        view.addSubview(imageView)
        imageView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: nil, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, paddingRight: 0, width: 84, height: 0)
        
        view.addSubview(emojiCancelButton)
        emojiCancelButton.anchor(top: nil, left: nil, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 4, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 10, height: 10)
        emojiCancelButton.centerYAnchor.constraint(equalTo: emojiTextView.centerYAnchor)
        emojiCancelButton.alpha = 0
        
        view.addSubview(emojiTextView)
        emojiTextView.anchor(top: nil, left: imageView.rightAnchor, bottom: containerView.bottomAnchor, right: emojiCancelButton.leftAnchor, paddingTop: 0, paddingLeft: 4, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        emojiTextView.delegate  = self
        
        view.addSubview(captionTextView)
        captionTextView.anchor(top: containerView.topAnchor, left: imageView.rightAnchor, bottom: emojiTextView.topAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 4, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        captionTextView.delegate = self
        
        
        
// Location Container View
        
        let LocationContainerView = UIView()
        LocationContainerView.backgroundColor = .yellow
        
        view.addSubview(LocationContainerView)
        LocationContainerView.anchor(top: containerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 150)
        
        view.addSubview(locationIcon)
        locationIcon.anchor(top: LocationContainerView.topAnchor, left: LocationContainerView.leftAnchor, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 40, height: 40)
        locationIcon.adjustsFontSizeToFitWidth = true
        
        view.addSubview(locationNameLabel)
        locationNameLabel.anchor(top: LocationContainerView.topAnchor, left: locationIcon.rightAnchor, bottom: nil, right: LocationContainerView.rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 40)

        view.addSubview(locationCancelButton)
        locationCancelButton.anchor(top: LocationContainerView.topAnchor, left: nil, bottom: nil, right: locationNameLabel.rightAnchor, paddingTop: 18, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 20, height: 20)
        
        view.addSubview(adressIcon)
        adressIcon.anchor(top: locationIcon.bottomAnchor, left: LocationContainerView.leftAnchor, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 40, height: 40)
        adressIcon.adjustsFontSizeToFitWidth = true
        
        view.addSubview(locationAdressLabel)
        locationAdressLabel.anchor(top: locationNameLabel.bottomAnchor, left: adressIcon.rightAnchor, bottom: nil, right: LocationContainerView.rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 40)
        
        view.addSubview(locationSearchButton)
        locationSearchButton.anchor(top: locationAdressLabel.topAnchor, left: nil, bottom: nil, right: locationAdressLabel.rightAnchor, paddingTop: 18, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 20, height: 20)
        
        
        view.addSubview(placesCollectionView)
        placesCollectionView.anchor(top: locationAdressLabel.bottomAnchor, left: LocationContainerView.leftAnchor, bottom: nil, right: LocationContainerView.rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 40)
        placesCollectionView.backgroundColor = UIColor.white
        placesCollectionView.register(UploadLocationCell.self, forCellWithReuseIdentifier: locationCellID)
        placesCollectionView.delegate = self
        placesCollectionView.dataSource = self
        
// Emoji Container View
        
        let EmojiContainerView = UIView()
        EmojiContainerView.backgroundColor = .green
        

        
        view.addSubview(EmojiContainerView)
        EmojiContainerView.anchor(top: LocationContainerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: (EmojiSize.width + 2) * 4)
        
        view.addSubview(Emoji1CollectionView)
        view.addSubview(Emoji2CollectionView)
        view.addSubview(Emoji3CollectionView)
        view.addSubview(Emoji4CollectionView)
        

        emojiViews = [Emoji1CollectionView, Emoji2CollectionView, Emoji3CollectionView, Emoji4CollectionView]
        
        for (index,views) in emojiViews!.enumerated() {
            
            if index == 0 {
                views.anchor(top: EmojiContainerView.topAnchor, left: EmojiContainerView.leftAnchor, bottom: nil, right: EmojiContainerView.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: EmojiSize.width+2)
            } else {
                views.anchor(top: emojiViews![index-1].bottomAnchor, left: EmojiContainerView.leftAnchor, bottom: nil, right: EmojiContainerView.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: EmojiSize.width+2)
            }
            views.backgroundColor = UIColor.white
            views.register(UploadEmojiCell.self, forCellWithReuseIdentifier: emojiCellID)
            views.delegate = self
            views.dataSource = self
            views.allowsMultipleSelection = true
            
        }
        
        resetCaptionTextView()
        resetEmojiTextView()
        
    }
    
// Detect Emojis in textview
    
//    func textFieldDidChange(_ textField: UITextField) {
//     
//        let strLast5 =  textView.text.characters.substring(from: min(0,textView.text.characters.count - 5))
//        
//        textView.text.substring(from: 5)
//        
//        print(strLast5)
//        
//        
//    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        let char = text.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        
        
        if text == "\n"  // Recognizes enter key in keyboard
        {
            textView.resignFirstResponder()
            return false
        }
        
        if textView == emojiTextView {
            
            if (isBackSpace == -92){
                return true
            }
            
           if (text.isSingleEmoji)
           {
            self.emojiCheck(text)
            
            return false
           }
           
           else {
            return false
            }
            
        }
        
        
        if textView == captionTextView {
    
            if text.isSingleEmoji == true {
                if selectedEmojis.contains(text){
                    // Do nothing if user types emoji that is already included in selected emoji label
                } else {
                    self.emojiCheck(text)
                }
            }
        
        // Detect Backspace = isBackSpace == -92
        
            else if (text == " ") {
                let words = textView.text!.components(separatedBy: " ")
                let lastWord = words[words.endIndex - 1]
                var emojiLookup = EmojiDictionary.key(forValue: lastWord.lowercased())
                self.emojiCheck(emojiLookup)
            }
            return true
            
            }
        
        else { return false }
    }
    
    

    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if textView == captionTextView {
            
            if textView.text == captionDefault {
                textView.text = nil
            }
            
            textView.textColor = UIColor.black
        }
        
        if textView == emojiTextView {
            if  emojiTextView.text == emojiDefault{
                textView.text = nil
                
                
                // Alpha Handled through Check Emoji
            }

        }
    }
    
//    func textViewDidChange(_ textView: UITextView) {
//        if textView == captionTextView {
//            
//            if textView.text == "Caption Here" {
//                textView.text = nil
//            }
//            
//            textView.textColor = UIColor.black
//        }
//        
//        if textView == emojiTextView {
//            if  emojiTextView.text == "😍🐮🍔🇺🇸🔥"{
//                textView.text = nil
//            }
//
//        }
//    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == captionTextView {
            
            if textView.text.isEmpty {
                self.resetCaptionTextView()
            }
        }
        
        if textView == emojiTextView {
            
            // To handle backspaces
            self.selectedEmojis = textView.text
            if textView.text.isEmpty {
                self.resetEmojiTextView()
            }
        }
        
    }
    
    
    
    
    func resetCaptionTextView() {
        self.captionTextView.text = captionDefault
        self.captionTextView.textColor = UIColor.lightGray
        
    }
    
    func resetEmojiTextView() {
        self.emojiTextView.text = emojiDefault
        self.emojiTextView.alpha = 0.25
    }
    
    
    func emojiCheck(_ emoji: String?){
    

        // Check if selected Emojis already have emoji
        
        guard let emoji = emoji else {return}
        var selectedEmojis = self.selectedEmojis
        
        if emoji.containsOnlyEmoji == false {
            return
        }
      
        else if selectedEmojis == nil {
            selectedEmojis = emoji
            self.selectedEmojis = selectedEmojis
        }
            
        else if (selectedEmojis.contains(emoji)) {
            self.selectedEmojis = selectedEmojis.replacingOccurrences(of: emoji, with: "")
        }
        
         else if emoji.containsOnlyEmoji && (selectedEmojis.characters.count) < self.maxEmojis {
            selectedEmojis = emoji
            self.selectedEmojis = self.selectedEmojis + selectedEmojis
        }
        
        print(self.selectedEmojis)
        

        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == placesCollectionView {
            return googlePlaceNames.count }
        
        else if emojiViews!.contains(collectionView) {
            
            return EmoticonArray[collectionView.tag].count
        }
        
        else {return 0}
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if collectionView == placesCollectionView {
        
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationCellID, for: indexPath) as! UploadLocationCell
            
            cell.uploadLocations.text = googlePlaceNames[indexPath.item]
            if self.selectedPostLocation == self.googlePlaceLocations[indexPath.item] {
                cell.backgroundColor = UIColor.gray
            } else {
                cell.backgroundColor = UIColor.white
            }
            
            return cell
        }
        
        if emojiViews!.contains(collectionView){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiCellID, for: indexPath) as! UploadEmojiCell
            
                cell.uploadEmojis.text = EmoticonArray[collectionView.tag][(indexPath as IndexPath).row]
                
                if self.selectedEmojis.contains(cell.uploadEmojis.text!){
                    cell.backgroundColor = UIColor.gray
                } else {
                    cell.backgroundColor = UIColor.white
                }

            return cell
            
        }
        
        else {

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiCellID, for: indexPath) as! UploadEmojiCell
            cell.uploadEmojis.text = EmoticonArray[0][(indexPath as IndexPath).row]
            return cell
            
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
        if emojiViews!.contains(collectionView) {

            let cell = collectionView.cellForItem(at: indexPath) as! UploadEmojiCell
           // cell.contentView.backgroundColor = UIColor.blue
            self.emojiCheck(cell.uploadEmojis.text)

            
        }
        
        else if collectionView == placesCollectionView {

            // Unselects Location
            
            if self.selectedPostLocation == self.googlePlaceLocations[indexPath.item] {

                self.selectedPostLocation = self.selectedImageLocation
                self.locationNameLabel.text = self.selectedImageLocationName
                self.locationAdressLabel.text = self.selectedImageLocationAdress
                self.selectedPostGooglePlaceID = nil
                self.selectedGoogleLocationIndex = nil
                
            } else {
            
                self.selectedPostLocation = self.googlePlaceLocations[indexPath.item]
                self.locationNameLabel.text = self.googlePlaceNames[indexPath.item]
                self.locationAdressLabel.text = self.googlePlaceAdresses[indexPath.item]
                self.selectedPostGooglePlaceID = self.googlePlaceIDs[indexPath.item]
                self.selectedGoogleLocationIndex = indexPath.item
        
                print(self.googlePlaceLocations[indexPath.item])
                print(self.googlePlaceAdresses[indexPath.item])
                print(self.selectedPostLocation ?? nil)
                print(self.selectedPostGooglePlaceID ?? "")
            
            }
            
            collectionView.reloadData()
        
        }
    
    }
    
    

    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        
        if collectionView == placesCollectionView {
            
            collectionView.cellForItem(at: indexPath)?.contentView.backgroundColor = UIColor.white
            
        }
        
// Deselect Doesn't work for emojis since scells are constantly being reloaded and hence selection is restarted
        
    }
    
    func handleShare() {
        
        guard let image = selectedImage else { return }
        guard let uploadData = UIImageJPEGRepresentation(image, 0.5) else {return}
        guard let caption = captionTextView.text, caption.characters.count > 0 else {return}
        

        
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        let filename = NSUUID().uuidString
        Storage.storage().reference().child("posts").child(filename).putData(uploadData, metadata: nil) { (metadata, err) in
            if let err = err {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                print("Failed to upload post image:", err)
                return
            }
            
            guard let imageUrl = metadata?.downloadURL()?.absoluteString else {return}
            
            print("Successfully uploaded post image:",  imageUrl)
            
            self.saveToDatabaseWithImageURL(imageUrl: imageUrl)
            
        }
        
    }
    
     static let updateFeedNotificationName = NSNotification.Name(rawValue: "UpdateFeed")
    
    fileprivate func saveToDatabaseWithImageURL(imageUrl: String) {
        
        guard let postImage = selectedImage else {return}
        var caption = captionTextView.text
            if caption == captionDefault {
                caption = ""
            }
        let selectedPostEmoji = selectedEmojis
        let googlePlaceID = selectedPostGooglePlaceID ?? ""
        guard let postLocationName = locationNameLabel.text else {return}
        guard let postLocationAdress = locationAdressLabel.text else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        var uploadedLocationGPSLatitude: String
        var uploadedlocationGPSLongitude: String
        var uploadedLocationGPS: String
        
        if selectedPostLocation == nil {
            uploadedLocationGPSLatitude = "0"
            uploadedlocationGPSLongitude = "0"
        } else {
            uploadedLocationGPSLatitude = String(format: "%f", (selectedPostLocation?.coordinate.latitude)!)
            uploadedlocationGPSLongitude = String(format: "%f", (selectedPostLocation?.coordinate.longitude)!)
        }
        // "postLocationGPS" : uploadedLocationGPS
        
        
        uploadedLocationGPS = uploadedLocationGPSLatitude + "," + uploadedlocationGPSLongitude
        print(uploadedLocationGPS)
        
        
        let userPostRef = Database.database().reference().child("posts").child(uid)
        let ref = userPostRef.childByAutoId()
        
        let values = ["imageUrl": imageUrl, "caption": caption, "emoji": selectedPostEmoji, "imageWidth": postImage.size.width, "imageHeight": postImage.size.height, "creationDate": Date().timeIntervalSince1970, "googlePlaceID": googlePlaceID, "locationName": postLocationName, "locationAdress": postLocationAdress, "postLocationGPS": uploadedLocationGPS] as [String:Any]
        ref.updateChildValues(values) { (err, ref) in
            if let err = err {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                print("Failed to save post to DB", err)
                return
            }
        
        print("Successfully save post to DB")
            
// SAVE GEOFIRE LOCATION DATA
            
            let geofireRef = Database.database().reference().child("postlocations")
            guard let geoFire = GeoFire(firebaseRef: geofireRef) else {return}
            let postref = ref.key
            print(postref)

            geoFire.setLocation(self.selectedPostLocation, forKey: postref) { (error) in
                if (error != nil) {
                    print("An error occured: \(error)")
                } else {
                    print("Saved location successfully!")
                }
            }
            
            self.dismiss(animated: true, completion: nil)
            

            NotificationCenter.default.post(name: SharePhotoController.updateFeedNotificationName, object: nil)
        }

        
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    

// APPLE PLACES QUERY
    
    let locationManager = CLLocationManager()
    
    func appleCurrentLocation(_ GPSLocation: CLLocation) {
        
        // Reverse GPS to get place adress
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        
        // var location:CLLocation = CLLocation(latitude: postlatitude, longitude: postlongitude)
        
        CLGeocoder().reverseGeocodeLocation(GPSLocation, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil) {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                return
            }
            
            if placemarks!.count > 0 {
                let pm = placemarks![0]
                self.displayLocationInfo(pm)
            } else {
                print("Problem with the data received from geocoder")
            }
        })
    }
    
    func displayLocationInfo(_ placemark: CLPlacemark?) {
        if let containsPlacemark = placemark {
            //stop updating location to save battery life
            //locationManager.stopUpdatingLocation()
            

            let subThoroughfare = (containsPlacemark.subThoroughfare != nil) ? containsPlacemark.subThoroughfare : ""
            let thoroughfare = (containsPlacemark.thoroughfare != nil) ? containsPlacemark.thoroughfare : ""
            let locality = (containsPlacemark.locality != nil) ? containsPlacemark.locality : ""
            let state = (containsPlacemark.administrativeArea != nil) ? containsPlacemark.administrativeArea : ""
            let postalCode = (containsPlacemark.postalCode != nil) ? containsPlacemark.postalCode : ""

            self.selectedImageLocationAdress = subThoroughfare! + " " + thoroughfare! + ", " + locality! + ", " + state! + " " + postalCode!
            
        }
        
    }

// GOOGLE PLACES QUERY
    
    func googleReverseGPS(GPSLocation: CLLocation){
        let URL_Search = "https://maps.googleapis.com/maps/api/geocode/json?"
        let API_iOSKey = GoogleAPIKey()
        
        let urlString = "\(URL_Search)latlng=\(GPSLocation.coordinate.latitude),\(GPSLocation.coordinate.longitude)&key=\(API_iOSKey)"
        let url = URL(string: urlString)!
        
        //   https://maps.googleapis.com/maps/api/geocode/json?latlng=34.79,-111.76&key=AIzaSyAzwACZh50Qq1V5YYKpmfN21mZs8dW6210
    
        var temp = [String()]
        var locationGPStemp = [CLLocation()]

        
        Alamofire.request(url).responseJSON { (response) -> Void in
            
 //           print(response)
            
            if let value  = response.result.value {
                let json = JSON(value)
                
                if let results = json["results"].array {

   //                 print("Google Map Results ",results[0]["formatted_address"])
                    self.selectedImageLocationAdress = results[0]["formatted_address"].string

                        }
                    }
                }
            }
    
    
    
    func googleLocationSearch(GPSLocation: CLLocation){
        
        let dataProvider = GoogleDataProvider()
        let searchRadius: Double = 100
        var searchedTypes = ["restaurant"]
        var searchTerm = "restaurant"
        
        downloadRestaurantDetails(GPSLocation, searchRadius: searchRadius, searchType: searchTerm)
        
    }
    
    
    var googlePlaceNames = [String?](){
        didSet {
        }
    }

    var googlePlaceIDs = [String]()
    var googlePlaceAdresses = [String]()
    var googlePlaceLocations = [CLLocation]()
    
    
    func downloadRestaurantDetails(_ lat: CLLocation, searchRadius:Double, searchType: String ) {
        let URL_Search = "https://maps.googleapis.com/maps/api/place/search/json?"
        let API_iOSKey = GoogleAPIKey()
        
        let urlString = "\(URL_Search)location=\(lat.coordinate.latitude),\(lat.coordinate.longitude)&rankby=distance&type=\(searchType)&key=\(API_iOSKey)"
        let url = URL(string: urlString)!
        
        print(urlString)
        
        //   https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.8670,151.1957&radius=500&types=food&name=cruise&key=YOUR_API_KEY
        
        // https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=41.9542116666667,-87.7055883333333&radius=100.0&rankby=distance&type=restaurant&key=AIzaSyBq2etZOLunPzzNt9rA52n3RKN-TKPLhec
        
        self.googlePlaceNames.removeAll()
        self.googlePlaceIDs.removeAll()
        self.googlePlaceAdresses.removeAll()
        self.googlePlaceLocations.removeAll()

        
        Alamofire.request(url).responseJSON { (response) -> Void in
            
//            print(response)
            
            if let value  = response.result.value {
                let json = JSON(value)
                
                if let results = json["results"].array {
                    for result in results {
                        
                        if result["place_id"].string != nil {
                            guard let placeID = result["place_id"].string else {return}
                            guard let name = result["name"].string else {return}
                            guard let locationAdress = result["vicinity"].string else {return}
                            guard let postLatitude = result["geometry"]["location"]["lat"].double else {return}
                            guard let postLongitude = result["geometry"]["location"]["lng"].double else {return}
                                
                            let locationGPStempcreate = CLLocation(latitude: postLatitude, longitude: postLongitude)
                            
                                    self.googlePlaceNames.append(name)
                                    self.googlePlaceIDs.append(placeID)
                                    self.googlePlaceAdresses.append(locationAdress)
                                    self.googlePlaceLocations.append(locationGPStempcreate)
                                    self.placesCollectionView.reloadData()
                                    
                            }
                        }
                    }
                }
            }
        
        }
    }





//            if let adressDictionaryValue = adressDictionary["FormattedAddressLines"] as! NSArray as? [String] {
//
//                var adress = adressDictionaryValue as NSArray as! [String]



//                Optional([AnyHashable("Street"): 3465 W 6th St,
//                   AnyHashable("Country"): United States,
//                   AnyHashable("State"): CA, AnyHashable("PostCodeExtension"): 2567, AnyHashable("ZIP"): 90020, AnyHashable("SubThoroughfare"): 3465, AnyHashable("Name"): 3465 W 6th St, AnyHashable("Thoroughfare"): W 6th St, AnyHashable("SubAdministrativeArea"): Los Angeles, AnyHashable("FormattedAddressLines"): <__NSArrayM 0x60800024ced0>(
//                    3465 W 6th St,
//                    Los Angeles, CA  90020,
//                    United States
//                )

//            SelectedLocationName = containsPlacemark.name
//            SelectedLocationAdress = nil
//
//            updateGPS()
//
// self.PlaceName.text = containsPlacemark.name

//            Optional([AnyHashable("Street"): 90 Bell Rock Plz, AnyHashable("ZIP"): 86351, AnyHashable("Country"): United States, AnyHashable("SubThoroughfare"): 90, AnyHashable("State"): AZ, AnyHashable("Name"): Coconino National Forest, AnyHashable("SubAdministrativeArea"): Yavapai, AnyHashable("Thoroughfare"): Bell Rock Plz, AnyHashable("FormattedAddressLines"): <__NSArrayM 0x608000241440>(
//                Coconino National Forest,
//                90 Bell Rock Plz,
//                Sedona, AZ  86351,
//                United States
//                )
//                , AnyHashable("City"): Sedona, AnyHashable("CountryCode"): US, AnyHashable("PostCodeExtension"): 9040])


/*
 print(locality)
 print(GPS)
 print(containsPlacemark.areasOfInterest)
 print(containsPlacemark.name)
 print(containsPlacemark.thoroughfare)
 print(containsPlacemark.subThoroughfare)
 
 
 public var name: String? { get } // eg. Apple Inc.
 public var thoroughfare: String? { get } // street name, eg. Infinite Loop
 public var subThoroughfare: String? { get } // eg. 1
 public var locality: String? { get } // city, eg. Cupertino
 public var subLocality: String? { get } // neighborhood, common name, eg. Mission District
 public var administrativeArea: String? { get } // state, eg. CA
 public var subAdministrativeArea: String? { get } // county, eg. Santa Clara
 public var postalCode: String? { get } // zip code, eg. 95014
 public var ISOcountryCode: String? { get } // eg. US
 public var country: String? { get } // eg. United States
 public var inlandWater: String? { get } // eg. Lake Tahoe
 public var ocean: String? { get } // eg. Pacific Ocean
 public var areasOfInterest: [String]? { get } // eg. Golden Gate Park
 */



