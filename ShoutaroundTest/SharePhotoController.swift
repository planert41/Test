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
import GooglePlaces

class SharePhotoController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate,UICollectionViewDataSource, UITextViewDelegate, CLLocationManagerDelegate, LocationSearchControllerDelegate, UIGestureRecognizerDelegate, GMSAutocompleteViewControllerDelegate {
   
    let locationManager = CLLocationManager()
    let emojiCollectionViewRows: Int = 5
    let DefaultEmojiLabelSize = 25 as CGFloat
    
    
    func didUpdate(lat: Double?, long: Double?, locationAdress: String?, locationName: String?, locationGooglePlaceID: String?) {
        self.selectedImageLocation = CLLocation.init(latitude: lat!, longitude: long!)
        self.selectedPostGooglePlaceID = locationGooglePlaceID
        self.selectedImageLocationName = locationName
        self.selectedImageLocationAdress = locationAdress
        
    }

    
    
    let locationCellID = "locationCellID"
    let emojiCellID = "emojiCellID"
    let captionDefault = "Insert Caption Here"
    let emojiDefault = ""
    
    var emojiArray:[String]? = nil
    
    let nonRatingEmojiLimit = 4
    
    var selectedEmojis = ""
    var ratingEmoji: String? = nil {
        didSet{
         
            self.ratingEmojiLabel.text = ratingEmoji
            if ratingEmoji != nil || self.nonRatingEmoji != nil {
                self.emojiCancelButton.alpha = 1
            }
            if ratingEmoji != nil {
                self.blankRatingEmoji.isHidden = true
            } else {
                self.blankRatingEmoji.isHidden = false
                if nonRatingEmoji == nil {
                self.emojiCancelButton.alpha = 0
                }
            }
            updateSelectedEmojis()
        }
    }
    
    var nonRatingEmoji: [String]? = nil {
        didSet{
            self.nonRatingEmojiLabel.text = nonRatingEmoji?.joined()
            self.ratingEmojiLabel.text = ratingEmoji
            
            if ratingEmoji != nil || self.nonRatingEmoji != nil {
                self.emojiCancelButton.alpha = 1
            }
            
            if nonRatingEmoji != nil {
                self.nonRatingEmojiStackView.isHidden = true
                
            } else {
                self.nonRatingEmojiStackView.isHidden = false
                if nonRatingEmoji == nil {
                    self.emojiCancelButton.alpha = 0
                }
            }
            updateSelectedEmojis()
        }
    }

    var nonRatingEmojiTags:[String]? = nil

    func updateSelectedEmojis(){
        var ratingEmojiValue = self.ratingEmojiLabel.text ?? ""
        var nonRatingEmojiValue = self.nonRatingEmojiLabel.text ?? ""
        self.selectedEmojis = ratingEmojiValue + nonRatingEmojiValue
        print("Selected Emojis: ", self.selectedEmojis)

    }
    
