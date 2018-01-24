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
import EmptyDataSet_Swift

var placeCache = [String: JSON]()

class LocationController: UIViewController, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, GMSMapViewDelegate, GridPhotoCellDelegate, EmptyDataSetSource, EmptyDataSetDelegate, LastLocationPhotoCellDelegate, SortFilterHeaderDelegate, FilterControllerDelegate  {
    
    var placesClient: GMSPlacesClient!
    var marker = GMSMarker()
    var map: GMSMapView?
    
    let locationCellId = "locationCellID"
    let photoHeaderId = "photoHeaderId"
    let photoCellId = "photoCellId"
    let lastPhotoCellId = "lastPhotoCellId"

    var displayedPosts = [Post]()
    var postNearby: [String: CLLocation] = [:]

    // INPUT FROM DELEGATE
    var selectedPost: Post?{
        didSet{
//            locationNameLabel.text = selectedPost?.locationName
//            locationDistanceLabel.text = selectedPost?.locationAdress
//            self.refreshMap(long: selectedLong!, lat: selectedLat!)
            
            selectedLocation = selectedPost?.locationGPS
            selectedName = selectedPost?.locationName
            selectedAdress = selectedPost?.locationAdress
            self.googlePlaceId = selectedPost?.locationGooglePlaceID
            self.checkHasRestaurantLocation()
        }
    }
    
    // MAIN INPUT
    var googlePlaceId: String? = nil {
        didSet{
            self.checkHasRestaurantLocation()
            // Google Place ID Exists
        }
    }
    
    var hasRestaurantLocation: Bool = false
    
    var selectedLocation: CLLocation? {
        didSet{
            if selectedLocation?.coordinate.latitude == 0 && selectedLocation?.coordinate.longitude == 0 {
                selectedLat = CurrentUser.currentLocation?.coordinate.latitude
                selectedLong = CurrentUser.currentLocation?.coordinate.longitude
                print("Selected Post Location: Nil, Using Current User Position: \(self.selectedLat), \(self.selectedLong)")
            } else {
            selectedLat = selectedLocation?.coordinate.latitude
            selectedLong = selectedLocation?.coordinate.longitude
            }
            self.checkHasRestaurantLocation()
        }
    }
    
    var selectedLong: Double? = 0
    var selectedLat: Double? = 0
    var selectedName: String? {
        didSet {
            if selectedName != nil {
                self.locationNameLabel.text = selectedName!
            }}}
    var selectedAdress: String?

    // Filter Variables
    let defaultFilterRange = "25"
    
    var isFiltering: Bool = false
    var filterCaption: String? = nil
    var filterRange: String? = nil
    var filterLocation: CLLocation? = nil
    var filterLocationName: String? = nil
    var filterGoogleLocationID: String? = nil
    var filterMinRating: Double = 0
    var filterType: String? = nil
    var filterMaxPrice: String? = nil
    
    // Header Sort Variables
    var selectedHeaderSort = HeaderSortDefault {
        didSet {
        }
    }
    
    
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
    
    

    
    func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay) {
        mapView.delegate = self
        print("Tapped")
        self.activateMap()
    }
    
    func checkHasRestaurantLocation(){
        self.hasRestaurantLocation = true

        guard let googlePlaceId = googlePlaceId else {
            self.hasRestaurantLocation = false
            return
        }
        
        if googlePlaceId == "" {
            self.hasRestaurantLocation = false
        }
            
        if selectedAdress != nil && selectedName != nil {
           // If User uses Google to input adress, it will produce a GooglePlaceID, but won't be a location
            if (selectedName?.length)! > 1 && (selectedAdress?.length)! > 1 && selectedName == selectedAdress {
                self.hasRestaurantLocation = false
            }
        }

        print("Restaurant Location Check: \(self.hasRestaurantLocation) : \(googlePlaceId)")
    }
    
    
    
