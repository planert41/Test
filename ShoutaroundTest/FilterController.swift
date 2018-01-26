//
//  FilterController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/28/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import GooglePlaces
import Cosmos


protocol FilterControllerDelegate: class {
    func filterControllerFinished(selectedCaption: String?, selectedRange: String?, selectedLocation: CLLocation?, selectedLocationName: String?, selectedGooglePlaceId: String?, selectedGooglePlaceType: [String]?, selectedMinRating: Double, selectedType: String?, selectedMaxPrice: String?, selectedSort: String)
}

class FilterController: UIViewController, GMSAutocompleteViewControllerDelegate, PostSearchControllerDelegate, UISearchBarDelegate {

    let locationManager = CLLocationManager()
    
    var selectedCaption: String? = nil {
        didSet{
            self.filterCaptionSearchBar.text = selectedCaption
        }
    }
    
    var selectedRange: String? = nil {
        didSet{
            guard let selectedRange = selectedRange else {return}
            if let index = geoFilterRangeDefault.index(of: selectedRange){
                self.distanceSegment.selectedSegmentIndex = index
            } else {
                 self.distanceSegment.selectedSegmentIndex = UISegmentedControlNoSegment
            }
        }
    }
    var selectedMinRating: Double = 0 {
        didSet {
            if selectedMinRating > 0 {
                starRating.rating = selectedMinRating
            }
        }
    }
    var selectedType: String? = nil {
        didSet{
            guard let selectedType = selectedType else {return}
            if let index = UploadPostTypeDefault.index(of: selectedType){
                self.typeSegment.selectedSegmentIndex = index
            }
        }
    }
    var selectedMaxPrice: String? = nil {
        didSet{
            guard let selectedMaxPrice = selectedMaxPrice else {return}
            if let index = UploadPostPriceDefault.index(of: selectedMaxPrice){
                self.priceSegment.selectedSegmentIndex = index
            }
        }
    }
    
    // 0 For Default Header Sort Options, 1 for Location Sort Options
    var sortOptionsInd: Int = 0 {
        didSet{
            self.updateForSortOptionsInd()
        }
    }
    var filterSortOptions: [String] = HeaderSortOptions

    
    
    var selectedSort: String = defaultSort {
        didSet{
            if let index = filterSortOptions.index(of: selectedSort){
                self.sortSegment.selectedSegmentIndex = index
            }
        }
    }

    let segmentHeight: CGFloat = 35
    
    weak var delegate: FilterControllerDelegate?

