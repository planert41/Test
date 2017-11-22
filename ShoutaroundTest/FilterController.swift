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


protocol FilterControllerDelegate: class {
    func filterControllerFinished(selectedRange: String, selectedLocation: CLLocation?, selectedGooglePlaceID: String?, selectedTime: String, selectedGroup: String, selectedSort: String)
}

class FilterController: UIViewController, CLLocationManagerDelegate, GMSAutocompleteViewControllerDelegate {
    
    let optionRanges = geoFilterRangeDefault
    let optionGroups = ["Favs", "All"]
    let optionSort = FilterSortDefault
    let optionTime = FilterSortTimeDefault
    let locationManager = CLLocationManager()
    
    var selectedRange: String = defaultRange
    var selectedGroup: String = defaultGroup
    var selectedSort: String = defaultSort
    var selectedTime: String = defaultTime
    var currentTime: Int = 0
    
    
    
    weak var delegate: FilterControllerDelegate?

    var selectedGooglePlaceID: String? = nil
    var selectedLocation: CLLocation? = nil {
        didSet{
            if selectedLocation == CurrentUser.currentLocation {
                let attributedText = NSMutableAttributedString(string: "Current Location", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor.mainBlue()])
    
                self.currentLocationButton.isHidden = true
                locationNameLabel.attributedText = attributedText
            } else {
                self.currentLocationButton.isHidden = false
            }
        }
    }
    

    lazy var filterDistanceLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Filter Within (KM)"
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
        tv.backgroundColor = UIColor(white: 0, alpha: 0.03)
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
        button.backgroundColor = UIColor.mainBlue()
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
    
    var distanceSegment = UISegmentedControl()
    var groupSegment = UISegmentedControl()
    var sortSegment = UISegmentedControl()
    var timeSegment = UISegmentedControl()
    
    
    func findCurrentLocation() {
        
        self.selectedGooglePlaceID = nil
        self.selectedLocation = nil
        
        self.determineCurrentLocation()
        let when = DispatchTime.now() + 1 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.selectedLocation = CurrentUser.currentLocation
        }
    }
    
    static let updateFeedWithFilterNotificationName = NSNotification.Name(rawValue: "UpdateFeedWithFilter")
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.determineCurrentLocation()
        
        let scrollview = UIScrollView()
        
        scrollview.frame = view.bounds
        scrollview.backgroundColor = UIColor.white
        scrollview.isScrollEnabled = true
        scrollview.showsVerticalScrollIndicator = true
        scrollview.contentSize = CGSize(width: view.bounds.width, height: view.bounds.height * 1.25)
        
        view.addSubview(scrollview)
    
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(filterSelected))
        
        view.backgroundColor = UIColor.white
        
        distanceSegment = UISegmentedControl(items: optionRanges)
        distanceSegment.selectedSegmentIndex = optionRanges.index(of: self.selectedRange)!
        distanceSegment.addTarget(self, action: #selector(selectRange), for: .valueChanged)
        distanceSegment.tintColor = UIColor.orange
        
        timeSegment = UISegmentedControl(items: optionTime)
        timeSegment.selectedSegmentIndex = optionTime.index(of: self.selectedTime)!
        timeSegment.addTarget(self, action: #selector(selectTime), for: .valueChanged)
//        timeSegment.tintColor = UIColor.orange
        
        groupSegment = UISegmentedControl(items: optionGroups)
        groupSegment.selectedSegmentIndex = optionGroups.index(of: self.selectedGroup)!
        groupSegment.addTarget(self, action: #selector(selectGroup), for: .valueChanged)

        sortSegment = UISegmentedControl(items: optionSort)
        sortSegment.selectedSegmentIndex = optionSort.index(of: self.selectedSort)!
        sortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        
        
        
        scrollview.addSubview(filterDistanceLabel)
        scrollview.addSubview(distanceSegment)
        
        filterDistanceLabel.anchor(top: scrollview.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 30)
        
        distanceSegment.anchor(top: filterDistanceLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 50)
        
        scrollview.addSubview(locationLabel)
        scrollview.addSubview(locationNameLabel)
        scrollview.addSubview(currentLocationButton)
        
        locationNameLabel.isUserInteractionEnabled = true
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(tapSearchBar))
        locationNameLabel.addGestureRecognizer(TapGesture)
        
        locationLabel.anchor(top: distanceSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 15, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 30)
        locationNameLabel.anchor(top: locationLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 50)
        
        currentLocationButton.anchor(top: locationNameLabel.topAnchor, left: nil, bottom: locationNameLabel.bottomAnchor, right: locationNameLabel.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        currentLocationButton.widthAnchor.constraint(equalTo: currentLocationButton.heightAnchor, multiplier: 1).isActive = true
        currentLocationButton.isHidden = true
        
        
        scrollview.addSubview(filterTimeLabel)
        scrollview.addSubview(timeSegment)
        
        filterTimeLabel.anchor(top: locationNameLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 15, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 30)
        timeSegment.anchor(top: filterTimeLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 40)
        
        
        let date = Date() // save date, so all components use the same date
        let calendar = Calendar.current // or e.g. Calendar(identifier: .persian)
        let hour = calendar.component(.hour, from: date)
        print(hour)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // "a" prints "pm" or "am"
        let hourString = formatter.string(from: Date()) // "12 AM"
        
        let filterTimeAttributedText = NSMutableAttributedString(string: "Sort By Time", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor.black])

        filterTimeAttributedText.append(NSMutableAttributedString(string: "   ⏰ \(hourString) ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor.mainBlue()]))
        filterTimeLabel.attributedText = filterTimeAttributedText
        
// Remove Group Filter For now
        
//        view.addSubview(filterGroupLabel)
//        view.addSubview(groupSegment)
//        
//        filterGroupLabel.anchor(top: timeSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 15, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 30)
//        groupSegment.anchor(top: filterGroupLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 40)
        
        scrollview.addSubview(sortByLabel)
        scrollview.addSubview(sortSegment)
        
        sortByLabel.anchor(top: timeSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 15, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 30)
        sortSegment.anchor(top: sortByLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 40)

        scrollview.addSubview(filterButton)
        filterButton.anchor(top: sortSegment.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 15, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 40)
        
        scrollview.addSubview(clearFilterButton)
        clearFilterButton.anchor(top: filterButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 40)
        

        
        
        // Morning 6-12, MidDay 12 - 6, Late, 6 - 6
        
        if hour > 5 && hour <= 12 {
            self.currentTime = 0
        } else if hour > 12 && hour <= 18 {
            self.currentTime = 1
        } else {
            self.currentTime = 2
        }
        
        
    }
    
    func selectRange(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0...optionRanges.count - 2:
            
            // Non-Zero search range is selected
            
            self.selectedRange = optionRanges[sender.selectedSegmentIndex]
            self.sortSegment.selectedSegmentIndex = 0
            self.selectedSort = optionSort[self.sortSegment.selectedSegmentIndex]

            
        case optionRanges.count - 1:
            self.selectedRange = optionRanges[sender.selectedSegmentIndex]
            self.sortSegment.selectedSegmentIndex = 2
            self.selectedSort = optionSort[self.sortSegment.selectedSegmentIndex]
            
        default:
            self.selectedRange = optionRanges[optionRanges.endIndex-1]
            
        }
        print("Selected Range is ",self.selectedRange)
    }
    
    func selectGroup(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0...optionGroups.count:
            self.selectedGroup = optionGroups[sender.selectedSegmentIndex]
        default:
            self.selectedGroup = optionGroups[optionGroups.endIndex-1]
            
        }
        print("Selected Group is ",self.selectedGroup)
    }
    
    func selectTime(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0...optionTime.count:
            self.selectedTime = optionTime[sender.selectedSegmentIndex]
        default:
            self.selectedTime = optionTime[optionTime.endIndex-1]
            
        }
        print("Selected Time is ",self.selectedTime)
    }
    
    func selectSort(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.selectedSort = optionSort[sender.selectedSegmentIndex]
            if self.selectedRange == optionRanges[optionRanges.endIndex - 1]
            {
                self.selectedRange = optionRanges[0]
                self.distanceSegment.selectedSegmentIndex = 0
                print(self.distanceSegment.selectedSegmentIndex)
            }
        case 1...optionSort.count - 2:
            self.selectedSort = optionSort[sender.selectedSegmentIndex]
        default:
            self.selectedSort = optionSort[0]
            
        }
        print("Selected Sort is ",self.selectedGroup)
    }
    
    func filterSelected(){
        delegate?.filterControllerFinished(selectedRange: self.selectedRange, selectedLocation: self.selectedLocation, selectedGooglePlaceID: self.selectedGooglePlaceID, selectedTime: self.selectedTime, selectedGroup: self.selectedGroup, selectedSort: self.selectedSort)
    //    NotificationCenter.default.post(name: FilterController.updateFeedWithFilterNotificationName, object: nil)
        print("Filter By ",self.selectedRange,self.selectedLocation, self.selectedGooglePlaceID, self.selectedGroup, self.selectedSort)
        self.navigationController?.popViewController(animated: true)

    }
    
    func refreshFilter(){
        self.distanceSegment.selectedSegmentIndex = optionRanges.endIndex-1
        self.selectedRange = optionRanges[optionRanges.endIndex-1]
        
        self.timeSegment.selectedSegmentIndex = optionTime.endIndex-1
        self.selectedTime = optionTime[optionTime.endIndex-1]
        
        self.groupSegment.selectedSegmentIndex = optionGroups.endIndex-1
        self.selectedGroup = optionGroups[optionGroups.endIndex-1]
        
        self.sortSegment.selectedSegmentIndex = optionSort.endIndex - 1
        self.selectedSort = optionSort[optionSort.endIndex-1]
        
        self.selectedLocation = CurrentUser.currentLocation
        
        
    }
    
    // Google Search Location Delegates
    
    
    func tapSearchBar() {
        print("Search Bar Tapped")
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        print(place)
        selectedLocation = CLLocation.init(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        selectedGooglePlaceID = place.placeID
        locationNameLabel.text = place.name
        dismiss(animated: true, completion: nil)
        
    }
    
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print(error)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // LOCATION MANAGER DELEGATE METHODS
    
    func determineCurrentLocation(){
        
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
            selectedLocation = userLocation
            manager.stopUpdatingLocation()
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("GPS Location Not Found")
    }
    
    
}
