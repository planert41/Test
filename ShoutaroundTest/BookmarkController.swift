//
//  BookmarkController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/22/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import CoreGraphics
import GeoFire

class BookMarkController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UISearchControllerDelegate, HomePostSearchDelegate, BookmarkPhotoCellDelegate, HomePostCellDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    let bookmarkCellId = "bookmarkCellId"
    let homePostCellId = "homePostCellId"
    
    let locationManager = CLLocationManager()
    
    // Geo Filter Variables
    
    let geoFilterRange = geoFilterRangeDefault
    let geoFilterImage:[UIImage] = geoFilterImageDefault
    
    var filterRange: Double?{
        didSet{
            print(filterRange)
            if filterRange == nil {
                rangeImageButton.image = self.geoFilterImage[0].withRenderingMode(.alwaysOriginal)
                rangeImageButton.addGestureRecognizer(singleTap)
                rangeImageButton.addGestureRecognizer(longPressGesture)
                navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: rangeImageButton)
                
            } else {
                print(String(format:"%.1f", self.filterRange!))
                let rangeIndex = self.geoFilterRange.index(of: String(format:"%.1f", self.filterRange!))
                
                rangeImageButton.image = geoFilterImage[rangeIndex!].withRenderingMode(.alwaysOriginal)
                rangeImageButton.addGestureRecognizer(singleTap)
                rangeImageButton.addGestureRecognizer(longPressGesture)
                navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: rangeImageButton)
                
                
            }
        }
    }
    
    
    var rangeImageButton: UIImageView = {
        let view = UIImageView()
        view.image = #imageLiteral(resourceName: "Globe").withRenderingMode(.alwaysOriginal)
        view.contentMode = .scaleAspectFit
        view.sizeToFit()
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    lazy var singleTap: UIGestureRecognizer = {
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(filterHere))
        tap.delegate = self
        return tap
    }()
    
    lazy var longPressGesture: UILongPressGestureRecognizer = {
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(activateFilterRange))
        longPressGesture.minimumPressDuration = 1.0 // 1 second press
        longPressGesture.delegate = self
        return longPressGesture
    }()

    let searchBarPlaceholderText = "Search for Caption or Emoji 😍🐮🍔🇺🇸🔥"
    let currentLocation: CLLocation? = CLLocation(latitude: 41.973735, longitude: -87.667751)
    
    
    var userId:String?
    var allPosts = [Post]()
    var filteredPosts = [Post]()
    
    var isGridView = true

    lazy var actionBar: UIView = {
        let sv = UIView()
        return sv
    }()
    
    var resultSearchController:UISearchController? = nil
    var searchBar: UISearchBar? = nil
    
    lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()
    
    // Setup Bottom Grid/List Buttons
    
    lazy var gridButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "grid"), for: .normal)
        button.addTarget(self, action: #selector(handleChangetoGridView), for: .touchUpInside)
        return button
    }()
    
    func handleChangetoGridView() {
        gridButton.tintColor = UIColor.mainBlue()
        listButton.tintColor = UIColor(white: 0, alpha: 0.2)
        isGridView = true
        collectionView.reloadData()
    }
    
    lazy var listButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "list"), for: .normal)
        button.tintColor = UIColor(white: 0, alpha: 0.2)
        button.addTarget(self, action: #selector(handleChangetoListView), for: .touchUpInside)
        return button
    }()
    
    func handleChangetoListView() {
        listButton.tintColor = UIColor.mainBlue()
        gridButton.tintColor = UIColor(white: 0, alpha: 0.2)
        isGridView = false
        collectionView.reloadData()
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        view.backgroundColor = .white

        setupNavigationItems()
        setupGeoPicker()
        view.addSubview(actionBar)
        actionBar.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        actionBar.backgroundColor = .white
        setupBottomToolbar()
        
// Setup CollectionView
        
        collectionView.backgroundColor = .white
        collectionView.register(BookmarkPhotoCell.self, forCellWithReuseIdentifier: bookmarkCellId)
        collectionView.register(HomePostCell.self, forCellWithReuseIdentifier: homePostCellId)
        
        view.addSubview(collectionView)
        collectionView.anchor(top: actionBar.bottomAnchor , left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
// Fetch Photos and Refresh
        
        fetchBookmarkPosts()
        setupRefresh()
        
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }
        
    }
    
    fileprivate func setupRefresh() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
    }

    
    fileprivate func setupBottomToolbar() {
        
        let homePostSearchResults = HomePostSearch()
        homePostSearchResults.delegate = self
        resultSearchController = UISearchController(searchResultsController: homePostSearchResults)
        resultSearchController?.searchResultsUpdater = homePostSearchResults
        resultSearchController?.delegate = self
        searchBar = resultSearchController?.searchBar
        searchBar?.backgroundColor = UIColor.clear
        navigationItem.titleView = searchBar
        searchBar?.delegate = homePostSearchResults
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        let searchBarView = UIView()
        let buttonView = UIView()

        let buttonStackView = UIStackView(arrangedSubviews: [gridButton, listButton])
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        
        let topDividerView = UIView()
        topDividerView.backgroundColor = UIColor.lightGray
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor.lightGray
        
        view.addSubview(buttonStackView)

        view.addSubview(topDividerView)
        view.addSubview(bottomDividerView)

        buttonStackView.anchor(top: actionBar.topAnchor, left: actionBar.leftAnchor, bottom: actionBar.bottomAnchor, right: actionBar.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        topDividerView.anchor(top: buttonStackView.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        bottomDividerView.anchor(top: buttonStackView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
    }
    
    fileprivate func setupNavigationItems() {
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "mailbox").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(openInbox))
        
        //        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "GeoFence").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(filterHere))
        
        var rangeImageButton = UIImageView()
        rangeImageButton.image = #imageLiteral(resourceName: "Globe").withRenderingMode(.alwaysOriginal)
        rangeImageButton.contentMode = .scaleAspectFit
        rangeImageButton.sizeToFit()
        rangeImageButton.backgroundColor = UIColor.clear
        
        
        rangeImageButton.addGestureRecognizer(singleTap)
        rangeImageButton.addGestureRecognizer(longPressGesture)
        
        let rangeBarButton = UIBarButtonItem.init(customView: rangeImageButton)
        //        rangeBarButton.image = #imageLiteral(resourceName: "Globe").withRenderingMode(.alwaysOriginal)
        
        
        navigationItem.rightBarButtonItem = rangeBarButton
        
    }

func openInbox() {
    
    let inboxController = InboxController(collectionViewLayout: UICollectionViewFlowLayout())
    navigationController?.pushViewController(inboxController, animated: true)
    
}
    
    
    // LOCATION MANAGER DELEGATE METHODS
    
    func determineCurrentLocation(){
        
        CurrentUser.currentLocation = nil
        
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
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("GPS Location Not Found")
    }
    
    
    // Search Delegate And Methods
    
    func filterCaptionSelected(searchedText: String?) {
        self.resultSearchController?.searchBar.text = searchedText
        filterPostByCaption(self.resultSearchController?.searchBar.text)
        filterPostByLocation()
        self.collectionView.reloadData()
    }
    
    func filterHere(){
        
        self.filterRange = Double(geoFilterRange[5])
        self.filterPostByLocation()
        let indexPath = IndexPath(item: 0, section: 0)
        self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
        
    }
    
    func filterPostByCaption(_ string: String?) {
        
        guard let searchedText = string else {
            print("No Search Term")
            filteredPosts = allPosts
            self.collectionView.reloadData()
            return
        }
        
        if searchedText.isEmpty || searchedText == "" {
            filteredPosts = allPosts
            print("No Search Term")
        } else {
            
            print("Search Term Was", searchedText)
            //Makes everything case insensitive
            filteredPosts = self.allPosts.filter { (post) -> Bool in
                return post.caption.lowercased().contains(searchedText.lowercased()) || post.emoji.contains(searchedText.lowercased()) || post.locationName.contains(searchedText.lowercased()) || post.locationAdress.contains(searchedText.lowercased())
            }
            collectionView.reloadData()
        }
    }
    
    func filterPostByLocation(){
        
        let ref = Database.database().reference().child("postlocations")
        let geoFire = GeoFire(firebaseRef: ref)
        //     let currentLocation = CLLocation(latitude: 41.973735, longitude: -87.667751)
        
        var geoFilteredPosts = [Post]()
        
        guard let filterDistance = self.filterRange else {
            collectionView.reloadData()
            print("No Distance Number")
            return}
        
        self.determineCurrentLocation()
        
        let when = DispatchTime.now() + 0.5 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            
            print("Current User Location Used for Post Filtering", CurrentUser.currentLocation)
            let circleQuery = geoFire?.query(at: CurrentUser.currentLocation, withRadius: filterDistance)
            circleQuery?.observe(.keyEntered, with: { (key, location) in
                var geoFilteredPost: [Post] = self.filteredPosts.filter { (post) -> Bool in
                    return post.id == key
                }
                
                if geoFilteredPost != nil && geoFilteredPost.count > 0 && geoFilteredPost[0].locationGPS != nil {
                    geoFilteredPost[0].locationGPS = location
                    geoFilteredPost[0].distance = Double((location?.distance(from: CurrentUser.currentLocation!))!)
                }
                geoFilteredPosts += geoFilteredPost
            })
            
            circleQuery?.observeReady({
                self.filteredPosts = geoFilteredPosts.sorted(by: { (p1, p2) -> Bool in
                    p1.distance!.isLess(than: p2.distance!)
                })
                
                if self.collectionView.numberOfItems(inSection: 0) != 0 {
                    let indexPath = IndexPath(item: 0, section: 0)
                    self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
                self.collectionView.reloadData()
            })
        }
    }
    
// Setup for Picker
    
    func activateFilterRange() {
        
        if self.filterRange != nil {
            let rangeIndex = self.geoFilterRange.index(of: String(format:"%.1f", self.filterRange!))
            pickerView.selectRow(rangeIndex!, inComponent: 0, animated: false)
        }
        dummyTextView.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.1)
    }
    
    
    lazy var dummyTextView: UITextView = {
        let tv = UITextView()
        return tv
    }()
    
    
    
    var pickerView: UIPickerView = {
        let pv = UIPickerView()
        pv.backgroundColor = .white
        pv.showsSelectionIndicator = true
        
        return pv
    }()
    
    
    func setupGeoPicker() {

        pickerView.dataSource = self
        pickerView.delegate = self
        
        var toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.bordered, target: self, action: Selector("donePicker"))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.bordered, target: self, action: Selector("cancelPicker"))
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        self.dummyTextView.inputView = pickerView
        self.dummyTextView.inputAccessoryView = toolBar
        self.view.addSubview(dummyTextView)
    }
    
    func donePicker(){
        dummyTextView.resignFirstResponder()
        filterPostByCaption(self.resultSearchController?.searchBar.text)
        filterPostByLocation()
    }
    
    func cancelPicker(){
        dummyTextView.resignFirstResponder()
    }
    
    
    // UIPicker DataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
        
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return geoFilterRange.count
    }
    
    // UIPicker Delegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return geoFilterRange[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // If Select some number
        if row > 0 {
            filterRange = Double(geoFilterRange[row])
        } else {
            filterRange = nil
        }
    }
    
    func fetchBookmarkPosts() {
        
        guard let uid = Auth.auth().currentUser?.uid  else {return}
        let ref = Database.database().reference().child("bookmarks").child(uid)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            //print(snapshot.value)
            
            
            guard let dictionaries = snapshot.value as? [String: Any] else {return}
            
            dictionaries.forEach({ (key,value) in
            
                guard let dictionary = value as? [String: Any] else {return}
                if let value = dictionary["bookmarked"] as? Int, value == 1 {
                
                    if let creatorUID = dictionary["creatorUID"] as? String {
                        
                        Database.fetchPostWithUIDAndPostID(creatoruid: creatorUID, postId: key, completion: { (post) in

                            self.allPosts.append(post)
                            self.filteredPosts = self.allPosts
                            self.collectionView.reloadData()
                            
                        })
                    }
                }
            })
        })
    }
    
    func handleRefresh() {
        
        allPosts.removeAll()
        filteredPosts.removeAll()
        self.resultSearchController?.searchBar.text = ""
        self.filterRange = nil
        collectionView.reloadData()
        fetchBookmarkPosts()
        self.collectionView.refreshControl?.endRefreshing()
        print("Refresh Bookmark Feed")
    }
    
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredPosts.count
    }
    
     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var displayPost = filteredPosts[indexPath.item]
        
        if CurrentUser.currentLocation != nil {
            displayPost.distance = Double((displayPost.locationGPS?.distance(from: CurrentUser.currentLocation!))!)
        }
        
        if isGridView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: bookmarkCellId, for: indexPath) as! BookmarkPhotoCell
            cell.delegate = self
            cell.post = displayPost


            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: homePostCellId, for: indexPath) as! HomePostCell
            cell.delegate = self
            cell.post = displayPost
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if isGridView {

            return CGSize(width: view.frame.width, height: 150)
        } else {
            var height: CGFloat = 40 + 8 + 8 //username userprofileimageview
            height += view.frame.width
            height += 50
            height += 60
            
            return CGSize(width: view.frame.width, height: height)
        }
        
    }
    
    // HOME POST CELL DELEGATE METHODS
    
    func didTapPicture(post: Post) {
        
        let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
        pictureController.selectedPost = post
        
        
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    
    func didTapComment(post: Post) {
        
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.post = post
        
        navigationController?.pushViewController(commentsController, animated: true)
    }
    
    func didTapUser(post: Post) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.userId = post.user.uid
        
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapLocation(post: Post) {
        let locationController = LocationController()
        locationController.selectedPost = post
        
        navigationController?.pushViewController(locationController, animated: true)
    }
    
    func refreshPost(post: Post) {
        let index = filteredPosts.index { (filteredpost) -> Bool in
            filteredpost.id  == post.id
        }
        
        let filteredindexpath = IndexPath(row:index!, section: 0)
        print(index)
        if post.hasBookmarked == false{
            self.filteredPosts.remove(at: index!)
            self.collectionView.deleteItems(at: [filteredindexpath])
        }

        
        self.filteredPosts[index!] = post
        //        self.collectionView?.reloadItems(at: [filteredindexpath])
    }
    
    func didTapMessage(post: Post) {
        
        let messageController = MessageController()
        messageController.post = post
        
        navigationController?.pushViewController(messageController, animated: true)
        
    }
    
    func deletePost(post:Post){
        
        let deleteAlert = UIAlertController(title: "Delete", message: "All data will be lost.", preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            
            
            Database.database().reference().child("posts").child(post.id!).removeValue()
            Database.database().reference().child("postlocations").child(post.id!).removeValue()
            Database.database().reference().child("userposts").child(post.creatorUID!).child(post.id!).removeValue()
            
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(deleteAlert, animated: true, completion: nil)
        
        
    }
    
    
    
//     func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "bookmarkHeaderId", for: indexPath) as! BookmarkHeader
//        
//        header.delegate = self
//        
//        return header
//        
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: view.frame.width, height: 100)
//    }
    
}