    var selectedGooglePlaceID: String? = nil
    var selectedGooglePlaceType: [String]? = nil
    var selectedLocation: CLLocation? = nil {
        didSet{
            if selectedLocation == CurrentUser.currentLocation {
                let attributedText = NSMutableAttributedString(string: "Current Location", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor.legitColor()])
                locationNameLabel.attributedText = attributedText

                self.currentLocationButton.isHidden = true
            } else {
                self.currentLocationButton.isHidden = false
            }
        }
    }
    var selectedLocationName: String? = nil {
        didSet{
            if selectedLocationName != nil {
                locationNameLabel.text = selectedLocationName
            }
        }
    }
    
    lazy var filterCaptionLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Search Posts For"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    lazy var filterCaptionSearchBar = UISearchBar()
    
    lazy var filterDistanceLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Distance Within (Mi)"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    lazy var locationLabel: UILabel = {
        let ul = UILabel()
        ul.text = "From Location"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    let locationNameLabel: UILabel = {
        let tv = LocationLabel()
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.backgroundColor = UIColor(white: 0, alpha: 0.05)
        tv.layer.borderColor = UIColor(white: 0, alpha: 0.15).cgColor
        tv.layer.borderWidth = 0.5
        tv.layer.cornerRadius = 5
        return tv
    }()

    
    lazy var filterGroupLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Posts From"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    lazy var sortByLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Sort By (First)"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    lazy var filterTimeLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Sort By Time"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    lazy var filterRatingLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Min Rating"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    lazy var filterPriceLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Max Price"
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    lazy var currentLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.black, for: .normal)
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 3
        button.setImage(#imageLiteral(resourceName: "GeoFence").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(findCurrentLocation), for: .touchUpInside)
        return button
    }()
    
    var filterButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.legitColor()
        button.setTitle("Filter", for: .normal)
        button.titleLabel?.textAlignment = NSTextAlignment.center
        button.addTarget(self, action: #selector(filterSelected), for: .touchUpInside)
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 0.5
        button.layer.cornerRadius = 3
        
        return button
    }()
    
    var clearFilterButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.orange
        button.setTitle("Clear Filter", for: .normal)
        button.titleLabel?.textAlignment = NSTextAlignment.center
        button.addTarget(self, action: #selector(refreshFilter), for: .touchUpInside)
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 0.5
        button.layer.cornerRadius = 3
        
        return button
    }()
    
    let starRating: CosmosView = {
        let iv = CosmosView()
        iv.settings.fillMode = .half
        iv.settings.totalStars = 7
        iv.settings.starSize = 30
        iv.settings.filledImage = #imageLiteral(resourceName: "ratingstarfilled").withRenderingMode(.alwaysOriginal)
        iv.settings.emptyImage = #imageLiteral(resourceName: "ratingstarunfilled").withRenderingMode(.alwaysOriginal)
        iv.rating = 0
        iv.settings.starMargin = 10
        return iv
    }()
    
    var distanceSegment:ReselectableSegmentedControl = {
        var segment = ReselectableSegmentedControl(items: geoFilterRangeDefault)
        segment.addTarget(self, action: #selector(handleSelectRange), for: .valueChanged)
        segment.tintColor = UIColor.rgb(red: 223, green: 85, blue: 78)
        segment.selectedSegmentIndex = UISegmentedControlNoSegment
        return segment
    }()
    
    func handleSelectRange(sender: UISegmentedControl) {
        if (geoFilterRangeDefault[sender.selectedSegmentIndex] == self.selectedRange) {
            sender.selectedSegmentIndex =  UISegmentedControlNoSegment
            self.selectedRange = nil
        }
        else {
            self.selectedRange = geoFilterRangeDefault[sender.selectedSegmentIndex]
        }
        print("Selected Range is ",self.selectedRange)
    }
    
    var typeSegment:ReselectableSegmentedControl = {
        var segment = ReselectableSegmentedControl(items: UploadPostTypeDefault)
        segment.addTarget(self, action: #selector(handleSelectType), for: .valueChanged)
        segment.tintColor = UIColor.rgb(red: 223, green: 85, blue: 78)
        segment.selectedSegmentIndex = UISegmentedControlNoSegment
        return segment
    }()

    func handleSelectType(sender: UISegmentedControl) {
        if (UploadPostTypeDefault[sender.selectedSegmentIndex] == self.selectedType) {
            sender.selectedSegmentIndex =  UISegmentedControlNoSegment
            self.selectedType = nil
        }
        else {
            self.selectedType = UploadPostTypeDefault[sender.selectedSegmentIndex]
        }
        print("Selected Type is ",self.selectedType)
    }
    
    
    var priceSegment:ReselectableSegmentedControl = {
        var segment = ReselectableSegmentedControl(items: UploadPostPriceDefault)
        segment.addTarget(self, action: #selector(handleSelectPrice), for: .valueChanged)
        segment.tintColor = UIColor.rgb(red: 223, green: 85, blue: 78)
        segment.selectedSegmentIndex = UISegmentedControlNoSegment
        return segment
    }()
    
    func handleSelectPrice(sender: UISegmentedControl) {
        if (UploadPostPriceDefault[sender.selectedSegmentIndex] == self.selectedMaxPrice) {
            sender.selectedSegmentIndex =  UISegmentedControlNoSegment
            self.selectedMaxPrice = nil
        }
        else {
            self.selectedMaxPrice = UploadPostPriceDefault[sender.selectedSegmentIndex]
        }
        print("Selected Max Price is ",self.selectedMaxPrice)
    }
    
    var sortSegment: UISegmentedControl = {
        var segment = UISegmentedControl(items: HeaderSortOptions)
        segment.addTarget(self, action: #selector(handleSelectSort), for: .valueChanged)
        segment.tintColor = UIColor.rgb(red: 223, green: 85, blue: 78)
        segment.selectedSegmentIndex = 0
        return segment
    }()
    
    func handleSelectSort(sender: UISegmentedControl) {
        self.selectedSort = filterSortOptions[sender.selectedSegmentIndex]
        print("Selected Sort is ",self.selectedSort)
    }
    
    func findCurrentLocation() {
        
        self.selectedGooglePlaceID = nil
        self.selectedLocation = nil
        
        LocationSingleton.sharedInstance.determineCurrentLocation()
        let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.selectedLocation = CurrentUser.currentLocation
        }
    }
    
    let selectionMargin: CGFloat = 10
    
    static let updateFeedWithFilterNotificationName = NSNotification.Name(rawValue: "UpdateFeedWithFilter")
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if self.selectedLocation == nil {
            let attributedText = NSMutableAttributedString(string: "Current Location", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor.legitColor()])
            locationNameLabel.attributedText = attributedText
            
            self.findCurrentLocation()
        }

        let scrollview = UIScrollView()
       
        scrollview.frame = view.bounds
        scrollview.backgroundColor = UIColor.white
        scrollview.isScrollEnabled = true
        scrollview.showsVerticalScrollIndicator = true
        scrollview.contentSize = CGSize(width: view.bounds.width, height: view.bounds.height * 1.25)
        view.addSubview(scrollview)
    
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(filterSelected))
        
        view.backgroundColor = UIColor.white
        
    // 0. Filter Post By Caption
        
        
        filterCaptionSearchBar.delegate = self
        filterCaptionSearchBar.placeholder = "Filter Posts For"
        filterCaptionSearchBar.searchBarStyle = .prominent
        filterCaptionSearchBar.barTintColor = UIColor.legitColor()
        
        // Add Border Color to Search Bar
        for s in filterCaptionSearchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.legitColor().cgColor
                s.layer.cornerRadius = 5
            }
        }
        
        scrollview.addSubview(filterCaptionSearchBar)
        filterCaptionSearchBar.anchor(top: scrollview.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: segmentHeight+20)

        
        