// Location Detail Items
    
    let locationDetailRowHeight: CGFloat = 30
    
    // Google Place Variables
    var placeName: String?
    var placeOpeningHours: [JSON]?
    var placePhoneNo: String?
    var placeWebsite: String?
    var placeGoogleRating: Double?
    var placeOpenNow: Bool?
    var placeGoogleMapUrl: String?
    var placeDetailStackview = UIStackView()
    
    // Location Name
    let locationNameView = UIView()
    lazy var locationNameLabel = PaddedUILabel()
    let locationNameIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "home").withRenderingMode(.alwaysOriginal), for: .normal)
        return button
    }()
    
    // Location Adress
    let locationAdressView = UIView()
    lazy var locationAdressLabel = PaddedUILabel()
    let locationAdressIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "GeoFence").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activateMap), for: .touchUpInside)
        return button
    }()

    // Location Hours
    let locationHoursView = UIView()
    lazy var locationHoursLabel = PaddedUILabel()
    let locationHoursIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "hours").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(locationHoursIconTapped), for: .touchUpInside)
        return button
    }()
    
    // Location Phone
    let locationPhoneView = UIView()
    lazy var locationPhoneLabel = PaddedUILabel()
    let locationPhoneIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "phone").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activatePhone), for: .touchUpInside)
        return button
    }()
    
    // Location Website
    let locationWebsiteView = UIView()
    lazy var locationWebsiteLabel = PaddedUILabel()
    let locationWebsiteIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "website").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activateBrowser), for: .touchUpInside)
        return button
    }()
    
    // Location Places Collection View
    lazy var placesCollectionView : UICollectionView = {
        let uploadLocationTagList = UploadLocationTagList()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: uploadLocationTagList)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UIColor(white: 0, alpha: 0.03)
        return cv
    }()

