//
//  LocationController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/11/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import Firebase
import GeoFire
import GooglePlaces
import Alamofire
import SwiftyJSON

var placeCache = [String: JSON]()

class LocationController: UIViewController, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, GMSMapViewDelegate, UserProfilePhotoCellDelegate, CLLocationManagerDelegate  {
    
    let locationManager = CLLocationManager()
    let locationCellId = "locationCellID"
    let photoCellId = "photoCellId"
    
    var postNearby: [String: CLLocation] = [:]
    
    var selectedPost: Post?{
        didSet{
//            locationNameLabel.text = selectedPost?.locationName
//            locationDistanceLabel.text = selectedPost?.locationAdress
            
//            self.refreshMap(long: selectedLong!, lat: selectedLat!)
            
            // Passes Coordinates And/Or Google Place ID
            selectedLat = selectedPost?.locationGPS?.coordinate.latitude
            selectedLong = selectedPost?.locationGPS?.coordinate.longitude
            selectedLocation = selectedPost?.locationGPS
            selectedAdress = selectedPost?.locationAdress
            self.googlePlaceId = selectedPost?.locationGooglePlaceID
        }
    }
    
    
    var googlePlaceId: String? = nil {
        didSet{
            if googlePlaceId != "" && googlePlaceId != nil {
                // Google Place ID Exists
                self.populatePlaceDetails(placeId: googlePlaceId)
                self.fetchPostForPostLocation(placeId: googlePlaceId!)
//            self.filterPostByLocation(location: CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!))
            } else {
                // Google Place ID Doesnt Exist
                self.fetchPostWithLocation(location: CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!))
                self.googleLocationSearch(GPSLocation: CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!))
                
            }
        }
    }
    var displayedPosts = [Post]()
    var placesClient: GMSPlacesClient!

    var selectedLong: Double? = 0
    var selectedLat: Double? = 0
    var selectedLocation: CLLocation?
    
    var selectedAdress: String?
    
    var marker = GMSMarker()
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.delegate = self
        view.backgroundColor = UIColor.white
        return view
    }()
    
    lazy var tempView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    lazy var placeDetailsView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    
    lazy var map: GMSMapView = {
        let mp = GMSMapView()
        mp.mapType = .normal
        return mp
    }()
    
    func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay) {
        mapView.delegate = self
        print("Tapped")
        self.activateMap()
    }
    
    let locationNameView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.rgb(red: 128, green: 191, blue: 255)
        return view
    }()
    
    lazy var locationNameLabel: PaddedUILabel = {
        let ul = PaddedUILabel()
        ul.text = "Name: "
        ul.font = UIFont.systemFont(ofSize: 12)
        ul.backgroundColor = UIColor(white: 1, alpha: 0.75)
        ul.layer.backgroundColor = UIColor.rgb(red: 128, green: 191, blue: 255).cgColor
        ul.layer.borderWidth = 1
        ul.layer.cornerRadius = 5
        ul.layer.masksToBounds = true
        
        return ul
    }()
    
    let locationNameIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "home").withRenderingMode(.alwaysOriginal), for: .normal)
        return button
    }()
    
    let locationDistanceView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.rgb(red: 128, green: 191, blue: 255)
        return view
    }()
    
    lazy var locationDistanceLabel: PaddedUILabel = {
        let ul = PaddedUILabel()
        ul.text = "Name: "
        ul.isUserInteractionEnabled = true
        ul.font = UIFont.systemFont(ofSize: 10)
        ul.backgroundColor = UIColor(white: 1, alpha: 0.75)
        ul.layer.backgroundColor = UIColor.rgb(red: 128, green: 191, blue: 255).cgColor
        ul.layer.borderWidth = 0.5
        ul.layer.cornerRadius = 5
        ul.layer.masksToBounds = true
        ul.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(activateMap)))
        return ul
    }()
    
    let locationDistanceIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "GeoFence").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activateMap), for: .touchUpInside)
        return button
    }()

    let locationHoursView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    lazy var locationHoursLabel: PaddedUILabel = {
        let ul = PaddedUILabel()
        ul.text = "Name: "
        ul.isUserInteractionEnabled = true
        ul.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(locationHoursIconTapped)))
        return ul
    }()
    
    let locationHoursIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "hours").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(locationHoursIconTapped), for: .touchUpInside)
        return button
    }()
    
    let locationPhoneView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    lazy var locationPhoneLabel: PaddedUILabel = {
        let ul = PaddedUILabel()
        ul.text = "Name: "
        ul.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(activatePhone)))
        
        return ul
    }()
    
    let locationPhoneIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "phone").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activatePhone), for: .touchUpInside)
        
        return button
    }()
    
    let locationWebsiteView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    lazy var locationWebsiteLabel: PaddedUILabel = {
        let ul = PaddedUILabel()
        ul.text = "Name: "
        ul.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(activateBrowser)))
        return ul
    }()
    
    let locationWebsiteIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "website").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activateBrowser), for: .touchUpInside)
        return button
    }()

    func locationHoursIconTapped(){
        
        var timeString = "" as String
        for time in self.placeOpeningHours! {
            timeString = timeString + time.string! + "\n"
        }
        
        self.alert(title: "Opening Hours", message: timeString)
    }
    
    func activatePhone(){
        guard let url = URL(string: "tel://\(self.placePhoneNo!)") else {
            return //be safe
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    func activateBrowser(){
        guard let url = URL(string: self.placeWebsite!) else {
            return //be safe
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    lazy var collectionViewTitleLabel: PaddedUILabel = {
        let ul = PaddedUILabel()
        ul.text = "Photos From Location:"
        ul.font = UIFont.boldSystemFont(ofSize: 15)
        return ul
    }()
    
    lazy var noIdLabel: PaddedUILabel = {
        let ul = PaddedUILabel()
        ul.text = "Restaurants Around Location"
        ul.font = UIFont.boldSystemFont(ofSize: 15)
        return ul
    }()
    
    lazy var photoCollectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UIColor(white: 0, alpha: 0.03)
        cv.isScrollEnabled = false
        return cv
    }()
    
    lazy var placesCollectionView : UICollectionView = {
        let uploadLocationTagList = UploadLocationTagList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UIColor(white: 0, alpha: 0.03)
        return cv
    }()
    
    
    func didTapPicture(post: Post) {
        let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
        pictureController.selectedPost = post
        
        navigationController?.pushViewController(pictureController, animated: true)
    }
    

    var placeName: String?
    var placeOpeningHours: [JSON]?
    var placePhoneNo: String?
    var placeWebsite: String?
    var placeGoogleRating: Double?
    var placeOpenNow: Bool?
    var placeGoogleMapUrl: String?
    var placeDetailStackview = UIStackView()
    
    
    func populatePlaceDetails(placeId: String?){
        guard let placeId = placeId else {
            print("Google Place Id is nil")
            return
        }

        let URL_Search = "https://maps.googleapis.com/maps/api/place/details/json?"
        let API_iOSKey = GoogleAPIKey()
        
//        https://maps.googleapis.com/maps/api/place/details/json?placeid=ChIJbd2OryfY3IARR6800Hij7-Q&key=AIzaSyAzwACZh50Qq1V5YYKpmfN21mZs8dW6210
        
        let urlString = "\(URL_Search)placeid=\(placeId)&key=\(API_iOSKey)"
        let url = URL(string: urlString)!
        print("Google Places URL: ",urlString)

//        print("Place Cache for postid: ", placeId, placeCache[placeId])
        if let result = placeCache[placeId] {
//            print("Using Place Cache for placeId: ", placeId)
            self.extractPlaceDetails(fetchedResults: result)
        } else {
        
        Alamofire.request(url).responseJSON { (response) -> Void in
//                        print("Google Response: ",response)
            if let value  = response.result.value {
                let json = JSON(value)
                let result = json["result"]

                placeCache[placeId] = result
                self.extractPlaceDetails(fetchedResults: result)
                }
            }
        }
    }
    
    func extractPlaceDetails(fetchedResults: JSON){
        
        let result = fetchedResults
//        print("Fetched Results: ",result)
        if result["place_id"].string != nil {
            
            self.placeName = result["name"].string ?? ""
//            print("place Name: ", self.placeName)
            self.locationNameLabel.text = self.placeName
            self.navigationItem.title = self.placeName
            
            self.placeOpeningHours = result["opening_hours"]["weekday_text"].arrayValue
//            print("placeOpeningHours: ", self.placeOpeningHours)
            
            let today = Date()
            let myCalendar = Calendar(identifier: .gregorian)
            let weekDay = myCalendar.component(.weekday, from: today)
            
            var hourIndex: Int?
            if weekDay == 1 {
                hourIndex = 6
            } else {
                hourIndex = weekDay - 2
            }
            
            self.placeOpenNow = result["open_now"].boolValue ?? false
//            print("placeOpenNow: ", self.placeOpenNow)
            
            if self.placeOpeningHours! != [] {
                let todayHours = String(describing: (self.placeOpeningHours?[hourIndex!])!)
                    self.locationHoursLabel.text = todayHours
                
            if self.placeOpenNow! {
                // If Open Now
                var attributedText = NSMutableAttributedString(string: todayHours, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12),NSForegroundColorAttributeName: UIColor.mainBlue()])
                attributedText.append(NSMutableAttributedString(string: " (Open Now)", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12),NSForegroundColorAttributeName: UIColor.rgb(red: 0, green: 153, blue: 51)]))
                self.locationHoursLabel.attributedText = attributedText
            } else {
                var attributedText = NSMutableAttributedString(string: todayHours, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12),NSForegroundColorAttributeName: UIColor.black])
                attributedText.append(NSMutableAttributedString(string: " (Closed)", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12),NSForegroundColorAttributeName: UIColor.red]))
                self.locationHoursLabel.attributedText = attributedText
            }
            } else {
                // No Opening Hours from Google
                self.locationHoursLabel.text = ""
                
            }
        
            self.placePhoneNo = result["formatted_phone_number"].string ?? ""