// 1. Filter By Location + Distance
        scrollview.addSubview(filterDistanceLabel)
        
        filterDistanceLabel.anchor(top: filterCaptionSearchBar.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: selectionMargin, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 25)
        
        scrollview.addSubview(locationNameLabel)
        scrollview.addSubview(currentLocationButton)
        
        locationNameLabel.isUserInteractionEnabled = true
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(tapSearchBar))
        locationNameLabel.addGestureRecognizer(TapGesture)
        locationNameLabel.isUserInteractionEnabled = false
        
        locationNameLabel.anchor(top: filterDistanceLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 2, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: segmentHeight)
        
        currentLocationButton.anchor(top: locationNameLabel.topAnchor, left: nil, bottom: locationNameLabel.bottomAnchor, right: locationNameLabel.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        currentLocationButton.widthAnchor.constraint(equalTo: currentLocationButton.heightAnchor, multiplier: 1).isActive = true
        currentLocationButton.isHidden = true
        
        scrollview.addSubview(distanceSegment)
        distanceSegment.anchor(top: locationNameLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: segmentHeight)

        
        
    // 3. Select Min Rating
        scrollview.addSubview(filterRatingLabel)
        scrollview.addSubview(starRating)
        filterRatingLabel.anchor(top: distanceSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: selectionMargin, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 25)
        starRating.anchor(top: filterRatingLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: segmentHeight)
        starRating.didFinishTouchingCosmos = starRatingSelectFunction

    // 4. Select Price Filter
        scrollview.addSubview(filterPriceLabel)
        scrollview.addSubview(priceSegment)
        
        filterPriceLabel.anchor(top: starRating.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: selectionMargin, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 25)
        priceSegment.anchor(top: filterPriceLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: segmentHeight)
        filterPriceLabel.text = "Max Price"
        
    // 5. Select Post Type (Breakfast, Lunch, Dinner, Snack)
//        scrollview.addSubview(filterTimeLabel)
        scrollview.addSubview(typeSegment)
//        filterTimeLabel.anchor(top: filterPriceLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: selectionMargin, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 25)
        typeSegment.anchor(top: priceSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: selectionMargin, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: segmentHeight)
        
    // 6. Sort Filter
//        scrollview.addSubview(sortByLabel)
        scrollview.addSubview(sortSegment)
        
//        sortByLabel.anchor(top: priceSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: selectionMargin, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 30)
        sortSegment.anchor(top: typeSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: selectionMargin, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: segmentHeight)

    // 7. Sort button
        scrollview.addSubview(filterButton)
        filterButton.anchor(top: sortSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 40)
        
        scrollview.addSubview(clearFilterButton)
        clearFilterButton.anchor(top: filterButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 40)
        
        let date = Date() // save date, so all components use the same date
        let calendar = Calendar.current // or e.g. Calendar(identifier: .persian)
        let hour = calendar.component(.hour, from: date)
        print(hour)
        
        // Don't Set Type Filter For Now
        
//        // Morning 6-11, MidDay 11 - 5, Late, 5 - 6
//        if hour > 5 && hour <= 11 {
//            self.selectedType = UploadPostTypeDefault[0]
//            self.typeSegment.selectedSegmentIndex = 0
//        } else if hour > 11 && hour <= 17 {
//            self.selectedType = UploadPostTypeDefault[1]
//            self.typeSegment.selectedSegmentIndex = 1
//        } else {
//            self.selectedType = UploadPostTypeDefault[2]
//            self.typeSegment.selectedSegmentIndex = 2
//        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // "a" prints "pm" or "am"
        let hourString = formatter.string(from: Date()) // "12 AM"
        
        let filterTimeAttributedText = NSMutableAttributedString(string: "Sort By Time", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor.black])
        
        filterTimeAttributedText.append(NSMutableAttributedString(string: "   ⏰ \(hourString) ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor.mainBlue()]))
        filterTimeLabel.attributedText = filterTimeAttributedText
        
    }
    
    
//    override func viewWillDisappear(_ animated: Bool) {
//        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        navigationController?.navigationBar.barTintColor = UIColor.white
//    }
    
    func starRatingSelectFunction(rating: Double) {
        if rating < 2 {
            self.selectedMinRating = 0
            self.starRating.rating = 0
        } else {
            self.selectedMinRating = rating
        }
        print("Selected Rating: \(self.selectedMinRating)")
    }
    

    func updateForSortOptionsInd(){
        
        if sortOptionsInd == 1 {
            self.locationNameLabel.isUserInteractionEnabled = false
            filterSortOptions = LocationSortOptions
        } else {
            self.locationNameLabel.isUserInteractionEnabled = true
            filterSortOptions = HeaderSortOptions
        }
        
        for i in 0..<sortSegment.numberOfSegments {
            if sortSegment.titleForSegment(at: i) != filterSortOptions[i] {
                //Update Segment Label
                sortSegment.setTitle(filterSortOptions[i], forSegmentAt: i)
            }
        }
    }
    
    func filterSelected(){
        
        delegate?.filterControllerFinished(selectedCaption: self.selectedCaption, selectedRange: self.selectedRange, selectedLocation: self.selectedLocation, selectedLocationName: self.locationNameLabel.text, selectedGooglePlaceId: self.selectedGooglePlaceID, selectedGooglePlaceType: self.selectedGooglePlaceType, selectedMinRating: self.selectedMinRating, selectedType: self.selectedType, selectedMaxPrice: self.selectedMaxPrice, selectedSort: self.selectedSort)

        print("Filter By ",self.selectedRange,self.selectedLocation, self.locationNameLabel.text, self.selectedMinRating, self.selectedType, self.selectedMaxPrice,  self.selectedSort)

        self.navigationController?.popViewController(animated: true)

    }
    
    func refreshFilter(){
        self.distanceSegment.selectedSegmentIndex = UISegmentedControlNoSegment
        self.selectedRange = nil
        
        self.selectedLocation = CurrentUser.currentLocation
        
        self.selectedMinRating = 0
        self.starRating.rating = 0
        
        self.typeSegment.selectedSegmentIndex = UISegmentedControlNoSegment
        self.selectedType = nil
        
        self.priceSegment.selectedSegmentIndex = UISegmentedControlNoSegment
        self.selectedMaxPrice = nil
        
        self.sortSegment.selectedSegmentIndex = 0
        self.selectedSort = defaultSort
        
    }
    
    // Search Bar Delegates
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.openSearch()
        return false
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        if (searchText.length == 0) {
//            self.filterCaption = nil
//            self.refreshPostsForFilter()
//            searchBar.endEditing(true)
//        }
    }
    
    func openSearch(){
        
        let postSearch = PostSearchController()
        postSearch.delegate = self
        self.navigationController?.pushViewController(postSearch, animated: true)
    }
    
    // Home Post Search Delegates
    
    func filterCaptionSelected(searchedText: String?){
        
        self.selectedCaption = searchedText
        
//        if searchedText == nil {
//            self.handleRefresh()
//
//        } else {
//            print("Searching for \(searchedText)")
//            defaultSearchBar.text = searchedText!
//            self.filterCaption = searchedText
//            self.refreshPagination()
//            self.collectionView?.reloadData()
//            self.scrolltoFirst = true
//            self.fetchAllPosts()
//        }
    }
    
    func userSelected(uid: String?){
//        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
//        userProfileController.userId = uid
//        self.navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    
    
    func locationSelected(googlePlaceId: String?, googlePlaceName: String?, googlePlaceLocation: CLLocation?, googlePlaceType: [String]?) {
        self.selectedLocation = googlePlaceLocation
        self.selectedGooglePlaceID = googlePlaceId
        self.selectedGooglePlaceType = googlePlaceType
        self.selectedLocationName = googlePlaceName
        
        var defaultRange: String? = nil
        if (self.selectedGooglePlaceType?.contains("locality"))! {
            // Selected City, So range is 25 Miles
            defaultRange = "25"
        } else if (self.selectedGooglePlaceType?.contains("neighbourhood"))! {
            // Selected City, So range is 25 Miles
            defaultRange = "5"
        } else if (self.selectedGooglePlaceType?.contains("establishment"))! {
            defaultRange = nil
        } else {
            defaultRange = "5"
        }
        if self.selectedRange == nil {
            self.selectedRange = defaultRange
        }
        
    }
    
    
    // Google Search Location Delegates
    
    
    func tapSearchBar() {
        print("Search Bar Tapped")
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        self.selectedLocation = CLLocation.init(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        self.selectedGooglePlaceID = place.placeID
        self.selectedGooglePlaceType = place.types
        self.selectedLocationName = place.name
        
        // Auto Select Closest Distance (5 KM)
        self.distanceSegment.selectedSegmentIndex = 1
        self.selectedRange = geoFilterRangeDefault[1]
        
        self.sortSegment.selectedSegmentIndex = 0
        self.selectedSort = defaultSort
        
        var defaultRange: String? = nil
        if (self.selectedGooglePlaceType?.contains("locality"))! {
            // Selected City, So range is 25 Miles
            defaultRange = "25"
        } else if (self.selectedGooglePlaceType?.contains("neighbourhood"))! {
            // Selected City, So range is 25 Miles
            defaultRange = "5"
        } else if (self.selectedGooglePlaceType?.contains("establishment"))! {
            defaultRange = nil
        }  else {
            defaultRange = "5"
        }
        if self.selectedRange == nil {
            self.selectedRange = defaultRange
        }
        
        print("Selected Google Location: \(place.name), \(place.placeID), \(selectedLocation)")
        dismiss(animated: true, completion: nil)
        
    }
    
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print(error)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
}