// Location Detail Functions
    func locationHoursIconTapped(){
        var timeString = "" as String
        for time in self.placeOpeningHours! {
            timeString = timeString + time.string! + "\n"
        }
        self.alert(title: "Opening Hours", message: timeString)
    }
    
    func activateMap() {
        if (UIApplication.shared.canOpenURL(NSURL(string:"https://www.google.com/maps/search/?api=1&query=\(selectedLat!),\(selectedLong!)")! as URL)) {
            UIApplication.shared.openURL(NSURL(string:
                "https://www.google.com/maps/search/?api=1&query=\(selectedLat!),\(selectedLong!)")! as URL)
        } else {
            NSLog("Can't use comgooglemaps://");
        }
    }
    
    func activatePhone(){
        guard let url = URL(string: "tel://\(self.placePhoneNo!)") else {return}
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    func activateBrowser(){
        guard let url = URL(string: self.placeWebsite!) else {return}

        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    
    
    
// Collection View Title
    
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
        cv.emptyDataSetSource = self
        cv.emptyDataSetDelegate = self
        return cv
    }()
    

    func didTapPicture(post: Post) {
        let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
        pictureController.selectedPost = post
        navigationController?.pushViewController(pictureController, animated: true)
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
            self.locationAdressLabel.attributedText = attributedString
        }
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupNavigationItems()
        if CurrentUser.currentLocation == nil {
            LocationSingleton.sharedInstance.determineCurrentLocation()
        }

    // Created a temp uiview and pinned all labels/map/pics onto temp uiview
    // Created scrollview and pinned temp uiview on top of scroll view
    // Added ScrollView onto view
        
        scrollView.frame = view.bounds
        scrollView.backgroundColor = UIColor.white
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.contentSize = CGSize(width: view.bounds.width, height: view.bounds.height * 2)
        self.view.addSubview(scrollView)

        scrollView.addSubview(tempView)
        tempView.anchor(top: scrollView.topAnchor, left: view.leftAnchor, bottom: scrollView.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
    // Place Details View
        tempView.addSubview(placeDetailsView)
        placeDetailsView.anchor(top: tempView.topAnchor, left: tempView.leftAnchor, bottom: nil, right: tempView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 4 * (locationDetailRowHeight + 2 + 2))
//
//    // CollectionView Title Header
//        tempView.addSubview(collectionViewTitleLabel)
//        collectionViewTitleLabel.anchor(top: placeDetailsView.bottomAnchor, left: tempView.leftAnchor, bottom: nil, right: tempView.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 20)
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor.white
        tempView.addSubview(bottomDividerView)
        bottomDividerView.anchor(top: placeDetailsView.bottomAnchor, left: tempView.leftAnchor, bottom: nil, right: tempView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
    // Photo CollectionView
        
        tempView.addSubview(photoCollectionView)
        photoCollectionView.anchor(top: bottomDividerView.bottomAnchor, left: tempView.leftAnchor, bottom: tempView.bottomAnchor, right: tempView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 500)
        photoCollectionView.register(GridPhotoCell.self, forCellWithReuseIdentifier: photoCellId)
        photoCollectionView.register(LastLocationPhotoCell.self, forCellWithReuseIdentifier: lastPhotoCellId)
        photoCollectionView.register(SortFilterHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: photoHeaderId)
        
        self.clearFilter()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if hasRestaurantLocation{
            print("Google Location: \(self.googlePlaceId)")
            setupPlaceDetailStackview()
            self.populatePlaceDetails(placeId: googlePlaceId)
            self.fetchPostForPostLocation(placeId: googlePlaceId!)
        } else {
            print("Google Location: No Location: (\(self.selectedLat), \(self.selectedLong))")
            setupNoLocationView()
            self.googleLocationSearch(GPSLocation: CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!))
            self.fetchPostWithLocation(location: CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!))
        }
    }
    
    func refreshAllPosts(){
        self.displayedPosts.removeAll()
        if hasRestaurantLocation{
            self.fetchPostForPostLocation(placeId: googlePlaceId!)
        } else {
            self.fetchPostWithLocation(location: CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Helps with Memory usage for Map View
        map?.clear()
        map?.stopRendering()
        map?.removeFromSuperview()
        map?.delegate = nil
        map = nil
    }
    
    func setupNoLocationView(){
        
    // Add Suggested Places CollectionView

        placesCollectionView.delegate = self
        placesCollectionView.dataSource = self
        placesCollectionView.showsHorizontalScrollIndicator = false
        
        tempView.addSubview(placesCollectionView)
        placesCollectionView.anchor(top: nil, left: placeDetailsView.leftAnchor, bottom: placeDetailsView.bottomAnchor, right: placeDetailsView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: locationDetailRowHeight)
        placesCollectionView.backgroundColor = UIColor.rgb(red: 128, green: 191, blue: 255)
        placesCollectionView.register(UploadLocationCell.self, forCellWithReuseIdentifier: locationCellId)
        
        // Dummy Header, Won't get shown
        placesCollectionView.register(SortFilterHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: photoHeaderId)

        
        
        setupLocationLabels(containerview: locationNameView, icon: locationNameIcon, label: locationNameLabel)
        tempView.addSubview(locationNameView)
        locationNameView.anchor(top: nil, left: placeDetailsView.leftAnchor, bottom: placesCollectionView.topAnchor, right: placeDetailsView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: locationDetailRowHeight)
        
        locationNameLabel.text = self.selectedName ?? ""
    
    // Add Map
        
        let camera = GMSCameraPosition.camera(withLatitude: self.selectedLat!, longitude: self.selectedLong!, zoom: 15)
        map = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        map?.mapType = .normal
        
        // Add Marker
        let position = CLLocationCoordinate2DMake(self.selectedLat!, self.selectedLong!)
        let marker = GMSMarker(position: position)
        marker.title = "Hello World"
        marker.isDraggable = false
        marker.appearAnimation = .pop
        marker.map = self.map
        marker.tracksViewChanges = false
        
        tempView.addSubview(map!)
        map?.anchor(top: placeDetailsView.topAnchor, left: placeDetailsView.leftAnchor, bottom: locationNameView.topAnchor, right: placeDetailsView.rightAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 0, paddingRight: 1, width: 0, height: 0)
        map?.delegate = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(activateMap))
        tapGesture.numberOfTapsRequired = 1

        map?.addGestureRecognizer(tapGesture)
        map?.isUserInteractionEnabled = true
        
        collectionViewTitleLabel.text = "Photos Around Location"
        
    }
    
    func setupPlaceDetailStackview(){
        
        setupLocationLabels(containerview: locationNameView, icon: locationNameIcon, label: locationNameLabel)
        setupLocationLabels(containerview: locationHoursView, icon: locationHoursIcon, label: locationHoursLabel)
        setupLocationLabels(containerview: locationPhoneView, icon: locationPhoneIcon, label: locationPhoneLabel)
        setupLocationLabels(containerview: locationAdressView, icon: locationAdressIcon, label: locationAdressLabel)
        
        // Add Gesture Recognizers
        locationAdressLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(activateMap)))
        locationHoursLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(locationHoursIconTapped)))
        locationPhoneLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(activatePhone)))
        
        placeDetailStackview = UIStackView(arrangedSubviews: [locationNameView, locationHoursView, locationAdressView, locationPhoneView])
        placeDetailStackview.distribution = .fillEqually
        placeDetailStackview.axis = .vertical
        
        tempView.addSubview(placeDetailStackview)
        placeDetailStackview.anchor(top: placeDetailsView.topAnchor, left: placeDetailsView.leftAnchor, bottom: placeDetailsView.bottomAnchor, right: placeDetailsView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    }
    
    func setupNavigationItems(){
        
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
    }

    
    var noIdView = UIView()
    
    
    func refreshMap(long: Double, lat: Double) -> (){
        self.map?.clear()
        
        let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: 16)
        print("refresh map", camera)
        self.map?.camera = camera
        
        let position = CLLocationCoordinate2DMake(lat, long)
        let marker = GMSMarker(position: position)
        print("Marker GPS, ", marker)
        marker.title = "Hello World"
        marker.isDraggable = false
        marker.appearAnimation = .pop
        marker.map = self.map
        marker.tracksViewChanges = false
    }
    
    
    func setupLocationLabels(containerview: UIView, icon: UIButton, label: UILabel){
        containerview.addSubview(icon)
        containerview.addSubview(label)
        containerview.backgroundColor = UIColor.rgb(red: 128, green: 191, blue: 255)
        
        //Icon Height Anchor determines row height
        icon.anchor(top: containerview.topAnchor, left: containerview.leftAnchor, bottom: containerview.bottomAnchor, right: nil, paddingTop: 2, paddingLeft: 15, paddingBottom: 2, paddingRight: 5, width: locationDetailRowHeight, height: locationDetailRowHeight)
        //        icon.widthAnchor.constraint(equalTo: locationNameIcon.heightAnchor, multiplier: 1)
        
        label.anchor(top: containerview.topAnchor, left: icon.rightAnchor, bottom: containerview.bottomAnchor, right: containerview.rightAnchor, paddingTop: 2, paddingLeft: 15, paddingBottom: 2, paddingRight: 15, width: 0, height: 0)
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 12)
        label.backgroundColor = UIColor(white: 1, alpha: 0.75)
        label.layer.borderWidth = 0.5
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.isUserInteractionEnabled = true
    }
    
    
    func searchNearby(){
        let locationController = LocationController()
        locationController.selectedLocation = self.selectedLocation
        locationController.selectedName = self.selectedAdress
        
        navigationController?.pushViewController(locationController, animated: true)
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
        
        let searchDistance = Double(self.filterRange!)!
        print("No Google Place ID. Searching Posts by Location: ", location)
        Database.fetchAllPostWithLocation(location: location, distance: searchDistance) { (fetchedPosts) in
            print("Fetched Post with Location: \(location) : \(fetchedPosts.count) Posts")
            self.displayedPosts = fetchedPosts
            self.filterSortFetchedPosts()
        }
    }
    
    func fetchPostWithGooglePlaceID(googlePlaceID: String){
        print("Searching Posts by Google Place ID: ", googlePlaceID)
        Database.fetchAllPostWithGooglePlaceID(googlePlaceId: googlePlaceID) { (fetchedPosts) in
            print("Fetching Post with googlePlaceId: \(googlePlaceID) : \(fetchedPosts.count) Posts")
            self.displayedPosts = fetchedPosts
            self.filterSortFetchedPosts()
        }
    }
    
    func filterSortFetchedPosts(){
        
        // Filter Posts
        // Not Filtering for Location and Range/Distances
        Database.filterPosts(inputPosts: self.displayedPosts, filterCaption: self.filterCaption, filterRange: nil, filterLocation: nil, filterMinRating: self.filterMinRating, filterType: self.filterType, filterMaxPrice: self.filterMaxPrice) { (filteredPosts) in
            
            // Sort Posts
            Database.sortPosts(inputPosts: filteredPosts, selectedSort: self.selectedHeaderSort, selectedLocation: self.filterLocation, completion: { (filteredPosts) in
                
                self.displayedPosts = []
                if filteredPosts != nil {
                    self.displayedPosts = filteredPosts!
                }
                print("Finish Filter and Sorting Post")
                self.photoCollectionView.reloadData()
            })
        }
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
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        Database.fetchPostWithPostID(postId: marker.title!) { (post, error) in
            
            guard let post = post else {return}
            
            let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
            pictureController.selectedPost = post
            self.navigationController?.pushViewController(pictureController, animated: true)
        
        }
        return true
    }
    
    // Sort Delegate
    
    func headerSortSelected(sort: String) {
        self.selectedHeaderSort = sort
        print("Filter Sort is ", self.selectedHeaderSort)
        self.refreshAllPosts()
    }
    
    // Search Delegate And Methods
    
    func openFilter(){
        let filterController = FilterController()
        filterController.delegate = self
        
        filterController.selectedCaption = self.filterCaption
        filterController.selectedRange = self.filterRange
        filterController.selectedMinRating = self.filterMinRating
        filterController.selectedMaxPrice = self.filterMaxPrice
        filterController.selectedType = self.filterType
        filterController.selectedLocation = self.selectedLocation
        filterController.selectedLocationName = self.selectedName
        
        filterController.selectedSort = self.selectedHeaderSort
        // Change filter controller for Location Controller
        filterController.sortOptionsInd = 1
        
        self.navigationController?.pushViewController(filterController, animated: true)
    }
    
    
    // Search Delegates
    
    
    func filterControllerFinished(selectedCaption: String?, selectedRange: String?, selectedLocation: CLLocation?, selectedLocationName: String?, selectedMinRating: Double, selectedType: String?, selectedMaxPrice: String?, selectedSort: String){
        
        // Clears all Filters, Puts in new Filters, Refreshes all Post IDS and Posts
        
        
        self.clearFilter()
        
        self.filterCaption = selectedCaption
        self.filterRange = selectedRange
        self.filterLocation = selectedLocation
        self.filterLocationName = selectedLocationName
        self.filterMinRating = selectedMinRating
        self.filterType = selectedType
        self.filterMaxPrice = selectedMaxPrice
        self.selectedHeaderSort = selectedSort
        
        // Check for filtering
        self.checkFilter()
        
        self.refreshAllPosts()
    }
    
    func clearFilter(){
        self.filterLocation = nil
        self.filterLocationName = nil
        self.filterRange = defaultFilterRange
        self.filterGoogleLocationID = nil
        self.filterMinRating = 0
        self.filterType = nil
        self.filterMaxPrice = nil
        self.selectedHeaderSort = defaultSort
        self.checkFilter()
    }
    
    func checkFilter(){
        if self.filterCaption != nil || (self.filterRange != nil) || (self.filterMinRating != 0) || (self.filterType != nil) || (self.filterMaxPrice != nil) {
            self.isFiltering = true
        } else {
            self.isFiltering = false
        }
    }

    
    
