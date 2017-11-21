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

var newPost: Post? = nil
var newPostId: PostId? = nil

class SharePhotoController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate,UICollectionViewDataSource, UITextViewDelegate, CLLocationManagerDelegate, LocationSearchControllerDelegate, UIGestureRecognizerDelegate, GMSAutocompleteViewControllerDelegate, UITableViewDelegate, UITableViewDataSource {

// Setup Default Variables
    
    let currentDateTime = Date()
    let locationManager = CLLocationManager()
    let emojiCollectionViewRows: Int = 5
    let DefaultEmojiLabelSize = 25 as CGFloat
    let nonRatingEmojiLimit = 5
    
    let locationCellID = "locationCellID"
    let emojiCellID = "emojiCellID"
    let captionDefault = "Insert Caption Here"
    let emojiDefault = ""
    var blankImageGPSName: String = "No GPS Location"

// Information from image
    
    var selectedImage: UIImage? {
        didSet{
            self.imageView.image = selectedImage
        }
    }
    
    var selectedImageLocation:CLLocation?{
        didSet{
            selectedPostLocation = selectedImageLocation
            // Updates Adress and Finds Restaurants near location
            if selectedPostLocation != nil && (selectedPostLocation?.coordinate.latitude != 0) && (selectedPostLocation?.coordinate.longitude != 0){
                googleReverseGPS(GPSLocation: selectedPostLocation!)
                googleLocationSearch(GPSLocation: selectedPostLocation!)
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
    
// Editing Post Information
    
    var editPost: Bool = false
    
    var editPostImageUrl: String? = nil {
        didSet{
            // Load image URL for editing. New posts will not have imageUrl
            if editPostImageUrl != nil {
                self.imageView.loadImage(urlString: editPostImageUrl!)
                self.selectedImage = self.imageView.image
            }
        }
    }
    
    var editPostId: String? = nil
    
// Selected Post Information

    var selectedPostGooglePlaceID: String? = nil
    var selectedGoogleLocationIndex: Int? = nil
    
    var selectedPostLocation: CLLocation? = nil {
        // Selected Location for Post to Upload
        didSet{
            if selectedPostLocation == nil || (selectedPostLocation?.coordinate.latitude == 0 && selectedPostLocation?.coordinate.longitude == 0){
                self.locationNameLabel.text =  self.blankImageGPSName
                self.locationAdressLabel.text = nil
                self.locationCancelButton.isHidden = true
            }
            else {
                let postLatitude:String! = String(format:"%.4f",(selectedPostLocation?.coordinate.latitude)!)
                let postLongitude:String! = String(format:"%.4f",(selectedPostLocation?.coordinate.longitude)!)
                self.locationNameLabel.text = "GPS: " + " (" + postLatitude + "," + postLongitude + ")"

                self.locationCancelButton.isHidden = false
            }
        }
    }
    
    var selectedPostLocationName:String?{
        // Location from Image
        didSet {
            locationNameLabel.text = selectedPostLocationName
        }
    }
    
    
    var selectedPostLocationAdress:String?{
        // Location Adress from Image
        didSet {
            locationAdressLabel.text = selectedPostLocationAdress
        }
    }
    
    var selectedTime: Date? = nil {
        didSet{
            // get the current date and time
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d YYYY, h:mm a"
            if self.selectedTime == nil {
                self.timeLabel.text = ""
            }
            else {
                self.timeLabel.text = formatter.string(from: self.selectedTime!)
            }
        }
    }
    
// Emoji Variables
    
    var emojiViews: Array<UICollectionView>?
    var selectedEmojis = ""
    var ratingEmoji: String? = nil {
        didSet{
            self.ratingEmojiLabel.text = ratingEmoji
            updateSelectedEmojis()
        }
    }
    
    var nonRatingEmoji: [String]? = nil {
        didSet{
            self.nonRatingEmojiLabel.text = nonRatingEmoji?.joined()
            updateSelectedEmojis()
        }
    }

    var nonRatingEmojiTags:[String]? = nil

// Emoji Functions
    
    func updateSelectedEmojis(){
        var ratingEmojiValue = self.ratingEmojiLabel.text ?? ""
        var nonRatingEmojiValue = self.nonRatingEmojiLabel.text ?? ""
        self.selectedEmojis = ratingEmojiValue + nonRatingEmojiValue
        
        print("Selected Emojis: ", self.selectedEmojis)
        
        // Emoji Cancel Buttons
        
        if ratingEmoji != nil && ratingEmoji != "" {
            // Contains Rating Emoji
            self.ratingEmojiCancelButton.isHidden = false
            self.blankRatingEmoji.isHidden = true
        } else {
            self.ratingEmojiCancelButton.isHidden = true
            self.blankRatingEmoji.isHidden = false
        }
        
        if nonRatingEmoji != nil && nonRatingEmoji?.count != 0 {
            // Contains Non Rating Emoji
            self.nonRatingEmojiCancelButton.isHidden = false
            self.nonRatingEmojiStackView.isHidden = true
        } else {
            self.nonRatingEmojiCancelButton.isHidden = true
            self.nonRatingEmojiStackView.isHidden = false
        }
        
        if self.captionTextView.text != "" && self.captionTextView.text != nil {
            self.captionCancelButton.isHidden = false
        } else {
            self.captionCancelButton.isHidden = true
        }
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
                self.EmojiCollectionView.reloadData()

            }
        } else {
                // Non Rating Emoji Input
            guard let emojiInputTag = emojiInputTag else {
                print("No Emoji Tag for Non Rating Emoji: ", emojiInput)
                return
            }
            
            let dupNonRatingEmojis = tempNonRatingEmoji?.filter({ (item) -> Bool in
//                var emojiDup = item.range(of: emojiInput)
//                return emojiDup != nil ? true : false
                return item == emojiInput
            })
            
            if tempNonRatingEmoji == nil {
              // If No Prior Non Rating Emoji
                tempNonRatingEmoji = [emojiInput]
                tempNonRatingEmojiTags = [emojiInputTag]
                print("Add Non Rating Emoji: ", emojiInput, emojiInputTag)
            }
                
                else if (dupNonRatingEmojis?.count)! > 0 {
                // There is a duplicate Emoji
                if let dupNonRatingEmojiIndex = tempNonRatingEmoji?.index(of: (dupNonRatingEmojis?[0])!) {
                    if (emojiInputTag == (tempNonRatingEmojiTags?[dupNonRatingEmojiIndex])!) || (emojiInputTag == ReverseEmojiDictionary[(tempNonRatingEmojiTags?[dupNonRatingEmojiIndex])!]!) {

                    // Delete if NR emoji and NR emoji tag are same
                    tempNonRatingEmoji?.remove(at: dupNonRatingEmojiIndex)
                    tempNonRatingEmojiTags?.remove(at: dupNonRatingEmojiIndex)
                    print("Remove Non Rating Emoji: ", emojiInput, emojiInputTag)
                        
                    }
                }
            }
            
            else if (tempNonRatingEmoji?.joined().characters.count)! + emojiInput.characters.count < nonRatingEmojiLimit + 1 {
               
//                // Check to see if selected icon is within Multi-Emoji Word. Remove prev tag
//                for emoji in self.nonRatingEmoji! {
//                    if emojiInput.contains(emoji){
//                        
//                        guard let dupNonRatingEmojiIndex = tempNonRatingEmoji?.index(of: emoji) else {
//                            print("Can't find Dup Emoji Index")
//                            return}
//                        tempNonRatingEmoji?.remove(at: dupNonRatingEmojiIndex)
//                        tempNonRatingEmojiTags?.remove(at: dupNonRatingEmojiIndex)
//                    }
//                }
                
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
        self.EmojiCollectionView.reloadData()
    }

    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.rgb(red: 204, green: 238, blue: 255)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handleShare))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(handleBack))
        