//            print("placePhoneNo: ", self.placePhoneNo)
            self.locationPhoneLabel.text = self.placePhoneNo
            
            self.placeWebsite = result["website"].string ?? ""
//            print("placeWebsite: ", self.placeWebsite)
            self.locationWebsiteLabel.text = self.placeWebsite
            
            self.placeGoogleRating = result["rating"].double ?? 0
//            print("placeGoogleRating: ", self.placeGoogleRating)
            
            self.placeGoogleMapUrl = result["url"].string!
            
            self.selectedLong = result["geometry"]["location"]["lat"].double ?? 0
            self.selectedLat = result["geometry"]["location"]["lng"].double ?? 0
            self.selectedLocation = CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!)
            self.refreshMap(long: self.selectedLat!, lat: self.selectedLong!)
            
            self.selectedAdress = result["formatted_address"].string ?? ""
            self.locationDistanceLabel.text = self.selectedAdress
            
            
        } else {
            print("Failed to extract Google Place Details")
        }
    }
    
    
    func updateAdressLabel() {
        
        guard let selectedLocation = self.selectedLocation else {return}
        guard let currentUserLocation = CurrentUser.currentLocation else {return}
        guard let selectedAdress = self.selectedAdress else {return}
        
        var distance = Double((selectedLocation.distance(from: currentUserLocation)))
        
        // Convert to M to KM
        let locationDistance = distance/1000
        let distanceformat = ".2"
        let adressString = (selectedAdress).truncate(length: 30)
        
        if locationDistance < 1000 {
            var attributedString = NSMutableAttributedString(string: " \(adressString)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12),NSForegroundColorAttributeName: UIColor.black])
            attributedString.append(NSMutableAttributedString(string: " (\(locationDistance.format(f: distanceformat)) KM)", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12),NSForegroundColorAttributeName: UIColor.mainBlue()]))
            self.locationDistanceLabel.attributedText = attributedString
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    

// Created a temp uiview and pinned all labels/map/pics onto temp uiview
// Created scrollview and pinned temp uiview on top of scroll view
// Added ScrollView onto view
        
        determineCurrentLocation()
        
        scrollView.frame = view.bounds
        scrollView.backgroundColor = UIColor.white
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.contentSize = CGSize(width: view.bounds.width, height: view.bounds.height * 2)
        
        tempView.addSubview(placeDetailsView)
        placeDetailsView.anchor(top: tempView.topAnchor, left: tempView.leftAnchor, bottom: nil, right: tempView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 5 * (30 + 2 + 2))
        
        // Location Adress Label
        setupLocationLabels(containerview: locationDistanceView, icon: locationDistanceIcon, label: locationDistanceLabel)
        tempView.addSubview(locationDistanceView)
        locationDistanceView.anchor(top: nil, left: placeDetailsView.leftAnchor, bottom: placeDetailsView.bottomAnchor, right: placeDetailsView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30 + 2 + 2)
        
        // Location Name Label
        placeDetailsView.addSubview(locationNameView)
        locationNameView.anchor(top: nil, left: placeDetailsView.leftAnchor, bottom: locationDistanceView.topAnchor, right: placeDetailsView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30 + 2 + 2)
        
        let buttonStackView = UIStackView(arrangedSubviews: [locationHoursIcon, locationPhoneIcon,locationWebsiteIcon])
        buttonStackView.distribution = .fillEqually
        
        locationNameView.addSubview(locationNameIcon)
        locationNameView.addSubview(locationNameLabel)
        locationNameView.addSubview(buttonStackView)
        
        buttonStackView.anchor(top: locationNameView.topAnchor, left: nil, bottom: locationNameView.bottomAnchor, right: locationNameView.rightAnchor, paddingTop: 2, paddingLeft: 5, paddingBottom: 2, paddingRight: 15, width: 90, height: 0)
        
        locationNameIcon.anchor(top: locationNameView.topAnchor, left: locationNameView.leftAnchor, bottom: locationNameView.bottomAnchor, right: nil, paddingTop: 2, paddingLeft: 15, paddingBottom: 2, paddingRight: 5, width: 30, height: 30)
        
        locationNameLabel.anchor(top: locationNameView.topAnchor, left: locationNameIcon.rightAnchor, bottom: locationNameView.bottomAnchor, right: buttonStackView.leftAnchor, paddingTop: 2, paddingLeft: 15, paddingBottom: 2, paddingRight: 5, width: 0, height: 0)
        
        // Add Map
        placeDetailsView.addSubview(map)
        map.anchor(top: placeDetailsView.topAnchor, left: placeDetailsView.leftAnchor, bottom: locationNameView.topAnchor, right: placeDetailsView.rightAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 0, paddingRight: 1, width: 0, height: 0)
        map.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(activateMap))
        tapGesture.numberOfTapsRequired = 1
        
        map.addGestureRecognizer(tapGesture)
        map.isUserInteractionEnabled = true
        
        if self.selectedLong != nil && self.selectedLat != nil {
            self.refreshMap(long: self.selectedLong!, lat: self.selectedLat!)
        }
        
        tempView.addSubview(collectionViewTitleLabel)
        collectionViewTitleLabel.anchor(top: placeDetailsView.bottomAnchor, left: tempView.leftAnchor, bottom: nil, right: tempView.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 20)
        
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor.white
        tempView.addSubview(bottomDividerView)
        bottomDividerView.anchor(top: collectionViewTitleLabel.bottomAnchor, left: tempView.leftAnchor, bottom: nil, right: tempView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        tempView.addSubview(photoCollectionView)
        photoCollectionView.anchor(top: bottomDividerView.bottomAnchor, left: tempView.leftAnchor, bottom: tempView.bottomAnchor, right: tempView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 500)
        photoCollectionView.register(UserProfilePhotoCell.self, forCellWithReuseIdentifier: photoCellId)
        
        scrollView.addSubview(tempView)

        self.view.addSubview(scrollView)
        tempView.anchor(top: scrollView.topAnchor, left: view.leftAnchor, bottom: scrollView.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        let tapGestureMsg = UITapGestureRecognizer(target: self, action: #selector(didTapNavMessage))
        tapGestureMsg.numberOfTapsRequired = 1
        
        var rangeImageButton = UIImageView(frame: CGRect(x: 0, y: 0, width: 15, height: 15))
        rangeImageButton.image = #imageLiteral(resourceName: "shoutaround").withRenderingMode(.alwaysOriginal)
        rangeImageButton.contentMode = .scaleAspectFit
        rangeImageButton.sizeToFit()
        rangeImageButton.backgroundColor = UIColor.clear
        rangeImageButton.addGestureRecognizer(tapGestureMsg)

        let rangeBarButton = UIBarButtonItem.init(customView: rangeImageButton)
        navigationItem.rightBarButtonItem = rangeBarButton

        
        if googlePlaceId != ""{
            self.populatePlaceDetails(placeId: self.googlePlaceId)
        } else{
            self.googleLocationSearch(GPSLocation: CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!))
            
            tempView.addSubview(placesCollectionView)
            placesCollectionView.anchor(top: locationNameView.topAnchor, left: locationNameView.leftAnchor, bottom: locationNameView.bottomAnchor, right: locationNameView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            placesCollectionView.backgroundColor = UIColor.rgb(red: 128, green: 191, blue: 255)
            placesCollectionView.register(UploadLocationCell.self, forCellWithReuseIdentifier: locationCellId)
            
            placesCollectionView.delegate = self
            placesCollectionView.dataSource = self
            placesCollectionView.showsHorizontalScrollIndicator = false
            
            collectionViewTitleLabel.text = "Photos Around Location"
            self.placesCollectionView.reloadData()
            self.photoCollectionView.reloadData()

        }
        
        // Location Posts Fetching functions are called on the top when posts and googleplaceids are set
        
    }
    
    func setupPlaceDetailStackview(){
        
        setupLocationLabels(containerview: locationNameView, icon: locationNameIcon, label: locationNameLabel)
        setupLocationLabels(containerview: locationHoursView, icon: locationHoursIcon, label: locationHoursLabel)
        setupLocationLabels(containerview: locationPhoneView, icon: locationPhoneIcon, label: locationPhoneLabel)
        setupLocationLabels(containerview: locationWebsiteView, icon: locationWebsiteIcon, label: locationWebsiteLabel)
        setupLocationLabels(containerview: locationDistanceView, icon: locationDistanceIcon, label: locationDistanceLabel)
        
        placeDetailStackview = UIStackView(arrangedSubviews: [locationNameView, locationHoursView, locationPhoneView, locationWebsiteView, locationDistanceView])
        placeDetailStackview.distribution = .fillEqually
        placeDetailStackview.axis = .vertical
   
    }
    
    
    var noIdView = UIView()
    
    func showNoPlaceIDStackview(){

        noIdView.addSubview(locationDistanceView)
        locationDistanceView.anchor(top: nil, left: noIdView.leftAnchor, bottom: noIdView.bottomAnchor, right: noIdView.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 2, paddingRight: 0, width: 0, height: 35)
        
        noIdView.addSubview(locationNameIcon)
        locationNameIcon.anchor(top: nil, left: noIdView.leftAnchor, bottom: locationDistanceView.topAnchor, right: nil, paddingTop: 2, paddingLeft: 15, paddingBottom: 2, paddingRight: 5, width: 30, height: 30)
        
        noIdView.addSubview(placesCollectionView)
        placesCollectionView.anchor(top: nil, left: locationNameIcon.rightAnchor, bottom: locationDistanceView.topAnchor, right: noIdView.rightAnchor, paddingTop: 2, paddingLeft: 5, paddingBottom: 2, paddingRight: 5, width: 0, height: 40)
        placesCollectionView.backgroundColor = UIColor.white
        placesCollectionView.register(UploadLocationCell.self, forCellWithReuseIdentifier: locationCellId)
        placesCollectionView.delegate = self
        placesCollectionView.dataSource = self
        
        noIdView.addSubview(map)
        map.anchor(top: noIdView.topAnchor, left: noIdView.leftAnchor, bottom: placesCollectionView.topAnchor, right: noIdView.rightAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 0, paddingRight: 1, width: 0, height: 0)
        map.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(activateMap))
        tapGesture.numberOfTapsRequired = 1
        
        map.addGestureRecognizer(tapGesture)
        map.isUserInteractionEnabled = true
        self.refreshMap(long: self.selectedLong!, lat: self.selectedLat!)
        //        map.heightAnchor.constraint(equalTo: map.widthAnchor, multiplier: 1).isActive = true
        
        


    }
    
    func setupLocationLabels(containerview: UIView, icon: UIButton, label: UILabel){
        containerview.addSubview(icon)
        containerview.addSubview(label)
        containerview.backgroundColor = UIColor.rgb(red: 128, green: 191, blue: 255)
        
        icon.anchor(top: containerview.topAnchor, left: containerview.leftAnchor, bottom: containerview.bottomAnchor, right: nil, paddingTop: 2, paddingLeft: 15, paddingBottom: 2, paddingRight: 5, width: 30, height: 30)
        //        icon.widthAnchor.constraint(equalTo: locationNameIcon.heightAnchor, multiplier: 1)
        
        label.anchor(top: containerview.topAnchor, left: icon.rightAnchor, bottom: containerview.bottomAnchor, right: containerview.rightAnchor, paddingTop: 2, paddingLeft: 15, paddingBottom: 2, paddingRight: 15, width: 0, height: 0)
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 12)
        label.backgroundColor = UIColor(white: 1, alpha: 0.75)
        label.layer.borderWidth = 0.5
        label.layer.cornerRadius = 5
    }
    
    
    
    func activateMap() {
        if (UIApplication.shared.canOpenURL(NSURL(string:"https://www.google.com/maps/search/?api=1&query=\(selectedLat!),\(selectedLong!)")! as URL)) {
            UIApplication.shared.openURL(NSURL(string:
                "https://www.google.com/maps/search/?api=1&query=\(selectedLat!),\(selectedLong!)")! as URL)
            
        } else {

            NSLog("Can't use comgooglemaps://");
        }
    }
    

     func didTapNavMessage() {
        let messageController = MessageController()
        if selectedPost == nil {
            // Show first found post if no selected post
            if displayedPosts.count == 0 {
                self.alert(title: "Message Error", message: "No Available Post to Send")
            } else {
            messageController.post = displayedPosts[0]
            }
        } else {
        messageController.post = selectedPost
        }
        
        navigationController?.pushViewController(messageController, animated: true)
        
    }
    
    func pushMessage(post: Post){
        
    }
    
    override func viewDidLayoutSubviews() {

        
    }
    
    func fetchPostForPostLocation(placeId:String){
        
        displayedPosts.removeAll()
        
        if placeId != "" {
            self.fetchPostWithGooglePlaceID(googlePlaceID: placeId)
        } else if (self.selectedLat != 0 &&  self.selectedLong != 0) {
            self.fetchPostWithLocation(location: CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!))
        } else {
            self.alert(title: "Error", message: "Error Fetching Post based on this location")
        }
        
        
    }
    
    func fetchPostWithLocation(location: CLLocation){
        
        print("No Google Place ID. Searching Posts by Location: ", location)
        Database.fetchAllPostWithLocation(location: location, distance: 25) { (fetchedPosts) in

            self.displayedPosts = fetchedPosts
            print("Fetching Post with Location: \(location)")
            self.photoCollectionView.reloadData()
        }
        
    }
    
    func fetchPostWithGooglePlaceID(googlePlaceID: String){
        print("Searching Posts by Google Place ID: ", googlePlaceID)
        Database.fetchAllPostWithGooglePlaceID(googlePlaceId: googlePlaceID) { (fetchedPosts) in
            self.displayedPosts = fetchedPosts
            print("Fetching Post with googlePlaceId: \(googlePlaceID)")
            self.photoCollectionView.reloadData()
        }
        
    }
    
    func refreshMap(long: Double, lat: Double) -> (){
        
        self.map.clear()
        
        let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: 13)
        print("refresh map", camera)
        self.map.camera = camera
        
        let position = CLLocationCoordinate2DMake(lat, long)
        let marker = GMSMarker(position: position)
        print("Marker GPS, ", marker)
        marker.title = "Hello World"
        marker.isDraggable = false
        marker.appearAnimation = .pop
        
        marker.map = self.map
        
        
    }
    
    func filterPostByLocation(location: CLLocation){
        
        let ref = Database.database().reference().child("postlocations")
        let geoFire = GeoFire(firebaseRef: ref)
        
        var geoFilteredPosts = [Post]()
        self.postNearby.removeAll()
        
            print("Current User Location Used for Post Filtering", location)
            let circleQuery = geoFire?.query(at: location, withRadius: 5)
            circleQuery?.observe(.keyEntered, with: { (key, location) in
 
                guard let postId: String = key! else {return}
                guard let postLocation: CLLocation = location else {return}
                
                self.postNearby[key!] = postLocation
                
            })
            
            circleQuery?.observeReady({

                self.addMarkers()
                
            })
        
    }
    
    func addMarkers() {
        
        
        for post in self.displayedPosts {
            
            let postUID: String = post.id!
            let postLocation: CLLocation = post.locationGPS!
            
            let state_marker = GMSMarker()
            print("Marker Coordinate: \(postLocation)")
            state_marker.position = CLLocationCoordinate2D(latitude: postLocation.coordinate.latitude, longitude: postLocation.coordinate.longitude)
            state_marker.title = postUID
            state_marker.snippet = "Hey, this is \(postLocation.description)"
            state_marker.isTappable = true
            state_marker.map = self.map
        }
  
    }