// Collection View Delegates
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == placesCollectionView{
            
            let locationController = LocationController()
            print(googlePlaceIDs[indexPath.row])
            locationController.googlePlaceId = googlePlaceIDs[indexPath.item]
            locationController.selectedName = googlePlaceNames[indexPath.item]
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
            if displayedPosts.count == 0 {
                return 0
            } else {
            return displayedPosts.count + 1
            }
        }
        if collectionView == placesCollectionView {
            return googlePlaceNames.count
        } else{
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == photoCollectionView {
            if indexPath.row == displayedPosts.count {
            // Add Last Photo Cell to enable search nearby
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: lastPhotoCellId, for: indexPath) as! LastLocationPhotoCell
                cell.delegate = self
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellId, for: indexPath) as! GridPhotoCell
                cell.delegate = self
                cell.post = displayedPosts[indexPath.item]
                return cell
            }
        } else if collectionView == placesCollectionView{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationCellId, for: indexPath) as! UploadLocationCell
            cell.uploadLocations.font = UIFont.systemFont(ofSize: 13)
            cell.uploadLocations.text = googlePlaceNames[indexPath.item]
//            cell.backgroundColor = UIColor(white: 0, alpha: 0.03)
            cell.backgroundColor = UIColor.white
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellId, for: indexPath) as! GridPhotoCell
            cell.delegate = self
            cell.post = displayedPosts[indexPath.item]
            return cell
        }
        
    }
    
    // SORT FILTER HEADER
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: photoHeaderId, for: indexPath) as! SortFilterHeader
            header.isFiltering = self.isFiltering
            header.delegate = self
            header.selectedSort = self.selectedHeaderSort
            // For Location Sort Ind
            header.sortOptionsInd = 1
            return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if collectionView == photoCollectionView {
            return CGSize(width: view.frame.width, height: 35 + 5)
        } else {
            return CGSize.zero
        }
    }
    

    // EMPTY DATA SET DELEGATES
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if let name = self.selectedName {
            text = "No Photos From \(self.selectedName!)"
        } else {
            text = "No Photos From Location"
        }

        font = UIFont.boldSystemFont(ofSize: 17.0)
        textColor = UIColor(hexColor: "25282b")
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: textColor])
        
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        text = nil

        font = UIFont.boldSystemFont(ofSize: 13.0)
        textColor = UIColor(hexColor: "7b8994")
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: textColor])
        
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -100
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return #imageLiteral(resourceName: "emptydataset")
    }
    
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        text = "Search Nearby"

        font = UIFont.boldSystemFont(ofSize: 14.0)
        textColor = UIColor(hexColor: "00aeef")
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: textColor])
        
    }
    
    func buttonBackgroundImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> UIImage? {
        
        var capInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        var rectInsets = UIEdgeInsets.zero
        
        capInsets = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)
        rectInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
        let image = #imageLiteral(resourceName: "emptydatasetbutton")
        return image.resizableImage(withCapInsets: capInsets, resizingMode: .stretch).withAlignmentRectInsets(rectInsets)
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return UIColor(hexColor: "fcfcfa")
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
       
        searchNearby()
        
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView) {
    }
    
    //    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
    //        let offset = (self.collectionView?.frame.height)! / 5
    //            return -50
    //    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return 0
    }

    
// Google Location Search Functions
    
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
            self.selectedName = self.placeName
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
            
            self.selectedLong = result["geometry"]["location"]["lng"].double ?? 0
            self.selectedLat = result["geometry"]["location"]["lat"].double ?? 0
            self.selectedLocation = CLLocation(latitude: self.selectedLat!, longitude: self.selectedLong!)
            
            self.selectedAdress = result["formatted_address"].string ?? ""
            self.locationAdressLabel.text = self.selectedAdress
            
            
        } else {
            print("Failed to extract Google Place Details")
        }
    }
    
    
    
    func googleLocationSearch(GPSLocation: CLLocation){
        
//        let dataProvider = GoogleDataProvider()
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
            
               //         print(response)
            
            if let value  = response.result.value {
                let json = JSON(value)
                
                if let results = json["results"].array {
                    print("Found Google Places Results: \(results.count)")
                    for result in results {
//                        print("Fetched Google Place Names Results: ",result)
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

