//
//  SearchLocation.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/8/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import Alamofire
import SwiftyJSON
import GooglePlaces


protocol LocationSearchControllerDelegate {
    func didUpdate(lat: Double?, long: Double?, locationAdress: String?, locationName: String?, locationGooglePlaceID: String?)
    
}


class LocationSearchController: UIViewController, UITextFieldDelegate, GMSMapViewDelegate, GMSAutocompleteViewControllerDelegate{

    let locationManager = CLLocationManager()
    
    
    var delegate: LocationSearchControllerDelegate?
    
    var selectedLong: Double?
    var selectedLat: Double?
    var selectedGooglePlaceID: String?

    var selectedLocation: CLLocation?
        //= CLLocation(latitude: 41.9735039, longitude: -87.66775139999999)
        {
        
        didSet{
            
            selectedLong = selectedLocation?.coordinate.longitude
            selectedLat = selectedLocation?.coordinate.latitude
            //            refreshMap(long: (selectedLocation?.coordinate.longitude)!, lat: (selectedLocation?.coordinate.latitude)!)
            
        }
    }
    
        var marker = GMSMarker()
        
        
        var resultsViewController: GMSAutocompleteResultsViewController?
        
        
    lazy var map: GMSMapView = {
        let mp = GMSMapView()
        mp.mapType = .normal
        return mp
    }()
    
    var mapView: UIView = {
        let view = UIView()
        return view
    }()
    
    var searchBarView: UIButton = {
        let view = UIButton()
        view.backgroundColor = UIColor.init(white: 0, alpha: 0.3)
        view.setTitle("Search Location With Google", for: .normal)
        view.titleLabel?.textAlignment = NSTextAlignment.center
        return view
    }()
    
    let latInput: PaddedTextField = {
        let tv = PaddedTextField()
        tv.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        tv.backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        tv.tag = 0
        return tv
    }()
    
    let longInput: PaddedTextField = {
        let tv = PaddedTextField()
        tv.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        tv.backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        tv.tag = 1
        return tv
    }()
    
    lazy var locationAdressLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Adress: "
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    let locationAdress: PaddedTextField = {
        let tv = PaddedTextField()
        tv.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        tv.backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        tv.tag = 2
        return tv
    }()
    
    lazy var locationNameLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Name: "
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    
    let locationName: PaddedTextField = {
        let tv = PaddedTextField()
        tv.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        tv.backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        tv.tag = 3
        
        return tv
    }()
    