//    
//    func addMarkers() {
//        
//        
//        for post in self.postNearby {
//            
//            let postUID: String = post.key
//            let postLocation: CLLocation = post.value
//            
//            let state_marker = GMSMarker()
//            print(postLocation.coordinate.latitude)
//            print(postLocation.coordinate.latitude)
//            state_marker.position = CLLocationCoordinate2D(latitude: postLocation.coordinate.latitude, longitude: postLocation.coordinate.longitude)
//            state_marker.title = postUID
//            state_marker.snippet = "Hey, this is \(postLocation.description)"
//            state_marker.isTappable = true
//            state_marker.map = self.map
//        }
//        
//    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        Database.fetchPostWithPostID(postId: marker.title!) { (post, error) in
            
            guard let post = post else {return}
            
            let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
            pictureController.selectedPost = post
            self.navigationController?.pushViewController(pictureController, animated: true)
        
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == placesCollectionView{
            
            let locationController = LocationController()
            print(googlePlaceIDs[indexPath.row])
            locationController.googlePlaceId = googlePlaceIDs[indexPath.item]
            navigationController?.pushViewController(locationController, animated: true)
            
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == photoCollectionView {
            return 1
        }
        else if collectionView == placesCollectionView {
            return 5
        } else {return 1}
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        if collectionView == photoCollectionView {
            return 1
        }
        else if collectionView == placesCollectionView {
            return 5
        } else {return 1}
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == photoCollectionView {
            let width = (view.frame.width - 2) / 3
            return CGSize(width: width, height: width)
        } else {return CGSize(width: 10, height: 10)}
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == photoCollectionView {
            return displayedPosts.count
        }
        if collectionView == placesCollectionView {
            return googlePlaceNames.count
        } else{
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == photoCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellId, for: indexPath) as! UserProfilePhotoCell
            cell.delegate = self
            cell.post = displayedPosts[indexPath.item]
            return cell
        } else if collectionView == placesCollectionView{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationCellId, for: indexPath) as! UploadLocationCell
            cell.uploadLocations.font = UIFont.systemFont(ofSize: 13)
            cell.uploadLocations.text = googlePlaceNames[indexPath.item]