        setupEmojiAutoComplete()
        setupImageAndTextViews()
        updateSelectedEmojis()
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
    

    let imageView: CustomImageView = {
        let iv = CustomImageView()
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
    
    let ratingEmojiCancelButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "cancel_shadow").withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(cancelRatingEmoji), for: .touchUpInside)
        return button
        
    } ()
    
    let nonRatingEmojiCancelButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "cancel_shadow").withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(cancelNonRatingEmoji), for: .touchUpInside)
        return button
        
    } ()
    
    
    func cancelRatingEmoji(){
        self.setSelectedEmojis(rateEmoji: nil, nonRateEmoji: self.nonRatingEmoji?.joined())
    }

    func cancelNonRatingEmoji(){
        self.setSelectedEmojis(rateEmoji: self.ratingEmoji, nonRateEmoji: nil)
    }
    
    let captionCancelButton: UIButton = {
        
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "cancel_shadow").withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(cancelCaption), for: .touchUpInside)
        return button
        
    } ()
    
    func cancelCaption(){
        captionTextView.text = nil
        self.captionCancelButton.isHidden = true
        self.setSelectedEmojis(rateEmoji: nil, nonRateEmoji: nil)
    }
    
    func setSelectedEmojis(rateEmoji: String?, nonRateEmoji: String?){
        
        if rateEmoji == nil {
            // Clear Rating Emoji
            self.ratingEmoji = nil
        }
        
        if nonRateEmoji == nil {
            // Clear NonRating Emoji
            self.nonRatingEmoji = nil
            self.nonRatingEmojiTags = nil
        }
        
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
        tv.textAlignment = NSTextAlignment.left
        tv.sizeToFit()
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
        button.setImage(#imageLiteral(resourceName: "mapcolor").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(locationIconPushed), for: .touchUpInside)
        return button
    }()
    
    func locationIconPushed(){
        print("Location Icon was Pushed")
        self.refreshGoogleResults()
        determineCurrentLocation()
    }
    
    func refreshGoogleResults(){
        self.googlePlaceNames.removeAll()
        self.googlePlaceIDs.removeAll()
        self.googlePlaceAdresses.removeAll()
        self.googlePlaceLocations.removeAll()
        self.placesCollectionView.reloadData()
        self.placesCollectionView.collectionViewLayout.invalidateLayout()
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
        button.setImage(#imageLiteral(resourceName: "home").withRenderingMode(.alwaysOriginal), for: .normal)
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
        button.setImage(#imageLiteral(resourceName: "hours").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(timeIconPushed), for: .touchUpInside)
        return button
    }()
    
    func timeIconPushed(){
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
        button.backgroundColor = UIColor.clear
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
        button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(cancelTime), for: .touchUpInside)
        return button
    } ()

    
    func cancelTime(){
        if selectedTime != currentDateTime {
            self.selectedTime = currentDateTime
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d YYYY, h:mm a"
            let attributedText = NSMutableAttributedString(string: formatter.string(from: currentDateTime), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor.mainBlue()])
            self.timeLabel.attributedText = attributedText
        } else {
        selectedTime = nil
        }
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
        view.backgroundColor = UIColor.white
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
        containerView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 35 + 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 100)
        view.addSubview(emojiLabelContainer)
        emojiLabelContainer.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: containerView.topAnchor, right: view.rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 1, paddingRight: 0, width: 0, height: 0)
        print(emojiLabelContainer.frame.height)