    lazy var findLocation: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.black, for: .normal)
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 3
        button.setImage(#imageLiteral(resourceName: "marker").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(findCurrentLocation), for: .touchUpInside)
        return button
    }()
    
    func findCurrentLocation() {
        LocationSingleton.sharedInstance.determineCurrentLocation()

        let when = DispatchTime.now() + 1 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
        self.selectedLocation = CurrentUser.currentLocation
        self.refreshMap(long: self.selectedLong!, lat: self.selectedLat!, name: nil, adress: nil)
            }
        }
    
    
    
    lazy var latLabel: UILabel = {
        let ul = UILabel()
        ul.text = "LAT: "
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    lazy var longLabel: UILabel = {
        let ul = UILabel()
        ul.text = "LONG: "
        ul.font = UIFont.boldSystemFont(ofSize: 14.0)
        return ul
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(selectLocation))
        
        view.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        view.addSubview(mapView)
        mapView.anchor(top: topLayoutGuide.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 0, paddingRight: 1, width: 0, height: 0)
        mapView.heightAnchor.constraint(equalTo: mapView.widthAnchor, multiplier: 1).isActive = true
        
        
        
        view.addSubview(map)
        map.anchor(top: mapView.topAnchor, left: mapView.leftAnchor, bottom: mapView.bottomAnchor, right: mapView.rightAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 1, paddingRight: 1, width: 0, height: 0)
        map.delegate = self
        map.isMyLocationEnabled = true
        
        view.addSubview(findLocation)
        findLocation.anchor(top: map.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 30, height: 30)
        
        
        
        
        let stackView = UIStackView(arrangedSubviews: [latLabel, latInput, longLabel, longInput])
        
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.spacing = 10
        
        
        
        view.addSubview(stackView)
        stackView.anchor(top: mapView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: findLocation.leftAnchor, paddingTop: 20, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 30)
        
        view.addSubview(locationAdress)
        view.addSubview(locationName)
        view.addSubview(locationAdressLabel)
        view.addSubview(locationNameLabel)
        
        locationAdressLabel.anchor(top: stackView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 60, height: 30)
        
        locationAdress.anchor(top: stackView.bottomAnchor, left: locationAdressLabel.rightAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 25, paddingBottom: 0, paddingRight: 25, width: 0, height: 30)
        
        
        locationNameLabel.anchor(top: locationAdress.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 60, height: 30)
        
        locationName.anchor(top: locationAdress.bottomAnchor, left: locationNameLabel.rightAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 25, paddingBottom: 0, paddingRight: 25, width: 0, height: 30)
        
        
        latInput.delegate = self
        longInput.delegate = self
        
        
        selectedLong = selectedLocation?.coordinate.longitude ?? 0
        selectedLat = selectedLocation?.coordinate.latitude ?? 0
        
        refreshMap(long: selectedLong!, lat: selectedLat!, name: nil, adress: nil)
        
        let searchBar = UISearchBar()
        searchBar.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        searchBar.text = "Search Location With Google"
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapSearchBar))
        searchBarView.addGestureRecognizer(tapGesture)
        
        view.addSubview(searchBarView)
        searchBarView.anchor(top: locationName.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 30)
        
    
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func selectLocation(){
        
        self.delegate?.didUpdate(lat: Double(latInput.text!), long: Double(longInput.text!), locationAdress: locationAdress.text, locationName: locationName.text, locationGooglePlaceID: selectedGooglePlaceID)

        let n: Int! = self.navigationController?.viewControllers.count
        self.navigationController?.popToViewController((self.navigationController?.viewControllers[n-2])!, animated: true)
        

       // self.dismiss(animated: true, completion: nil)
    }
    
    func tapSearchBar() {
        print("Search Bar Tapped")
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    func refreshMap(long: Double, lat: Double, name: String?, adress: String?) -> (){
        
        self.map.clear()
        self.selectedGooglePlaceID = nil
        
        let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: 15)
        print("refresh map", camera)
        self.map.camera = camera
        
        let position = CLLocationCoordinate2DMake(lat, long)
        let marker = GMSMarker(position: position)
        print("MArker GPS, ", marker)
        marker.title = "Hello World"
        marker.isDraggable = true
        marker.appearAnimation = .pop
        
        marker.map = self.map
        
        latInput.text = String(format:"%.4f", lat)
        longInput.text = String(format:"%.4f", long)
        
        if adress != nil {
            self.locationAdress.text = adress
        }
        
        if name != nil {
            self.locationName.text = name
        }
        
    }
    
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        selectedLocation = CLLocation.init(latitude: marker.position.latitude, longitude: marker.position.longitude)
        
        
        refreshMap(long: selectedLong!, lat: selectedLat!, name: nil, adress: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print(latInput.text, longInput.text)
        
        guard let latTemp = Double(latInput.text!) else {return false}
        guard let longTemp = Double(longInput.text!) else {return false}
        
        selectedLocation = CLLocation.init(latitude: latTemp, longitude: longTemp)
        refreshMap(long: selectedLong!, lat: selectedLat!, name: nil, adress: nil   )
        
        textField.resignFirstResponder()
        
        return false
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print(latInput.text, longInput.text)
        
        guard let latTemp = Double(latInput.text!) else {return }
        guard let longTemp = Double(longInput.text!) else {return }
        
        selectedLocation = CLLocation.init(latitude: latTemp, longitude: longTemp)
        refreshMap(long: selectedLong!, lat: selectedLat!, name: nil, adress: nil   )
        
        textField.resignFirstResponder()
    }
    
    func googleReverseGPS(GPSLocation: CLLocation){
        let URL_Search = "https://maps.googleapis.com/maps/api/geocode/json?"
        let API_iOSKey = "AIzaSyAzwACZh50Qq1V5YYKpmfN21mZs8dW6210"
        
        let urlString = "\(URL_Search)latlng=\(GPSLocation.coordinate.latitude),\(GPSLocation.coordinate.longitude)&key=\(API_iOSKey)"
        let url = URL(string: urlString)!
        
        //   https://maps.googleapis.com/maps/api/geocode/json?latlng=34.79,-111.76&key=AIzaSyAzwACZh50Qq1V5YYKpmfN21mZs8dW6210
        
        var temp = [String()]
        var locationGPStemp = [CLLocation()]
        
        
        Alamofire.request(url).responseJSON { (response) -> Void in
            
            print(response)
            
            if let value  = response.result.value {
                let json = JSON(value)
                
                if let results = json["results"].array {
                    
                    //                 print("Google Map Results ",results[0]["formatted_address"])
                    
                    self.locationAdress.text = results[0]["formatted_address"].string
                    
                    
                    
                    if results[0]["name"].string == nil {
                        
                        let lat = String(format:"%.4f", results[0]["geometry"]["location"]["lat"].double!)
                        let long = String(format:"%.4f", results[0]["geometry"]["location"]["lng"].double!)
                        
                        self.locationName.text = "GPS: " + " (" + lat + "," + long + ")"
                    } else {
                        self.locationName.text = results[0]["name"].string
                    }
                    
                }
            }
        }
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        print(place)
        selectedLocation = CLLocation.init(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        refreshMap(long: selectedLong!, lat: selectedLat!, name: place.name, adress: place.formattedAddress)
        selectedGooglePlaceID = place.placeID
        dismiss(animated: true, completion: nil)
        
    }
    
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print(error)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }

    
    

}