//            cell.backgroundColor = UIColor(white: 0, alpha: 0.03)
            cell.backgroundColor = UIColor.white
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellId, for: indexPath) as! UserProfilePhotoCell
            cell.delegate = self
            cell.post = displayedPosts[indexPath.item]
            return cell
        }
        
    }

    // LOCATION MANAGER DELEGATE METHODS
    
    func determineCurrentLocation(){
        
        CurrentUser.currentLocation = nil
        locationManager.delegate = self
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        if userLocation != nil {
            print("Current User Location", userLocation)
            CurrentUser.currentLocation = userLocation
            manager.stopUpdatingLocation()
            updateAdressLabel()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("GPS Location Not Found")
    }
    
    func googleLocationSearch(GPSLocation: CLLocation){
        
        let dataProvider = GoogleDataProvider()
        let searchRadius: Double = 100
        var searchedTypes = ["restaurant"]
        var searchTerm = "restaurant"
        
        downloadRestaurantDetails(GPSLocation, searchRadius: searchRadius, searchType: searchTerm)
        
    }
    
    var googlePlaceNames = [String?]()
    var googlePlaceIDs = [String]()
    var googlePlaceAdresses = [String]()
    var googlePlaceLocations = [CLLocation]()
    
    func downloadRestaurantDetails(_ lat: CLLocation, searchRadius:Double, searchType: String ) {
        let URL_Search = "https://maps.googleapis.com/maps/api/place/search/json?"
        let API_iOSKey = GoogleAPIKey()
        
        let urlString = "\(URL_Search)location=\(lat.coordinate.latitude),\(lat.coordinate.longitude)&rankby=distance&type=\(searchType)&key=\(API_iOSKey)"
        let url = URL(string: urlString)!
        
        print("Restaurant Google Download URL: \(urlString)")
        
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
                        print("Fetched Google Place Names Results: ",result)
                        if result["place_id"].string != nil {
                            guard let placeID = result["place_id"].string else {return}
                            guard let name = result["name"].string else {return}
                            guard let locationAdress = result["vicinity"].string else {return}
                            guard let postLatitude = result["geometry"]["location"]["lat"].double else {return}
                            guard let postLongitude = result["geometry"]["location"]["lng"].double else {return}
                            
                            // Checks to make sure its not a blank result
                            
                            let locationGPStempcreate = CLLocation(latitude: postLatitude, longitude: postLongitude)
                            
                            let check = result["opening_hours"]
                            if check != nil  {
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