// Non Rating Emoji Tags
        view.addSubview(emojiTagLabel)
        emojiTagLabel.anchor(top: emojiLabelContainer.topAnchor, left: emojiLabelContainer.leftAnchor, bottom: emojiLabelContainer.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 90, height: 0)
        view.addSubview(nonRatingEmojiCancelButton)
        nonRatingEmojiCancelButton.anchor(top: emojiTagLabel.topAnchor, left: emojiTagLabel.rightAnchor, bottom: emojiTagLabel.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 15, height: 15)
        view.addSubview(nonRatingEmojiStackView)
        nonRatingEmojiStackView.anchor(top: emojiLabelContainer.topAnchor, left: nonRatingEmojiCancelButton.rightAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: (DefaultEmojiLabelSize + 2) * 4, height: DefaultEmojiLabelSize)
        view.addSubview(nonRatingEmojiLabel)
        nonRatingEmojiLabel.anchor(top: nonRatingEmojiStackView.topAnchor, left: nonRatingEmojiStackView.leftAnchor, bottom: nonRatingEmojiStackView.bottomAnchor, right: self.view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        nonRatingEmojiCancelButton.centerYAnchor.constraint(equalTo: nonRatingEmojiLabel.centerYAnchor)
        nonRatingEmojiCancelButton.isHidden = true
        
// Non Rating Emoji Tags
        view.addSubview(blankRatingEmoji)
        blankRatingEmoji.anchor(top: emojiLabelContainer.topAnchor, left: nil, bottom: emojiLabelContainer.bottomAnchor, right:emojiLabelContainer.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 10, width: DefaultEmojiLabelSize + 2, height: DefaultEmojiLabelSize)

        // Set Rating Emoji Label anchor wider than blank rating emoji to allow emoji text to display
        view.addSubview(ratingEmojiLabel)
        ratingEmojiLabel.anchor(top: blankRatingEmoji.topAnchor, left: blankRatingEmoji.leftAnchor, bottom: blankRatingEmoji.bottomAnchor, right: emojiLabelContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        view.addSubview(ratingEmojiCancelButton)
        ratingEmojiCancelButton.anchor(top: emojiTagLabel.topAnchor, left: nil, bottom: emojiTagLabel.bottomAnchor, right: ratingEmojiLabel.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 15, height: 15)
        ratingEmojiCancelButton.centerYAnchor.constraint(equalTo: ratingEmojiLabel.centerYAnchor)
        ratingEmojiCancelButton.isHidden = true
        
// Image and Caption Setup
        
        view.addSubview(imageView)
        imageView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: nil, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, paddingRight: 0, width: 84, height: 0)
        view.addSubview(captionTextView)
        captionTextView.anchor(top: imageView.topAnchor, left: imageView.rightAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 4, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        captionTextView.delegate = self
        view.addSubview(captionCancelButton)
        captionCancelButton.anchor(top: nil, left: nil, bottom: captionTextView.bottomAnchor, right: captionTextView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 15, height: 15)
//        captionCancelButton.centerYAnchor.constraint(equalTo: emojiTextView.centerYAnchor)
        captionCancelButton.isHidden = true
        

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
        timeCancelButton.anchor(top: timeLabel.topAnchor, left: nil, bottom: timeLabel.bottomAnchor, right: timeLabel.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 20, height: 20)
        view.addSubview(locationIcon)
        locationIcon.anchor(top: timeLabel.bottomAnchor, left: LocationContainerView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 30, height: 30)
        view.addSubview(locationNameLabel)
        locationNameLabel.anchor(top: timeLabel.bottomAnchor, left: locationIcon.rightAnchor, bottom: nil, right: LocationContainerView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 40)
        locationNameLabel.isUserInteractionEnabled = true
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(tapSearchBar))
        locationNameLabel.addGestureRecognizer(TapGesture)
        view.addSubview(locationCancelButton)
        locationCancelButton.anchor(top: locationNameLabel.topAnchor, left: nil, bottom: locationNameLabel.bottomAnchor, right: locationNameLabel.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 20, height: 20)
        view.addSubview(adressIcon)
        adressIcon.anchor(top: locationNameLabel.bottomAnchor, left: LocationContainerView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 30, height: 30)
        view.addSubview(locationAdressLabel)
        locationAdressLabel.anchor(top: locationNameLabel.bottomAnchor, left: adressIcon.rightAnchor, bottom: nil, right: LocationContainerView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10, width: 0, height: 40)
        locationAdressLabel.isUserInteractionEnabled = true
        let TapGesture1 = UITapGestureRecognizer(target: self, action: #selector(tapSearchBar))
        locationAdressLabel.addGestureRecognizer(TapGesture1)
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
        
        // Emoji Auto Complete
        view.addSubview(emojiAutoComplete)
        emojiAutoComplete.anchor(top: LocationContainerView.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        emojiAutoComplete.isHidden = true
    }
    

// Google Search Location Delegates
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        print(place)
        self.refreshGoogleResults()
        self.didUpdate(lat: Double(place.coordinate.latitude), long: Double(place.coordinate.longitude), locationAdress: place.formattedAddress, locationName: place.name, locationGooglePlaceID: place.placeID)
//        self.reloadInputViews()
        dismiss(animated: true, completion: nil)
        
    }
    
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print(error)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }

    func didUpdate(lat: Double?, long: Double?, locationAdress: String?, locationName: String?, locationGooglePlaceID: String?) {
        self.selectedPostLocation = CLLocation.init(latitude: lat!, longitude: long!)
        self.selectedPostGooglePlaceID = locationGooglePlaceID
        self.selectedPostLocationName = locationName
        self.selectedPostLocationAdress = locationAdress
        self.googleReverseGPS(GPSLocation: selectedPostLocation!)
        self.googleLocationSearch(GPSLocation: selectedPostLocation!)
        
    }
    
    func emojiTagging(captionText: String){
        
        var tempCaptionText =  captionText.lowercased()
        
        // Add Space to last tempCaption for searching
        var tempNonRatingEmojiTags = self.nonRatingEmojiTags
        var tempNonRatingEmojis = self.nonRatingEmoji
        var tempRatingEmoji = self.ratingEmoji
        
        if tempRatingEmoji != nil {
            guard let tempRatingEmoji = tempRatingEmoji else {return}
        // Check caption for Rating Emojis
            
            if let range = tempCaptionText.lowercased().range(of: (tempRatingEmoji)){
                // Rating emoji exist as emoji in caption
            } else if let range = tempCaptionText.lowercased().range(of: ReverseEmojiDictionary.key(forValue: tempRatingEmoji)!){
                // Rating emoji exist as text in caption
            } else {
                //Rating Emoji is missing as text or emoji in caption - Remove emoji tag
                emojiTagUntag(emojiInput: tempRatingEmoji, emojiInputTag: nil)
            }
        }
        
        if (tempNonRatingEmojiTags != nil)  && (tempNonRatingEmojis != nil) {
            // Loop through current Emoji Tags, check if tags exist
            
            if tempNonRatingEmojiTags?.count != tempNonRatingEmojis?.count {
                print("ERROR: Non Rating Emojis Not Equal")
            }
            for tag in tempNonRatingEmojiTags! {
                
                var searchTag: String = ""
                if tag.isSingleEmoji{
                    searchTag = tag
                } else {
                    // Avoid finding parts of tag in another word
                    searchTag = tag + " "
                }
                
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
                    
                    // Emoji Tag does not exist anymore, Untag emojis and tags
                    emojiTagUntag(emojiInput: tempNonRatingEmojis?[removeIndex], emojiInputTag: tempNonRatingEmojiTags?[removeIndex])
                    
                    }
                }
        }
        print(tempCaptionText)
   
         // Check for Complex Tags - Replaced with Auto Complete emoji input
        var tempCaptionWords = tempCaptionText.components(separatedBy: " ")
        
        for i in (1...3).reversed() {
            // Check if last n (3 to 1) words match complex dictionary
            
            let captionCheckArray = tempCaptionWords.suffix(i)
            var captionCheckText = captionCheckArray.joined(separator: " ").emojilessString
            print("Caption Check Text: ", captionCheckText)
            
            let emojiLookupResult = ReverseEmojiDictionary[captionCheckText]
            print(emojiLookupResult)
            if emojiLookupResult != nil {
                // If there is a emoji match for words
                if self.nonRatingEmojiTags?.index(of: captionCheckText) == nil {
                    // Check to see if caption tag already exist in current tags. If so ignore (double type)
                    emojiTagUntag(emojiInput: emojiLookupResult, emojiInputTag: captionCheckText)
                    break
                }
            }
        }
        }
 
    
    func textViewDidChange(_ textView: UITextView) {
            var tempCaptionWords = textView.text.components(separatedBy: " ")
            var lastWord = tempCaptionWords[tempCaptionWords.endIndex - 1]
            self.filterContentForSearchText(inputString: lastWord)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        captionCancelButton.isHidden = false
        let char = text.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        
        // If caption textview is not blank
        if textView.text != ""{
            captionCancelButton.isHidden = true
        }
        
        if text == "\n"  // Recognizes enter key in keyboard
        {
            textView.resignFirstResponder()
            return false
        }
        
        if text.isSingleEmoji == true {
            // Emoji was typed
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
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == captionTextView {
            
            if textView.text.isEmpty {
                self.resetCaptionTextView()
            }
            
            // Hide AutoComplete
            self.emojiAutoComplete.isHidden = true
            self.filteredEmojis.removeAll()
        }
    }
    

    func resetCaptionTextView() {
        self.captionTextView.text = captionDefault
        self.captionTextView.textColor = UIColor.lightGray
    }

    // EmojiAutoComplete
    var emojiAutoComplete: UITableView!
    let EmojiAutoCompleteCellId = "EmojiAutoCompleteCellId"
    var filteredEmojis:[Emoji] = []
    var isAutocomplete: Bool = false
    
    func setupEmojiAutoComplete() {
        
        // Emoji Autocomplete View
        emojiAutoComplete = UITableView()
        emojiAutoComplete.register(EmojiCell.self, forCellReuseIdentifier: EmojiAutoCompleteCellId)
        emojiAutoComplete.delegate = self
        emojiAutoComplete.dataSource = self
        emojiAutoComplete.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        emojiAutoComplete.backgroundColor = UIColor.white
    }
    
    func filterContentForSearchText(inputString: String) {
        filteredEmojis = allEmojis.filter({( emoji : Emoji) -> Bool in
            
        
        return emoji.emoji.lowercased().contains(inputString.lowercased()) || (emoji.name?.contains(inputString.lowercased()))!
        })
        
        // Show only if filtered emojis not 0
        if filteredEmojis.count > 0 {
            self.emojiAutoComplete.isHidden = false
        } else {
            self.emojiAutoComplete.isHidden = true
        }
        
        // Sort results based on prefix
        filteredEmojis.sort { (p1, p2) -> Bool in
            ((p1.name?.hasPrefix(inputString))! ? 0 : 1) < ((p2.name?.hasPrefix(inputString))! ? 0 : 1)
        }
        self.emojiAutoComplete.reloadData()
    }
    
    // Tableview delegate functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredEmojis.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EmojiAutoCompleteCellId, for: indexPath) as! EmojiCell
        cell.emoji = filteredEmojis[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var emojiSelected = filteredEmojis[indexPath.row]
        var selectedWord = emojiSelected.name
        var selectedEmoji = emojiSelected.emoji
        var tempEmojiWords = selectedWord?.components(separatedBy: " ")
        var tempCaptionWords = self.captionTextView.text.lowercased().components(separatedBy: " ")
        var lastWord = tempCaptionWords[tempCaptionWords.endIndex - 1]
        var addedString : String?
        
        if tempCaptionWords.count < 2 {
         // Capitalize string
            addedString = emojiSelected.name?.capitalized
        } else {
            addedString = " " + emojiSelected.name!
        }
        
        if tempEmojiWords?.count == 1 || tempCaptionWords.count < 2 {
            // Only one emoji caption or only one word currently in caption, so just substitute last word
            self.captionTextView.text = tempCaptionWords.dropLast().joined(separator: " ") + (addedString)! + " "
            
        } else if tempEmojiWords?.count == 2 {
            // 2 words, so will have to check if previous word should be taken out
            let secondLastWord = tempCaptionWords[tempCaptionWords.endIndex - 2]
            if secondLastWord == tempEmojiWords?[0] {
                // 2nd last word matches first word of 2 word emoji tag, so drop 2nd last word
                if tempCaptionWords.count == 2 {
                    addedString = emojiSelected.name?.capitalized
                }
                self.captionTextView.text = tempCaptionWords.dropLast(2).joined(separator: " ") + (addedString)! + " "
                }
            else {
                self.captionTextView.text = tempCaptionWords.dropLast().joined(separator: " ") + (addedString)! + " "
            }
        }
        self.isAutocomplete = false
        self.emojiAutoComplete.isHidden = true
        self.emojiTagUntag(emojiInput: emojiSelected.emoji, emojiInputTag: emojiSelected.name)
    }
    
    
    func handleDoubleTap(_ gestureReconizer: UITapGestureRecognizer) {

        let p = gestureReconizer.location(in: self.view)

            
            let point = self.EmojiCollectionView.convert(p, from:self.view)
            let indexPath = self.EmojiCollectionView.indexPathForItem(at: point)
        
            if let index = indexPath  {
                let cell = self.EmojiCollectionView.cellForItem(at: index) as! UploadEmojiCell
                var selectedEmoji = cell.uploadEmojis.text
                print("Double Tap Emoji: ", selectedEmoji   )
                self.captionTextView.text =  self.captionTextView.text + selectedEmoji! + selectedEmoji!
                
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
                label.text = ReverseEmojiDictionary.key(forValue: (cell.uploadEmojis.text)!)
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
            
            if (self.selectedEmojis.contains(cell.uploadEmojis.text!)/*||self.captionTextView.text.contains(cell.uploadEmojis.text!)*/){
                //Highlight only if emoji is tagged, dont care about caption
                
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
            
        
            if /*self.captionTextView.text.contains(pressedEmoji) == false &&*/ self.selectedEmojis.contains(pressedEmoji) == false
            {   // Emoji not in caption or tag
                
                if self.captionTextView.text == "Insert Caption Here" {
                    self.captionTextView.text = cell.uploadEmojis.text!
                    self.captionCancelButton.isHidden = false
                } else {
                    self.captionTextView.text = self.captionTextView.text + cell.uploadEmojis.text!
                    self.captionCancelButton.isHidden = false
                }
                self.emojiTagUntag(emojiInput: cell.uploadEmojis.text, emojiInputTag: cell.uploadEmojis.text)
                
                
            } else if self.selectedEmojis.contains(pressedEmoji) == true {
                // Emoji is Tagged, Remove emoji from captions and selected emoji
                
                captionTextView.text = captionTextView.text.replacingOccurrences(of: pressedEmoji, with: "")
                self.emojiTagUntag(emojiInput: cell.uploadEmojis.text, emojiInputTag: cell.uploadEmojis.text)

            }
        }
        
        else if collectionView == placesCollectionView {

            // Unselects Location
            
            if self.selectedPostLocation == self.googlePlaceLocations[indexPath.item] {

                self.selectedPostLocation = self.selectedImageLocation
                self.locationNameLabel.text = self.blankImageGPSName
                self.locationAdressLabel.text = self.selectedPostLocationAdress
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
        // If imageurl exist, then post is being edited. New posts do not have prior image url
        
        // Check for Caption and Location Data
        guard let postImage = selectedImage else {
            self.alert(title: "Upload Post Requirement", message: "Please Insert Picture")
            return}
        guard let caption = captionTextView.text, caption.characters.count > 0 else {
            self.alert(title: "Upload Post Requirement", message: "Please Insert Caption")
            return}
        guard let postLocationName = self.locationNameLabel.text else {return}
        if postLocationName == self.blankImageGPSName {
            self.alert(title: "Upload Post Requirement", message: "Please Tag Location")
            return}
        guard let postLocationAdress = self.locationAdressLabel.text else {
            self.alert(title: "Upload Post Requirement", message: "Please Tag Location")
            return}
        
        if editPost{
            // Editing Post
            guard let postId = self.editPostId else {return}
            guard let imageUrl = self.editPostImageUrl else {return}
            self.saveEditedPost(postId: postId, imageUrl: imageUrl)
            
        } else {
            //Create New Post
            guard let image = selectedImage?.resizeImageWith(newSize: defaultPhotoResize) else {
                self.alert(title: "Upload Post Requirement", message: "Please Insert Picture")
                return }
            guard let uploadData = UIImageJPEGRepresentation(image, 0.5) else {
                self.alert(title: "Upload Post Requirement", message: "Please Insert Picture")
                return}
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
    }
    
    static let updateFeedNotificationName = NSNotification.Name(rawValue: "UpdateFeed")
    
    fileprivate func saveToDatabaseWithImageURL(imageUrl: String) {
        // SAVE POST
        
        guard let postImage = selectedImage else {return}
        var caption = captionTextView.text
        if caption == captionDefault {caption = nil}
        let selectedPostEmoji = selectedEmojis ?? nil
        let googlePlaceID = selectedPostGooglePlaceID ?? nil
        
        // Upload Name Adress that matches inputs
        guard let postLocationName = self.locationNameLabel.text else {return}
        if postLocationName == self.blankImageGPSName {return}
        guard let postLocationAdress = self.locationAdressLabel.text else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        let ratingEmojiUpload = self.ratingEmoji ?? nil
        let nonratingEmojiUpload = self.nonRatingEmoji ?? nil
        let nonratingEmojiTagsUpload = self.nonRatingEmojiTags ?? nil

        var uploadedLocationGPSLatitude: String?
        var uploadedlocationGPSLongitude: String?
        var uploadedLocationGPS: String?
        
        if selectedPostLocation == nil {
            uploadedLocationGPSLatitude = "0"
            uploadedlocationGPSLongitude = "0"
            uploadedLocationGPS = nil
        } else {
            uploadedLocationGPSLatitude = String(format: "%f", (selectedPostLocation?.coordinate.latitude)!)
            uploadedlocationGPSLongitude = String(format: "%f", (selectedPostLocation?.coordinate.longitude)!)
            uploadedLocationGPS = uploadedLocationGPSLatitude! + "," + uploadedlocationGPSLongitude!
        }
        
        let userPostRef = Database.database().reference().child("posts")
        let ref = userPostRef.childByAutoId()
        let uploadTime = Date().timeIntervalSince1970
        let tagTime = self.selectedTime?.timeIntervalSince1970
        
        let values = ["imageUrl": imageUrl, "caption": caption, "imageWidth": postImage.size.width, "imageHeight": postImage.size.height, "creationDate": uploadTime, "googlePlaceID": googlePlaceID, "locationName": postLocationName, "locationAdress": postLocationAdress, "postLocationGPS": uploadedLocationGPS, "creatorUID": uid, "tagTime": tagTime,"ratingEmoji": ratingEmojiUpload, "nonratingEmoji": nonratingEmojiUpload, "nonratingEmojiTags": nonratingEmojiTagsUpload] as [String:Any]
        
        // SAVE POST IN POST DATABASE
        
        ref.updateChildValues(values) { (err, ref) in
            if let err = err {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                print("Failed to save post to DB", err)
                return}
            
            print("Successfully save post to DB")
            
            
            // Put new post in cache
            self.uploadnewPost(uid: uid,postid: ref.key, dictionary: values)
            
            // SAVE USER AND POSTID IN USERPOSTS
            
            let postref = ref.key
            let userPostRef = Database.database().reference().child("userposts").child(uid).child(postref)
            let values = ["creationDate": uploadTime, "tagTime": tagTime, "emoji": selectedPostEmoji] as [String:Any]

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
    
    fileprivate func uploadnewPost(uid: String?, postid: String?, dictionary: [String:Any]?){
        guard let uid = uid else {return}
        guard let dictionary = dictionary else {return}
        
        if uid == CurrentUser.uid{
            newPost = Post.init(user: CurrentUser.user!, dictionary: dictionary)
            newPost?.id = postid
            print("New Post Temp Uploaded: ",newPost)
            
            newPostId = PostId.init(id: postid!, creatorUID: CurrentUser.uid!, fetchedTagTime: 0, fetchedDate:(newPost?.creationDate.timeIntervalSince1970)!, distance: nil, postGPS: nil, postEmoji: newPost?.nonRatingEmoji?.joined())
            
            //Update Cache
            postCache.removeValue(forKey: postid!)
            postCache[postid!] = newPost
            imageCache[postid!] = self.selectedImage
        } else {
            print("Error creating temp new post")
        }
    }

    fileprivate func saveEditedPost(postId: String, imageUrl: String){
        // Edit Post
        
        guard let postImage = selectedImage else {return}
        var caption = captionTextView.text
        if caption == captionDefault {caption = nil}
        let selectedPostEmoji = selectedEmojis ?? nil
        let googlePlaceID = selectedPostGooglePlaceID ?? nil
        
        // Upload Name Adress that matches inputs
        guard let postLocationName = self.locationNameLabel.text else {return}
        if postLocationName == self.blankImageGPSName {return}
        guard let postLocationAdress = self.locationAdressLabel.text else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        let ratingEmojiUpload = self.ratingEmoji ?? nil
        let nonratingEmojiUpload = self.nonRatingEmoji ?? nil
        let nonratingEmojiTagsUpload = self.nonRatingEmojiTags ?? nil
        
        var uploadedLocationGPSLatitude: String?
        var uploadedlocationGPSLongitude: String?
        var uploadedLocationGPS: String?
        
        if selectedPostLocation == nil {
            uploadedLocationGPS = nil
        } else {
            uploadedLocationGPSLatitude = String(format: "%f", (selectedPostLocation?.coordinate.latitude)!)
            uploadedlocationGPSLongitude = String(format: "%f", (selectedPostLocation?.coordinate.longitude)!)
            uploadedLocationGPS = uploadedLocationGPSLatitude! + "," + uploadedlocationGPSLongitude!
        }
        
        let userPostRef = Database.database().reference().child("posts").child(postId)
        let uploadTime = Date().timeIntervalSince1970
        let tagTime = self.selectedTime?.timeIntervalSince1970
        
        let values = ["imageUrl": imageUrl, "caption": caption, "imageWidth": postImage.size.width, "imageHeight": postImage.size.height, "creationDate": uploadTime, "googlePlaceID": googlePlaceID, "locationName": postLocationName, "locationAdress": postLocationAdress, "postLocationGPS": uploadedLocationGPS, "creatorUID": uid, "tagTime": tagTime,"ratingEmoji": ratingEmojiUpload, "nonratingEmoji": nonratingEmojiUpload, "nonratingEmojiTags": nonratingEmojiTagsUpload, "editDate": uploadTime] as [String:Any]
        userPostRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                print("Failed to save edited post to DB", err)
                return
            }
            
            print("Successfully save edited post to DB")
            
            // Put new post
            self.uploadnewPost(uid: uid,postid: postId, dictionary: values)

            
            // SAVE USER AND POSTID
            
            let userPostRef = Database.database().reference().child("userposts").child(uid).child(postId)
            let values = ["creationDate": uploadTime, "tagTime": tagTime, "emoji": selectedPostEmoji] as [String:Any]
            
            userPostRef.updateChildValues(values) { (err, ref) in
                if let err = err {
                    print("Failed to save edited post to user", err)
                    return
                }
                print("Successfully save edited post to user")
            }
            
            
            // SAVE GEOFIRE LOCATION DATA
            
            let geofireRef = Database.database().reference().child("postlocations")
            guard let geoFire = GeoFire(firebaseRef: geofireRef) else {return}
            //            let geofirekeytest = uid+","+postref
            
            geoFire.setLocation(self.selectedPostLocation, forKey: postId) { (error) in
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
            self.selectedPostLocation = userLocation
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

            self.selectedPostLocationAdress = subThoroughfare! + " " + thoroughfare! + ", " + locality! + ", " + state! + " " + postalCode!
            
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
                    self.selectedPostLocationAdress = results[0]["formatted_address"].string

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

    var googlePlaceNames = [String]()
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
        
        // https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=41.9542116666667,-87.7055883333333&radius=100.0&rankby=distance&type=restaurant&key=AIzaSyAzwACZh50Qq1V5YYKpmfN21mZs8dW6210        
        
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
                            
                                // Filter for results with more detail
                                let check = result["opening_hours"]
                                if check != nil {
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