    var nonRatingEmojiStackView: UIStackView = {
        
        var stackview = UIStackView()
        let defaultimage1 = UIImageView.init(image: #imageLiteral(resourceName: "emojidefault1").withRenderingMode(.alwaysOriginal))
        let defaultimage2 = UIImageView.init(image: #imageLiteral(resourceName: "emojidefault2").withRenderingMode(.alwaysOriginal))
        let defaultimage3 = UIImageView.init(image: #imageLiteral(resourceName: "emojidefault3").withRenderingMode(.alwaysOriginal))
        let defaultimage4 = UIImageView.init(image: #imageLiteral(resourceName: "emojidefault4").withRenderingMode(.alwaysOriginal))
        
        stackview = UIStackView(arrangedSubviews: [defaultimage1,defaultimage2,defaultimage3,defaultimage4])
        stackview.axis = .horizontal
        stackview.distribution = .fillEqually
        stackview.layer.borderWidth = 1
        stackview.layer.cornerRadius = 5
        stackview.layer.borderColor = UIColor.lightGray.cgColor
        stackview.spacing = 2
        return stackview
    }()

    func emojiTagUntag(emojiInput: String?, emojiInputTag: String?){
        
        guard let emojiInput = emojiInput else {
            print("No EmojiInput")
            return}
        
        if emojiInput.containsOnlyEmoji == false {
            print("Emoji Input is not emoji")
            return
        }
        
        var tempRatingEmoji: String? = self.ratingEmoji
        var tempNonRatingEmoji: [String]? = self.nonRatingEmoji
        var tempNonRatingEmojiTags: [String]? = self.nonRatingEmojiTags
        
        if emojiInput.containsRatingEmoji {
                // Rating Emoji
            if tempRatingEmoji == nil {
                    tempRatingEmoji = emojiInput
                print("Add Rating Emoji: ", emojiInput)
                
                } else {
                if tempRatingEmoji == emojiInput{
                    // Remove if Dup
                    if let range = captionTextView.text.lowercased().range(of: (emojiInput)) {
                    // Still in caption. No Delete
                    } else {
                        //Not in Caption anymore. Delete
                        tempRatingEmoji = nil

                    }
                print("Remove Rating Emoji: ", emojiInput)
                    
                } else {
                    // Replace if Not Dup
                    tempRatingEmoji = emojiInput
                print("Replace Rating Emoji: ", emojiInput)
                    
                }
            }
        } else {
                // Non Rating Emoji
            guard let emojiInputTag = emojiInputTag else {
                print("No Emoji Tag for Non Rating Emoji: ", emojiInput)
                return
            }
            
            let dupNonRatingEmojis = tempNonRatingEmoji?.filter({ (item) -> Bool in
                var emojiDup = item.range(of: emojiInput)
                return emojiDup != nil ? true : false
            })
            
            if tempNonRatingEmoji == nil {
                tempNonRatingEmoji = [emojiInput]
                tempNonRatingEmojiTags = [emojiInputTag]
//                
//                tempNonRatingEmoji?.insert(emojiInput, at: 0)
//                tempNonRatingEmojiTags?.insert(emojiInputTag, at: 0)
                print("Add Non Rating Emoji: ", emojiInput, emojiInputTag)
                print(tempNonRatingEmoji, tempNonRatingEmojiTags)
                
            }
                else if (dupNonRatingEmojis?.count)! > 0 {
                // There is a duplicate Emoji
                guard let dupNonRatingEmojiIndex = tempNonRatingEmoji?.index(of: (dupNonRatingEmojis?[0])!) else {
                    print("Can't find Dup Emoji Index")
                    return}
                
                if emojiInputTag == tempNonRatingEmojiTags?[dupNonRatingEmojiIndex] {
                
                    //Check to see if emoji is still in text
                    if let range = captionTextView.text.lowercased().range(of: (emojiInput)) {
                        } else {
                    // Delete if NR emoji and NR emoji tag are same
                    tempNonRatingEmoji?.remove(at: dupNonRatingEmojiIndex)
                    tempNonRatingEmojiTags?.remove(at: dupNonRatingEmojiIndex)
                    print("Remove Non Rating Emoji: ", emojiInput, emojiInputTag)
                        }
                    }
                }
            
            else if (tempNonRatingEmoji?.joined().characters.count)! + emojiInput.characters.count < nonRatingEmojiLimit + 1 {
               
                // Check to see if selected icon is within Multi-Emoji Word. Remove prev tag
                for emoji in self.nonRatingEmoji! {
                    if emojiInput.contains(emoji){
                        
                        guard let dupNonRatingEmojiIndex = tempNonRatingEmoji?.index(of: emoji) else {
                            print("Can't find Dup Emoji Index")
                            return}
                        tempNonRatingEmoji?.remove(at: dupNonRatingEmojiIndex)
                        tempNonRatingEmojiTags?.remove(at: dupNonRatingEmojiIndex)
                    }
                }
                
                // Add if total emoji count less than limit
                tempNonRatingEmoji?.append(emojiInput)
                tempNonRatingEmojiTags?.append(emojiInputTag)
                print("Add Non Rating Emoji: ", emojiInput, emojiInputTag)
            } else {
                print("No Add - Emoji Limit", emojiInput, emojiInputTag)
            }
        }
        
        print("Final Emoji Tags: ", self.ratingEmoji, self.nonRatingEmoji, self.nonRatingEmojiTags)
        
        self.ratingEmoji = tempRatingEmoji
        self.nonRatingEmoji = tempNonRatingEmoji
        self.nonRatingEmojiTags = tempNonRatingEmojiTags
        
        
    }


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

    var defaultImageGPSName: String? = nil
    
    var selectedImageLocation:CLLocation?{

        didSet {

            let postLatitude:String! = String(format:"%.4f",(selectedImageLocation?.coordinate.latitude)!)
            let postLongitude:String! = String(format:"%.4f",(selectedImageLocation?.coordinate.longitude)!)
            var GPSLabelText:String?
            
            if selectedImageLocation?.coordinate.latitude != 0 && selectedImageLocation?.coordinate.longitude != 0 {
                
                if selectedImageLocation == CurrentUser.currentLocation {
                let attributedText = NSMutableAttributedString(string: "Current Location", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor.mainBlue()])
                    self.locationNameLabel.attributedText = attributedText
                } else{
                
                    self.defaultImageGPSName = "GPS: " + " (" + postLatitude + "," + postLongitude + ")"
                    self.selectedImageLocationName = self.defaultImageGPSName
                    self.selectedPostLocation = selectedImageLocation
                    //self.locationCancelButton.alpha = 1
                }
                
                googleReverseGPS(GPSLocation: selectedImageLocation!)
                googleLocationSearch(GPSLocation: selectedImageLocation!)
                
                self.placesCollectionView.reloadData()

            } else {

                self.defaultImageGPSName =  "No GPS Location"
                self.selectedImageLocationName = self.defaultImageGPSName
                self.selectedImageLocationAdress = ""
                self.selectedPostLocation = nil
                
                // No Geofire Data is saved if location is empty
            }
        }
    }
    
    var selectedImageTime: Date? {
        didSet{
            if selectedImageTime == nil {
                ("No Image Time, Defaulting to Current Upload Time: ")
            } else {
                self.selectedTime = selectedImageTime
            }
        }
    }
    var selectedTime: Date? = nil {
        
        didSet{
            // get the current date and time
            let currentDateTime = Date()
            let formatter = DateFormatter()

            formatter.dateFormat = "MMM d YYYY, h:mm a"
            
            //            formatter.timeStyle = .short
            //            formatter.dateStyle = .short
            
            if self.selectedTime == nil {
                self.timeLabel.text = ""
            }
            else {
                self.timeLabel.text = formatter.string(from: self.selectedTime!)
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.rgb(red: 204, green: 238, blue: 255)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handleShare))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(handleBack))
        
        setupImageAndTextViews()
        self.captionTextView.becomeFirstResponder()
        
    }
    
    

    func handleBack() {
        self.dismiss(animated: true) {
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {

        // Invalidate Layout so that after location search it will not crash
        
        print("View will appear")
        self.placesCollectionView.collectionViewLayout.invalidateLayout()
        self.EmojiCollectionView.collectionViewLayout.invalidateLayout()
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
        
        self.resetSelectedEmojis()
        
    }
    
    let captionCancelButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "cancel_shadow").withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.backgroundColor = UIColor.gray
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        
        button.addTarget(self, action: #selector(cancelCaption), for: .touchUpInside)
        return button
        
    } ()
    
    func cancelCaption(){
        
        captionTextView.text = nil
        self.captionCancelButton.alpha = 0
        self.resetSelectedEmojis()
        
    }
    
    func resetSelectedEmojis(){
        
        if self.ratingEmoji != nil {
         //   self.captionTextView.text = self.captionTextView.text.replacingOccurrences(of: self.ratingEmoji!, with: "")
            self.ratingEmoji = nil
            
        }
        if self.nonRatingEmoji != nil {
            for emoji in self.nonRatingEmoji!{
          //      self.captionTextView.text = self.captionTextView.text.replacingOccurrences(of: emoji, with: "")
            }
            self.nonRatingEmoji = nil
        }
        
        
        self.selectedEmojis = ""
        self.EmojiCollectionView.reloadData()
    }
    
    let locationNameLabel: UILabel = {
        let tv = LocationLabel()
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tv.layer.borderWidth = 0.5
        tv.layer.cornerRadius = 5
        tv.isUserInteractionEnabled = true
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(tapSearchBar))
        tv.addGestureRecognizer(TapGesture)
        
        return tv
    }()
    
    let emojiTagLabel: UILabel = {
        let tv = LocationLabel()
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.text = "Emoji Tags:"
        tv.backgroundColor = UIColor.clear
        return tv
    }()
    
    func tapSearchBar() {
        print("Search Bar Tapped")
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }


    let locationIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "gpsmarker").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(locationIconPushed), for: .touchUpInside)
        return button
    }()
    
    func locationIconPushed(){
        determineCurrentLocation()
    }
    
    
    
    let locationAdressLabel: UILabel = {
        let tv = LocationLabel()
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tv.layer.borderWidth = 0.5
        tv.layer.cornerRadius = 5
        tv.isUserInteractionEnabled = true
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(tapSearchBar))
        tv.addGestureRecognizer(TapGesture)
        
        return tv
    }()
    
    
    let adressIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "adress").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(locationIconPushed), for: .touchUpInside)
        return button
    }()
    
    
    let timeLabel: UILabel = {
        let tv = LocationLabel()
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tv.layer.borderWidth = 0.5
        tv.layer.cornerRadius = 5
        tv.isUserInteractionEnabled = true
        let TapGesturet = UITapGestureRecognizer(target: self, action: #selector(timeInput))
        tv.addGestureRecognizer(TapGesturet)
        
        return tv
    }()
    
    
    let timeIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "time").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(timeIconPushed), for: .touchUpInside)
        return button
    }()
    
    func timeIconPushed(){

        let currentDateTime = Date()
        self.selectedTime = currentDateTime

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d YYYY, h:mm a"
        let attributedText = NSMutableAttributedString(string: formatter.string(from: currentDateTime), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor.mainBlue()])
        self.timeLabel.attributedText = attributedText
        

    }

    var datePicker: UIDatePicker = UIDatePicker()
    
    var toolBar: UIToolbar = {
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 92/255, green: 216/255, blue: 255/255, alpha: 1)
        toolBar.sizeToFit()
        return toolBar
    }()
    
    func timeInput(){
        
        print("Time Input is activated")
        
        self.datePicker.isHidden = false
        self.toolBar.isHidden = false
        // Set some of UIDatePicker properties
        datePicker.timeZone = NSTimeZone.local
        datePicker.backgroundColor = UIColor.white
        
        // ToolBar

        
        // Adding Button ToolBar
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneClick))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelClick))
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
    
        
        // Add an event to call onDidChangeDate function when value is changed.
        datePicker.addTarget(self, action: #selector(self.datePickerValueChanged(_:)), for: .valueChanged)
        
        // Add DataPicker to the view
        self.view.addSubview(datePicker)
        datePicker.anchor(top: nil, left: self.view.leftAnchor, bottom: self.view.bottomAnchor, right: self.view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 200)
        self.view.addSubview(toolBar)
        toolBar.anchor(top: nil, left: self.view.leftAnchor, bottom: datePicker.topAnchor, right: self.view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
    }
    
    
    func doneClick() {
        let dateFormatter1 = DateFormatter()
        self.selectedTime = datePicker.date
        
        self.toolBar.isHidden = true
        self.datePicker.isHidden = true
    }
    func cancelClick() {
        self.toolBar.isHidden = true
        self.datePicker.isHidden = true
    }
    
    
    func datePickerValueChanged(_ sender: UIDatePicker){
        
    }
    
    
    let locationCancelButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "cancel_shadow").withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        
        button.addTarget(self, action: #selector(cancelLocation), for: .touchUpInside)
        return button
        
    } ()
    
    
    func cancelLocation(){
        
        selectedPostLocation = nil
        
    }
    
    let timeCancelButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "cancel_shadow").withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        
        button.addTarget(self, action: #selector(cancelTime), for: .touchUpInside)
        return button
        
    } ()

    
    func cancelTime(){
        
        selectedTime = nil
        
    }
    
    
    let locationSearchButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.backgroundColor = UIColor(white: 0, alpha: 0.03)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        
        button.addTarget(self, action: #selector(locationSearch), for: .touchUpInside)
        return button
        
    } ()
    
    func locationSearch(){
        
        let locationSearchController = LocationSearchController()
        var sentLocation: CLLocation?
        
        if self.selectedPostLocation == nil {

            self.determineCurrentLocation()
            
            let when = DispatchTime.now() + 1 // change 2 to desired number of seconds
            DispatchQueue.main.asyncAfter(deadline: when) {
            
                sentLocation = CurrentUser.currentLocation
                print(sentLocation)
                locationSearchController.selectedLocation = sentLocation
                locationSearchController.refreshMap(long: (sentLocation!.coordinate.longitude), lat: (sentLocation!.coordinate.latitude), name: self.locationNameLabel.text, adress: self.locationAdressLabel.text)
                locationSearchController.selectedGooglePlaceID = self.selectedPostGooglePlaceID
                locationSearchController.delegate = self
                self.navigationController?.pushViewController(locationSearchController, animated: true)
            }
            

            
        } else {
            sentLocation = self.selectedPostLocation
            locationSearchController.selectedLocation = sentLocation
            locationSearchController.refreshMap(long: (sentLocation!.coordinate.longitude), lat: (sentLocation!.coordinate.latitude), name: self.locationNameLabel.text, adress: self.locationAdressLabel.text)
            locationSearchController.selectedGooglePlaceID = self.selectedPostGooglePlaceID
            locationSearchController.delegate = self
            navigationController?.pushViewController(locationSearchController, animated: true)
        }
        
    }

    
    let placesCollectionView: UICollectionView = {

        let uploadLocationTagList = UploadLocationTagList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        
        return cv
    }()
    
    let emojiContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    let emojiLabel: UILabel = {
        let tv = UILabel()
        tv.font = UIFont.systemFont(ofSize:15)
        tv.text = "Emoji Tags: "
        tv.textAlignment = NSTextAlignment.left
        tv.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tv.layer.cornerRadius = 5
        return tv
    }()
    
    let emojiLabelContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    let blankRatingEmoji: UIImageView = {
        let iv = UIImageView()
        iv.image = #imageLiteral(resourceName: "blankemoji").withRenderingMode(.alwaysOriginal)
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
        
    }()
    
    let ratingEmojiLabel: UILabel = {
        let tv = UILabel()
        tv.backgroundColor = UIColor.clear
        tv.font = UIFont.boldSystemFont(ofSize: 25)
        
        return tv
    }()
    
    let nonRatingEmojiLabel: UILabel = {
        let tv = UILabel()
        tv.backgroundColor = UIColor.clear
        tv.layer.cornerRadius = 5
        tv.font = UIFont.boldSystemFont(ofSize: 25)
        return tv
    }()
    
    let blankNonRatingEmoji: UIImageView = {
        let iv = UIImageView()
        iv.image = #imageLiteral(resourceName: "blankemoji").withRenderingMode(.alwaysOriginal)
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.borderWidth = 1
        iv.layer.cornerRadius = 5
        iv.layer.borderColor = UIColor.lightGray.cgColor
        return iv
        
    }()
    
    let EmojiCollectionView: UICollectionView = {
        
        let uploadEmojiList = UploadEmojiList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadEmojiList)
        cv.tag = 10
        cv.layer.borderWidth = 0.5
        cv.backgroundColor = UIColor(white: 0, alpha: 0.03)
        
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
        containerView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 135)
        
        view.addSubview(emojiLabelContainer)
        emojiLabelContainer.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, paddingTop: 5, paddingLeft: 4, paddingBottom: 0, paddingRight: 5, width: 0, height: 30)

        view.addSubview(emojiTagLabel)
        emojiTagLabel.anchor(top: emojiLabelContainer.topAnchor, left: emojiLabelContainer.leftAnchor, bottom: emojiLabelContainer.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 100, height: 0)
        
        
        view.addSubview(emojiCancelButton)
        //       emojiCancelButton.anchor(top: nil, left: nil, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 4, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 15, height: 15)
        emojiCancelButton.anchor(top: emojiLabelContainer.topAnchor, left: nil, bottom: emojiLabelContainer.bottomAnchor, right: emojiLabelContainer.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 15, height: 15)
        
        emojiCancelButton.centerYAnchor.constraint(equalTo: emojiLabelContainer.centerYAnchor)
        emojiCancelButton.alpha = 0
        
        
  //      stackview.anchor(top: emojiLabelContainer.topAnchor, left: nil, bottom: nil, right: emojiLabelContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: DefaultEmojiLabelSize * 4, height: DefaultEmojiLabelSize)

        view.addSubview(nonRatingEmojiStackView)
        nonRatingEmojiStackView.anchor(top: emojiLabelContainer.topAnchor, left: emojiTagLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: (DefaultEmojiLabelSize + 2) * 4, height: DefaultEmojiLabelSize)
        
        view.addSubview(nonRatingEmojiLabel)
        nonRatingEmojiLabel.anchor(top: nonRatingEmojiStackView.topAnchor, left: nonRatingEmojiStackView.leftAnchor, bottom: nonRatingEmojiStackView.bottomAnchor, right: self.view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        view.addSubview(blankRatingEmoji)
        blankRatingEmoji.anchor(top: emojiLabelContainer.topAnchor, left: nil, bottom: emojiLabelContainer.bottomAnchor, right:emojiCancelButton.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: DefaultEmojiLabelSize + 2, height: DefaultEmojiLabelSize)

        view.addSubview(ratingEmojiLabel)
        ratingEmojiLabel.anchor(top: blankRatingEmoji.topAnchor, left: blankRatingEmoji.leftAnchor, bottom: blankRatingEmoji.bottomAnchor, right: emojiLabelContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        view.addSubview(imageView)
        imageView.anchor(top: emojiLabelContainer.bottomAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: nil, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, paddingRight: 0, width: 84, height: 0)
        
        view.addSubview(captionTextView)
        captionTextView.anchor(top: imageView.topAnchor, left: imageView.rightAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 4, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        captionTextView.delegate = self
        
        
        view.addSubview(captionCancelButton)
        captionCancelButton.anchor(top: captionTextView.topAnchor, left: nil, bottom: nil, right: captionTextView.rightAnchor, paddingTop: 4, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 15, height: 15)
//        captionCancelButton.centerYAnchor.constraint(equalTo: emojiTextView.centerYAnchor)
        captionCancelButton.alpha = 0
        
        

        
        
// Location Container View
        
        let LocationContainerView = UIView()
        LocationContainerView.backgroundColor = .white

        view.addSubview(LocationContainerView)
        LocationContainerView.anchor(top: captionTextView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 180)
        
        
        // Add Tag Time

        view.addSubview(timeIcon)
        timeIcon.anchor(top: LocationContainerView.topAnchor, left: LocationContainerView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 30, height: 30)
        
        view.addSubview(timeLabel)
        timeLabel.anchor(top: LocationContainerView.topAnchor, left: timeIcon.rightAnchor, bottom: nil, right: LocationContainerView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 40)
        timeLabel.isUserInteractionEnabled = true
        let TapGestureT = UITapGestureRecognizer(target: self, action: #selector(timeInput))
        timeLabel.addGestureRecognizer(TapGestureT)
        
        view.addSubview(timeCancelButton)
        timeCancelButton.anchor(top: timeLabel.topAnchor, left: nil, bottom: nil, right: timeLabel.rightAnchor, paddingTop: 15, paddingLeft: 10, paddingBottom: 15, paddingRight: 10, width: 20, height: 20)
        
        view.addSubview(locationIcon)
        locationIcon.anchor(top: timeLabel.bottomAnchor, left: LocationContainerView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 30, height: 30)
        
        view.addSubview(locationNameLabel)
        locationNameLabel.anchor(top: timeLabel.bottomAnchor, left: locationIcon.rightAnchor, bottom: nil, right: LocationContainerView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 40)
        locationNameLabel.isUserInteractionEnabled = true
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(tapSearchBar))
        locationNameLabel.addGestureRecognizer(TapGesture)

        view.addSubview(locationCancelButton)
        locationCancelButton.anchor(top: locationNameLabel.topAnchor, left: nil, bottom: nil, right: locationNameLabel.rightAnchor, paddingTop: 15, paddingLeft: 10, paddingBottom: 15, paddingRight: 10, width: 20, height: 20)
        
        view.addSubview(adressIcon)
        adressIcon.anchor(top: locationNameLabel.bottomAnchor, left: LocationContainerView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 30, height: 30)
        
        view.addSubview(locationAdressLabel)
        locationAdressLabel.anchor(top: locationNameLabel.bottomAnchor, left: adressIcon.rightAnchor, bottom: nil, right: LocationContainerView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 40)
        locationAdressLabel.isUserInteractionEnabled = true
        let TapGesture1 = UITapGestureRecognizer(target: self, action: #selector(tapSearchBar))
        locationAdressLabel.addGestureRecognizer(TapGesture1)
        
        view.addSubview(locationSearchButton)
        locationSearchButton.anchor(top: locationAdressLabel.topAnchor, left: nil, bottom: nil, right: locationAdressLabel.rightAnchor, paddingTop: 15, paddingLeft: 10, paddingBottom: 15, paddingRight: 10, width: 20, height: 20)

        
        view.addSubview(placesCollectionView)
        placesCollectionView.anchor(top: locationAdressLabel.bottomAnchor, left: LocationContainerView.leftAnchor, bottom: nil, right: LocationContainerView.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 40)
        placesCollectionView.backgroundColor = UIColor.white
        placesCollectionView.register(UploadLocationCell.self, forCellWithReuseIdentifier: locationCellID)
        placesCollectionView.delegate = self
        placesCollectionView.dataSource = self

        
        
// Emoji Container View
        
        let EmojiContainerView = UIView()
        EmojiContainerView.backgroundColor = .green
        

        
        view.addSubview(EmojiContainerView)
//        EmojiContainerView.anchor(top: LocationContainerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: (EmojiSize.width + 2) * 4)
        
        let emojiContainerHeight: Int = (Int(EmojiSize.width) + 2) * self.emojiCollectionViewRows + 10

        EmojiContainerView.anchor(top: LocationContainerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: CGFloat(emojiContainerHeight))
        
        
        view.addSubview(EmojiCollectionView)
        EmojiCollectionView.anchor(top: EmojiContainerView.topAnchor, left: EmojiContainerView.leftAnchor, bottom: EmojiContainerView.bottomAnchor, right: EmojiContainerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        EmojiCollectionView.backgroundColor = UIColor.white
                    EmojiCollectionView.register(UploadEmojiCell.self, forCellWithReuseIdentifier: emojiCellID)
                    EmojiCollectionView.delegate = self
                    EmojiCollectionView.dataSource = self
                    EmojiCollectionView.allowsMultipleSelection = true
        
        let emojiRef = UILongPressGestureRecognizer(target: self, action: #selector(SharePhotoController.handleLongPress(_:)))
        emojiRef.minimumPressDuration = 0.5
        emojiRef.delegate = self
        
        let emojiDoubleTap = UITapGestureRecognizer(target: self, action: #selector(SharePhotoController.handleDoubleTap(_:)))
        emojiDoubleTap.numberOfTapsRequired = 2
        emojiDoubleTap.delegate = self
        
        EmojiCollectionView.addGestureRecognizer(emojiRef)
        EmojiCollectionView.addGestureRecognizer(emojiDoubleTap)
        
//        view.addSubview(Emoji1CollectionView)
//        view.addSubview(Emoji2CollectionView)
//        view.addSubview(Emoji3CollectionView)
//        view.addSubview(Emoji4CollectionView)
//        
//
//        emojiViews = [Emoji1CollectionView, Emoji2CollectionView, Emoji3CollectionView, Emoji4CollectionView]
//        
//        for (index,views) in emojiViews!.enumerated() {
//            
//            if index == 0 {
//                views.anchor(top: EmojiContainerView.topAnchor, left: EmojiContainerView.leftAnchor, bottom: nil, right: EmojiContainerView.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: EmojiSize.width+2)
//            } else {
//                views.anchor(top: emojiViews![index-1].bottomAnchor, left: EmojiContainerView.leftAnchor, bottom: nil, right: EmojiContainerView.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: EmojiSize.width+2)
//            }
//            views.backgroundColor = UIColor.white
//            views.register(UploadEmojiCell.self, forCellWithReuseIdentifier: emojiCellID)
//            views.delegate = self
//            views.dataSource = self
//            views.allowsMultipleSelection = true
//            
//        }
        
        resetCaptionTextView()
        
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
    
// Google Search Location Delegates
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        print(place)
        selectedPostLocation = CLLocation.init(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        selectedPostGooglePlaceID = place.placeID
        self.didUpdate(lat: Double(place.coordinate.latitude), long: Double(place.coordinate.longitude), locationAdress: place.formattedAddress, locationName: place.name, locationGooglePlaceID: place.placeID)
        self.reloadInputViews()
        dismiss(animated: true, completion: nil)
        
    }
    
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print(error)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }

    
    
        var savedWords = [String]()
        var deletedWords = [String]()
        var deletedWord = ""
    
    
    
    func emojiTagging(captionText: String){
        
        var tempCaptionText =  captionText.lowercased()
        
        // Add Space to last tempCaption for searching
        var tempNonRatingEmojiTags = self.nonRatingEmojiTags
        var tempNonRatingEmojis = self.nonRatingEmoji
        
        if (tempNonRatingEmojiTags != nil)  && (tempNonRatingEmojis != nil) {
            // Loop through current Emoji Tags, check if tags exist
            
            if tempNonRatingEmojiTags?.count != tempNonRatingEmojis?.count {
                print("ERROR: Non Rating Emojis Not Equal")
            }
            
            for tag in tempNonRatingEmojiTags! {
                let searchTag = tag + " "
                if let range = tempCaptionText.lowercased().range(of: (searchTag)) {
                    // Emoji Tag still exit in caption remove string from caption text
                    // Using replace subrange to only remove first instance, using X to replace to prevent later search mismatch
                    tempCaptionText.replaceSubrange(range, with: " X ")
                } else {
                    
                    // Can't find Emoji Tag in Caption
                    guard let removeIndex = nonRatingEmojiTags?.index(of: tag) else {
                        print("Can't find delete index for: ", tag)
                        return
                    }
                    
                    // Check if emoji equivalent exist in caption
                    if let emojiLookup = EmojiDictionary.key(forValue: tag) {
                    if tempCaptionText.lowercased().range(of: EmojiDictionary.key(forValue: tag)!) == nil {
                        
                        // Emoji Tag does not exist anymore, Untag emojis and tags
                        emojiTagUntag(emojiInput: tempNonRatingEmojis?[removeIndex], emojiInputTag: tempNonRatingEmojiTags?[removeIndex])

                        } else {
                        // Emoji still exist in caption. Leave tags alone
                        }
                    }
                    }
                }
        }
        
        print(tempCaptionText)
        
        // Check for Complex Tags
        var tempCaptionWords = tempCaptionText.components(separatedBy: " ")
        
        for i in (1...3).reversed() {
            // Check if last n (3 to 1) words match complex dictionary
            
            let captionCheckArray = tempCaptionWords.suffix(i)
            var captionCheckText = captionCheckArray.joined(separator: " ").emojilessString
            print("Caption Check Text: ", captionCheckText)
            
            let emojiLookupResult = EmojiDictionary.key(forValue: captionCheckText)
            if emojiLookupResult != nil {
                // If there is a match add emoji and tag
                emojiTagUntag(emojiInput: emojiLookupResult, emojiInputTag: captionCheckText)
                break
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        captionCancelButton.alpha = 0
        let char = text.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        
        // If caption textview is not blank
        if textView.text != ""{
            captionCancelButton.alpha = 1
        }
        
        if text == "\n"  // Recognizes enter key in keyboard
        {
            textView.resignFirstResponder()
            return false
        }
        
        if text.isSingleEmoji == true {
            if textView.text.contains(text){
             //Ignore if caption text already has emoji, allows multiple emoji caption
            } else {
            self.emojiTagUntag(emojiInput: text, emojiInputTag: text)
            }
            }
            
            else if (text == " ") || (isBackSpace == -92){

                emojiTagging(captionText: textView.text)
            
            }
        return true

    }
    
    
    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
            if textView.text == captionDefault {
                textView.text = nil
            }
            textView.textColor = UIColor.black
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
        
    }
    

    func resetCaptionTextView() {
        self.captionTextView.text = captionDefault
        self.captionTextView.textColor = UIColor.lightGray
        
    }
    

    func handleDoubleTap(_ gestureReconizer: UITapGestureRecognizer) {

        let p = gestureReconizer.location(in: self.view)

            
            let point = self.EmojiCollectionView.convert(p, from:self.view)
            let indexPath = self.EmojiCollectionView.indexPathForItem(at: point)
            
            print(indexPath)
            
            if let index = indexPath  {
                
                let cell = self.EmojiCollectionView.cellForItem(at: index) as! UploadEmojiCell
                var selectedEmoji = cell.uploadEmojis.text
                print("Double Tap Emoji: ", selectedEmoji   )
                
//                print(cell.uploadEmojis.text)
                self.captionTextView.text =  self.captionTextView.text + selectedEmoji! + selectedEmoji!
                self.emojiTagUntag(emojiInput: selectedEmoji, emojiInputTag: selectedEmoji)
                
                // do stuff with your cell, for example print the indexPath
                
                cell.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
                
            } else {
                print("Could not find index path")
            }
        
    }
    
    func handleTripleTap(_ gestureReconizer: UITapGestureRecognizer) {
        
        let p = gestureReconizer.location(in: self.view)
        
        
        let point = self.EmojiCollectionView.convert(p, from:self.view)
        let indexPath = self.EmojiCollectionView.indexPathForItem(at: point)
        
        print(indexPath)
        
        if let index = indexPath  {
            
            let cell = self.EmojiCollectionView.cellForItem(at: index) as! UploadEmojiCell
            var selectedEmoji = cell.uploadEmojis.text
            print("Double Tap Emoji: ", selectedEmoji   )
            
            //                print(cell.uploadEmojis.text)
            self.captionTextView.text.replacingOccurrences(of: selectedEmoji!, with: "")
            self.emojiTagUntag(emojiInput: selectedEmoji, emojiInputTag: selectedEmoji)
            
            // do stuff with your cell, for example print the indexPath
            
            cell.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
            
        } else {
            print("Could not find index path")
        }
        
    }
    
    
    
    
    
    func handleLongPress(_ gestureReconizer: UILongPressGestureRecognizer) {
        
        let p = gestureReconizer.location(in: self.view)
        let subViews = self.view.subviews
        
        if gestureReconizer.state != UIGestureRecognizerState.recognized {

            let point = self.EmojiCollectionView.convert(p, from:self.view)
            let indexPath = self.EmojiCollectionView.indexPathForItem(at: point)
            
            print(indexPath)
            
            if let index = indexPath  {
                
                let cell = self.EmojiCollectionView.cellForItem(at: index) as! UploadEmojiCell
                print(cell.uploadEmojis.text)
                 let selectedEmoji = cell.uploadEmojis.text
                
                
                // Clear Emojis if long press and contains emoji
                if self.captionTextView.text.contains(selectedEmoji!){
                    self.captionTextView.text = self.captionTextView.text.replacingOccurrences(of: selectedEmoji!, with: "")
                    self.emojiTagUntag(emojiInput: selectedEmoji, emojiInputTag: selectedEmoji)
                }
                
                let topleft = CGPoint(x: cell.center.x - cell.bounds.size.width/2, y: cell.center.y - cell.bounds.size.height/2-25)
                let converttopleft = self.view.convert(topleft, from:self.EmojiCollectionView)
                
                let label = UILabel(frame: CGRect(x: converttopleft.x, y: converttopleft.y, width: 75, height: 25))
                label.backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
                label.layer.cornerRadius = 5
                label.layer.masksToBounds = true
                label.layer.borderWidth = 0.25
                label.tag = 1
                label.font = label.font.withSize(15)
                label.textColor = UIColor.black
                label.textAlignment = NSTextAlignment.center
                label.text = EmojiDictionary[(cell.uploadEmojis.text)!]
                print(cell.uploadEmojis.text)
                print("text label is", label.text)
                self.view.addSubview(label)
                
                

                // do stuff with your cell, for example print the indexPath

                cell.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
                
            } else {
                print("Could not find index path")
            }
            
        }
    
        else if gestureReconizer.state != UIGestureRecognizerState.changed {
            
            let point = self.EmojiCollectionView.convert(p, from:self.view)
            let indexPath = self.EmojiCollectionView.indexPathForItem(at: point)
            
            if let index = indexPath  {
                
                // Removes label subview when released
                
                for subview in subViews{
                    if (subview.tag == 1) {
                        subview.removeFromSuperview()
                    }}
                
                let cell = self.EmojiCollectionView.cellForItem(at: index) as! UploadEmojiCell
                
                cell.backgroundColor = UIColor.white
                
            } else {
                print("Could not find index path")
            }
            
            return
            
        }
    
    
    
    
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == EmojiCollectionView {
            return 6
        } else {
            return 1
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == placesCollectionView {
            return googlePlaceNames.count }

        else if collectionView == EmojiCollectionView {
            return EmoticonArray[section].count
        }
            
            
//        else if emojiViews!.contains(collectionView) {
//            
//            return EmoticonArray[collectionView.tag].count
//        }
        
        else {return 0}
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if collectionView == placesCollectionView {
        
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationCellID, for: indexPath) as! UploadLocationCell
            
            cell.uploadLocations.text = googlePlaceNames[indexPath.item]
            if self.selectedPostLocation == self.googlePlaceLocations[indexPath.item] {
                cell.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
            } else {
                cell.backgroundColor = UIColor.white
            }
            
            return cell
        }
        
//        if emojiViews!.contains(collectionView){
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiCellID, for: indexPath) as! UploadEmojiCell
//            
//                cell.uploadEmojis.text = EmoticonArray[collectionView.tag][(indexPath as IndexPath).row]
//                
//                if self.selectedEmojis.contains(cell.uploadEmojis.text!){
//                    cell.backgroundColor = UIColor.gray
//                } else {
//                    cell.backgroundColor = UIColor.white
//                }
//
//            return cell
//            
//        }
            
        if collectionView == EmojiCollectionView {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiCellID, for: indexPath) as! UploadEmojiCell
            
                let columns = collectionView.numberOfItems(inSection: indexPath.section) / emojiCollectionViewRows
                let i = indexPath.item / emojiCollectionViewRows
                let j = indexPath.item % emojiCollectionViewRows
                let newIndex = j*columns+i
            
            
                    cell.uploadEmojis.text = EmoticonArray[(indexPath as IndexPath).section][newIndex]
            
            if (self.selectedEmojis.contains(cell.uploadEmojis.text!)||self.captionTextView.text.contains(cell.uploadEmojis.text!)){
                        cell.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
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
        
        
        if collectionView == EmojiCollectionView{
            let cell = collectionView.cellForItem(at: indexPath) as! UploadEmojiCell
            let pressedEmoji = cell.uploadEmojis.text!
            
        
            if self.captionTextView.text.contains(pressedEmoji) == false && self.selectedEmojis.contains(pressedEmoji) == false
            {
                // emoji not in caption or tag
                if self.captionTextView.text == "Insert Caption Here" {
                    self.captionTextView.text = cell.uploadEmojis.text!
                    self.captionCancelButton.isHidden = false
                    

                } else {
                    self.captionTextView.text = self.captionTextView.text + cell.uploadEmojis.text!
                    self.captionCancelButton.isHidden = false
                    
                }
                
            } else if self.captionTextView.text.contains(pressedEmoji) == true {
                
//                captionTextView.text = captionTextView.text.replacingOccurrences(of: pressedEmoji, with: "")
                let emojiChars = captionTextView.text.indicesOf(string: pressedEmoji)
                let lastEmojiChar = emojiChars[emojiChars.count - 1]
                var temp =  captionTextView.text
                let index = temp?.index((temp?.startIndex)!, offsetBy: lastEmojiChar)
                captionTextView.text.remove(at: index!)
            
            }
            
            // cell.contentView.backgroundColor = UIColor.blue
            self.emojiTagUntag(emojiInput: cell.uploadEmojis.text, emojiInputTag: cell.uploadEmojis.text)
            
            if let emojiChar = self.captionTextView.text.range(of: pressedEmoji) {
                cell.backgroundColor  = UIColor.rgb(red: 149, green: 204, blue: 244)
            }   else {
                cell.backgroundColor = UIColor.white
            }
            
            
            
            
        }
            
//        if emojiViews!.contains(collectionView) {
//
//            let cell = collectionView.cellForItem(at: indexPath) as! UploadEmojiCell
//           // cell.contentView.backgroundColor = UIColor.blue
//            self.emojiCheck(cell.uploadEmojis.text)
//            
//        }
        
        else if collectionView == placesCollectionView {

            // Unselects Location
            
            if self.selectedPostLocation == self.googlePlaceLocations[indexPath.item] {

                self.selectedPostLocation = self.selectedImageLocation
                self.locationNameLabel.text = self.defaultImageGPSName
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
                print(self.googlePlaceNames[indexPath.item])
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
        
        guard let image = selectedImage?.resizeImageWith(newSize: defaultPhotoResize) else { return }
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
        
        
        // SAVE POST
        
        guard let postImage = selectedImage else {return}
        var caption = captionTextView.text
        if caption == captionDefault {
            caption = ""
        }
        let selectedPostEmoji = selectedEmojis
        let googlePlaceID = selectedPostGooglePlaceID ?? ""
        
        // Upload Name Adress that matches inputs
        
        guard let postLocationName = self.locationNameLabel.text else {return}
        guard let postLocationAdress = self.locationAdressLabel.text else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        let ratingEmojiUpload = self.ratingEmoji
        let nonratingEmojiUpload = self.nonRatingEmoji
        let nonratingEmojiTagsUpload = self.nonRatingEmojiTags

        
        
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
        
        
        let userPostRef = Database.database().reference().child("posts")
        let ref = userPostRef.childByAutoId()
        let uploadTime = Date().timeIntervalSince1970
        let tagTime = self.selectedTime?.timeIntervalSince1970
        
        let values = ["imageUrl": imageUrl, "caption": caption, "imageWidth": postImage.size.width, "imageHeight": postImage.size.height, "creationDate": uploadTime, "googlePlaceID": googlePlaceID, "locationName": postLocationName, "locationAdress": postLocationAdress, "postLocationGPS": uploadedLocationGPS, "creatorUID": uid, "tagTime": tagTime,"ratingEmoji": ratingEmojiUpload, "nonratingEmoji": nonratingEmojiUpload, "nonratingEmojiTags": nonratingEmojiTagsUpload] as [String:Any]
        ref.updateChildValues(values) { (err, ref) in
            if let err = err {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                print("Failed to save post to DB", err)
                return
            }
            
            print("Successfully save post to DB")
            
            
            // SAVE USER AND POSTID
            
            let postref = ref.key
            let userPostRef = Database.database().reference().child("userposts").child(uid).child(postref)
            let values = ["creationDate": uploadTime]

            userPostRef.updateChildValues(values) { (err, ref) in
                if let err = err {
                    print("Failed to save post to user", err)
                    return
                }
                
                print("Successfully save post to user")
            }
            
            
            // SAVE GEOFIRE LOCATION DATA
            
            let geofireRef = Database.database().reference().child("postlocations")
            guard let geoFire = GeoFire(firebaseRef: geofireRef) else {return}
//            let geofirekeytest = uid+","+postref
            
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
    
    
    // LOCATION MANAGER DELEGATE METHODS
    
    func determineCurrentLocation(){
        
        CurrentUser.currentLocation = nil
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
        
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        if userLocation != nil {
            print("Current User Location", userLocation)
            CurrentUser.currentLocation = userLocation
            self.selectedImageLocation = userLocation
            manager.stopUpdatingLocation()
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("GPS Location Not Found")
    }
    
    
    

// APPLE PLACES QUERY
    
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



