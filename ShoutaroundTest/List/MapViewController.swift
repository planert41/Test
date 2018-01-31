//
//  MapViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/29/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import Firebase
import GeoFire
import GooglePlaces
import Alamofire
import SwiftyJSON


class MapViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, GMSMapViewDelegate, ListPhotoCellDelegate, GridPhotoCellDelegate, ListHeaderDelegate, FilterControllerDelegate {
    

    // List and Post Items
    var currentDisplayList: List? = nil {
        didSet{
            fetchPostsForList()
        }
    }
    var fetchedPosts: [Post] = []
    
    // Map Displays
    var placesClient: GMSPlacesClient!
    var marker = GMSMarker()
    var map: GMSMapView?
    let cameraZoom = 13 as Float
    let mapBackgroundView = UIView()
    
    // CollectionView
    let listCellId = "bookmarkCellId"
    let gridCellId = "gridCellId"
    let listHeaderId = "listHeaderId"
    
    lazy var collectionView : UICollectionView = {
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: FixedHeadersCollectionViewFlowLayout())
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()
    var collectionViewHeight:NSLayoutConstraint?
    var expandCollectionView: Bool = false {
        didSet{
            self.updateCollectionViewHeight()
        }
    }
    var isListView: Bool = true
    
    
    func updateCollectionViewHeight(){
        if expandCollectionView && self.collectionViewHeight?.constant != 400{
            UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
                self.collectionViewHeight?.constant = 400
                self.collectionView.layoutIfNeeded()
            })
//            collectionViewHeight?.constant = 400
        } else if !expandCollectionView && self.collectionViewHeight?.constant == 400  {
            UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
                self.collectionViewHeight?.constant = 160
                self.collectionView.layoutIfNeeded()
            })
//            collectionViewHeight?.constant = 160
        }
    }
    
    // Filtering Variables
    
    var isFiltering: Bool = false
    var filterCaption: String? = nil
    var filterRange: String? = nil
    var filterLocation: CLLocation? = CurrentUser.currentLocation
    var filterLocationName: String? = nil
    var filterGoogleLocationID: String? = nil
    var filterMinRating: Double = 0
    var filterType: String? = nil
    var filterMaxPrice: String? = nil
    
    // Header Sort Variables
    // Default Sort is Most Recent Listed Date
    var selectedHeaderSort:String? = defaultNearestSort

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white

        setupNavigationItems()
        
        view.addSubview(mapBackgroundView)
        mapBackgroundView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        mapBackgroundView.heightAnchor.constraint(equalTo: mapBackgroundView.widthAnchor).isActive = true
        
        let bottomDivider = UIView()
        view.addSubview(bottomDivider)
        bottomDivider.backgroundColor = UIColor.legitColor()
        bottomDivider.anchor(top: mapBackgroundView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
        
        if CurrentUser.currentLocation == nil {
            print("Map View, No Current User Location, Fetching Location")
            LocationSingleton.sharedInstance.determineCurrentLocation()
            let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
            DispatchQueue.main.asyncAfter(deadline: when) {
                //Delay for 1 second to find current location
                self.filterLocation = CurrentUser.currentLocation
                self.setupMapView()
            }
        } else {
            self.setupMapView()
        }
        
        setupCollectionView()
        view.addSubview(collectionView)
        collectionView.anchor(top: mapBackgroundView.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        collectionViewHeight = collectionView.heightAnchor.constraint(equalToConstant: 160)
        collectionViewHeight?.isActive = true
        
    }

    func setupNavigationItems(){
        navigationItem.title = currentDisplayList?.name
    }
    
    
    func setupMapView(){
        
        // Setup Map
        guard let location = self.filterLocation else {
            print("No Location For Map Setup")
            return
        }
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: cameraZoom)
        
        map = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        map?.mapType = .normal
        map?.isMyLocationEnabled = true
        map?.delegate = self
        map?.settings.myLocationButton = true
//        map?.settings.zoomGestures = true
//        map?.settings.scrollGestures = true
        map?.settings.setAllGesturesEnabled(true)
        self.addMarkers()
        
        self.view.addSubview(map!)
        map?.anchor(top: mapBackgroundView.topAnchor, left: mapBackgroundView.leftAnchor, bottom: mapBackgroundView.bottomAnchor, right: mapBackgroundView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    


    
    func setupCollectionView(){
        collectionView.register(ListPhotoCell.self, forCellWithReuseIdentifier: listCellId)
        collectionView.register(GridPhotoCell.self, forCellWithReuseIdentifier: gridCellId)
        collectionView.register(ListViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: listHeaderId)
        
        collectionView.backgroundColor = .white

        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
    }
    
    func filterSortFetchedPosts(){
        
        self.checkFilter()
        // Filter Posts
        Database.filterPosts(inputPosts: self.fetchedPosts, filterCaption: self.filterCaption, filterRange: self.filterRange, filterLocation: self.filterLocation, filterMinRating: self.filterMinRating, filterType: self.filterType, filterMaxPrice: self.filterMaxPrice) { (filteredPosts) in
            
            // Sort Recent Post By Listed Date
            var listSort: String = "Listed"
            if self.selectedHeaderSort == defaultRecentSort {
                listSort = "Listed"
            } else {
                listSort = self.selectedHeaderSort!
            }
            
            Database.sortPosts(inputPosts: filteredPosts, selectedSort: listSort, selectedLocation: self.filterLocation, completion: { (filteredPosts) in
                
                self.fetchedPosts = []
                if filteredPosts != nil {
                    self.fetchedPosts = filteredPosts!
                }
                print("Finish Filter and Sorting Post")
                
                self.addMarkers()
                // Go to first cell Location
                if let location = self.fetchedPosts[0].locationGPS {
                    self.goToMap(location: location)
                }
                
                self.collectionView.reloadData()
            })
        }
    }

    func refreshPostsForFilter(){
        self.checkFilter()
        self.clearAllPost()
        self.collectionView.reloadData()
        self.fetchPostsForList()
        self.collectionView.refreshControl?.endRefreshing()
    }
    
    func handleRefresh(){
        print("Refresh List")
        self.clearAllPost()
        self.clearFilter()
        self.collectionView.reloadData()
        self.fetchPostsForList()
        self.collectionView.refreshControl?.endRefreshing()
    }
    
    func clearAllPost(){
        self.fetchedPosts = []
    }
    
    func checkFilter(){
        if self.filterCaption != nil || (self.filterRange != nil) || (self.filterMinRating != 0) || (self.filterType != nil) || (self.filterMaxPrice != nil) {
            self.isFiltering = true
        } else {
            self.isFiltering = false
        }
    }
    
    func clearFilter(){
        self.filterLocation = nil
        self.filterLocationName = nil
        self.filterRange = nil
        self.filterGoogleLocationID = nil
        self.filterMinRating = 0
        self.filterType = nil
        self.filterMaxPrice = nil
        self.selectedHeaderSort = defaultRecentSort
        self.isFiltering = false
        self.filterCaption = nil
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        // Helps with Memory usage for Map View
        map?.clear()
        map?.stopRendering()
        map?.removeFromSuperview()
        map?.delegate = nil
        map = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setupMapView()
    }
    
    // Collection View Expand Shrink
    
//    func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay) {
//        // Shrink Collection View
//        self.expandCollectionView = false
//    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        // Shrink Collection View
        self.expandCollectionView = false
    }
    
    var pointNow: CGPoint?
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pointNow = scrollView.contentOffset;
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let pointNow = pointNow else {return}
        
        if (scrollView.contentOffset.y<pointNow.y) {
            //Scroll Down
        } else if (scrollView.contentOffset.y>pointNow.y) {
            // Scroll Up
            self.expandCollectionView = true
        }
    }
    
    // Map Functions
    func addMarkers() {
        print("Add Markers To Map")
        for post in self.fetchedPosts {
            
            let postUID: String = post.id!
            let postLocation: CLLocation = post.locationGPS!
            
            let marker = GMSMarker()
            print("Marker Coordinate: \(postLocation)")
            marker.position = CLLocationCoordinate2D(latitude: postLocation.coordinate.latitude, longitude: postLocation.coordinate.longitude)
            marker.title = postUID
            marker.snippet = "Hey, this is \(postLocation.description)"
            marker.isTappable = true
            marker.map = self.map
            marker.tracksViewChanges = false
            marker.isDraggable = false
        }
    }
    
    func goToMap(location: CLLocation?){
        guard let location = location else{
            print("Map View: ERROR, No Location")
            return
        }
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: cameraZoom)
        print("Camera: \(camera)")
        let moveUpdate = GMSCameraUpdate.setCamera(camera)
        self.map?.moveCamera(moveUpdate)

    }
    
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {

        if let index = self.fetchedPosts.index(where: { (post) -> Bool in
            return post.id == marker.title
        }){
            // Scroll to Tapped Post
            
            let indexpath = IndexPath(row:index, section: 0)

            self.collectionView.scrollToItem(at: indexpath, at: UICollectionViewScrollPosition.centeredVertically, animated: true)
        }
        return true
    }
    
    
    
    func fetchPostsForList(){
        guard let displayListId = currentDisplayList?.id else {
            print("Fetch Post for List: ERROR, No List or ListId")
            return
        }
        
        Database.fetchPostFromList(list: self.currentDisplayList, completion: { (fetchedPosts) in
            print("Fetch Post for List : Success, \(displayListId):\(self.currentDisplayList?.name), Count: \(fetchedPosts?.count) Posts")
            
            if let fetchedPosts = fetchedPosts {
                self.fetchedPosts = fetchedPosts
            } else {
                self.fetchedPosts = []
            }
            
            if (self.selectedHeaderSort == HeaderSortOptions[1] && self.filterLocation == nil){
                print("Sort by Nearest, No Location, Look up Current Location")
                LocationSingleton.sharedInstance.determineCurrentLocation()
                let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
                DispatchQueue.main.asyncAfter(deadline: when) {
                    //Delay for 1 second to find current location
                    self.filterLocation = CurrentUser.currentLocation
                    self.filterSortFetchedPosts()
                }
            } else {
                self.filterSortFetchedPosts()
            }
        })
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if isListView {
            return CGSize(width: view.frame.width, height: 120)
        } else {
            let width = (view.frame.width - 2) / 3
            return CGSize(width: width, height: width)
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return fetchedPosts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var displayPost = fetchedPosts[indexPath.item]
        
        if isListView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: listCellId, for: indexPath) as! ListPhotoCell
            cell.delegate = self
            cell.bookmarkDate = displayPost.listedDate
            cell.post = displayPost
            if cell.isSelected{
                cell.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.2)
            } else {
                cell.backgroundColor = UIColor.white
            }
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! GridPhotoCell
            cell.delegate = self
            cell.post = displayPost
            return cell
        }
        

    }
    

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let post = self.fetchedPosts[indexPath.row]
        self.goToMap(location: post.locationGPS)
        self.navigationItem.title = post.locationName
        collectionView.reloadItems(at: [indexPath])
        self.expandCollectionView = false
        //print(displayedPosts[indexPath.item])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    // SORT FILTER HEADER
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: listHeaderId, for: indexPath) as! ListViewHeader
        header.isFiltering = self.isFiltering
        header.isListView = self.isListView
        header.selectedCaption  = self.filterCaption
        header.enableSearchBar = false
        header.selectedSort = self.selectedHeaderSort!
        header.delegate = self
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        var height = 30 + 5 + 5 // Header Sort with 5 Spacing
        height += 40 // Search bar View
        return CGSize(width: view.frame.width, height: 30 + 5 + 5)
    }
    
    // Filter Controller Delegate
    func filterControllerFinished(selectedCaption: String?, selectedRange: String?, selectedLocation: CLLocation?, selectedLocationName: String?, selectedGooglePlaceId: String?, selectedGooglePlaceType: [String]?, selectedMinRating: Double, selectedType: String?, selectedMaxPrice: String?, selectedSort: String) {
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
        
        // Refresh Everything
        self.refreshPostsForFilter()
    }
    
    // Header Delegates
    func didChangeToListView() {
        self.isListView = true
        collectionView.reloadData()
    }
    
    func didChangeToPostView() {
        self.isListView = false
        collectionView.reloadData()
    }
    
    func openFilter() {
        let filterController = FilterController()
        filterController.delegate = self
        
        filterController.selectedRange = self.filterRange
        filterController.selectedMinRating = self.filterMinRating
        filterController.selectedMaxPrice = self.filterMaxPrice
        filterController.selectedType = self.filterType
        
        filterController.selectedSort = self.selectedHeaderSort!
        
        self.navigationController?.pushViewController(filterController, animated: true)
    }
    
    func clearCaptionSearch() {
        
    }
    
    func openSearch(index: Int?) {
        
    }
    
    func headerSortSelected(sort: String) {
        self.selectedHeaderSort = sort
        self.collectionView.reloadData()
        
        if (self.selectedHeaderSort == HeaderSortOptions[1] && self.filterLocation == nil){
            print("Sort by Nearest, No Location, Look up Current Location")
            LocationSingleton.sharedInstance.determineCurrentLocation()
            let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
            DispatchQueue.main.asyncAfter(deadline: when) {
                //Delay for 1 second to find current location
                self.filterLocation = CurrentUser.currentLocation
                self.refreshPostsForFilter()
            }
        } else {
            self.refreshPostsForFilter()
        }
        
        print("Filter Sort is ", self.selectedHeaderSort)
    }
    
    
    // List Photo Cell Delegates
    
    func didTapUser(post: Post) {
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.userId = post.user.uid
        
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapLocation(post: Post) {
        let locationController = LocationController()
        locationController.selectedPost = post
        
        navigationController?.pushViewController(locationController, animated: true)
    }
    
    func didTapMessage(post: Post) {
        let messageController = MessageController()
        messageController.post = post
        
        navigationController?.pushViewController(messageController, animated: true)
    }
    
    func refreshPost(post: Post) {
        let index = fetchedPosts.index { (fetchedPost) -> Bool in
            fetchedPost.id == post.id
        }
        let indexpath = IndexPath(row:index!, section: 0)

        self.fetchedPosts[index!] = post
        self.collectionView.reloadItems(at: [indexpath])
        
        // Update Cache
        let postId = post.id
        postCache[postId!] = post
    }
    
    func deletePostFromList(post: Post) {
        let deleteAlert = UIAlertController(title: "Delete", message: "Remove Post From List?", preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            // Remove from Current View
            let index = self.fetchedPosts.index { (filteredpost) -> Bool in
                filteredpost.id  == post.id
            }
            
            let deleteindexpath = IndexPath(row:index!, section: 0)
            self.fetchedPosts.remove(at: index!)
            self.collectionView.deleteItems(at: [deleteindexpath])
            Database.DeletePostForList(postId: post.id!, listId: self.currentDisplayList?.id, postCreationDate: nil)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        if self.currentDisplayList?.creatorUID == uid{
            // Only Allow Deletion if current user is list creator
            present(deleteAlert, animated: true, completion: nil)
        }
    }
    
    func didTapPicture(post: Post) {
        let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
        pictureController.selectedPost = post
        
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    func didTapExtraTag(tagName: String, tagId: String, post: Post) {
        print("Not Allowed from Map View")
    }

    
    
}
