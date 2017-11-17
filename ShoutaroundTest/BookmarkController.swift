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

class BookMarkController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchControllerDelegate, HomePostSearchDelegate, BookmarkPhotoCellDelegate, HomePostCellDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate, FilterControllerDelegate, UISearchBarDelegate {
    let bookmarkCellId = "bookmarkCellId"
    let homePostCellId = "homePostCellId"
    
    let locationManager = CLLocationManager()
    
    // Geo Filter Variables
    
    let geoFilterRange = geoFilterRangeDefault
    let geoFilterImage:[UIImage] = geoFilterImageDefault
    
    // Filter Variables
    
    let defaultRange = geoFilterRangeDefault[geoFilterRangeDefault.endIndex-1]
    let defaultGroup = "All"
    let defaultSort = FilterSortDefault[FilterSortDefault.endIndex - 1]
    let defaultTime =  FilterSortTimeDefault[FilterSortTimeDefault.endIndex - 1]
    
    
    var filterCaption: String? = nil{
        didSet{
            
        }
    }
    var filterLocation: CLLocation? = nil
    var filterGroup: String? {
        didSet{
            setupNavigationItems()
        }
    }
    var filterRange: String? {
        didSet{
            setupNavigationItems()
        }
    }
    
    var filterSort: String?
    var filterTime: String?{
        didSet{
            setupNavigationItems()
        }
    }
    
    var filterButton: UIImageView = {
        let view = UIImageView()
        view.image = #imageLiteral(resourceName: "blankfilter").withRenderingMode(.alwaysOriginal)
        view.contentMode = .scaleAspectFit
        view.sizeToFit()
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    
    var rangeImageButton: UIImageView = {
        let view = UIImageView()
        view.image = #imageLiteral(resourceName: "Globe").withRenderingMode(.alwaysOriginal)
        view.contentMode = .scaleAspectFit
        view.sizeToFit()
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    lazy var singleTap: UIGestureRecognizer = {
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(activateFilter))
        tap.delegate = self
        return tap
    }()
    
//    let currentLocation: CLLocation? = CLLocation(latitude: 41.973735, longitude: -87.667751)
    
    
    var userId:String?
    var fetchedBookmarks = [Bookmark]()
    var displayedBookmarks = [Bookmark]()
    
    var isGridView = true

    lazy var actionBar: UIView = {
        let sv = UIView()
        return sv
    }()
    
    var resultSearchController:UISearchController? = nil
    var defaultSearchBar = UISearchBar()
    
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
    
    
    
    // Emoji description
    
    let emojiDetailLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.layer.cornerRadius = 30/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.masksToBounds = true
        return label
        
    }()
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        emojiDetailLabel.isHidden = true
    }
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        view.backgroundColor = .white


        setupNavigationItems()
        view.addSubview(actionBar)
        actionBar.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        actionBar.backgroundColor = .white
        setupSearchController()
        setupBottomToolbar()
        
// Setup CollectionView
        
        collectionView.backgroundColor = .white
        collectionView.register(BookmarkPhotoCell.self, forCellWithReuseIdentifier: bookmarkCellId)
        collectionView.register(HomePostCell.self, forCellWithReuseIdentifier: homePostCellId)
        
        view.addSubview(collectionView)
        collectionView.anchor(top: actionBar.bottomAnchor , left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }
        
        // Fetch Photos and Refresh

        setupRefresh()
        clearFilter()
        
        fetchBookmarkPosts()
        
        // Add Detail Label last so that its above collectionview
        
        view.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: actionBar.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 150, height: 25)
        emojiDetailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        emojiDetailLabel.isHidden = true
        
    }
    
    func sortBookmarks(){
        if self.filterSort == FilterSortDefault[1] {
            self.displayedBookmarks.sort(by: { (p1, p2) -> Bool in
                return p1.bookmarkDate.compare(p2.bookmarkDate) == .orderedAscending
            })
        } else if self.filterSort == FilterSortDefault[0] {
            
            self.displayedBookmarks.sort(by: { (p1, p2) -> Bool in
                return (p1.post.distance! < p2.post.distance!)
            })
        } else {
            self.displayedBookmarks.sort(by: { (p1, p2) -> Bool in
                return p1.bookmarkDate.compare(p2.bookmarkDate) == .orderedDescending
            })
        }
    }
    
    
    fileprivate func setupRefresh() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
    }

    fileprivate func setupSearchController(){
        
        let homePostSearchResults = HomePostSearch()
        homePostSearchResults.delegate = self
        resultSearchController = UISearchController(searchResultsController: homePostSearchResults)
        resultSearchController?.searchResultsUpdater = homePostSearchResults
        resultSearchController?.delegate = self
        let searchBar = resultSearchController?.searchBar
        searchBar?.backgroundColor = UIColor.clear
        searchBar?.placeholder =  searchBarPlaceholderText
        searchBar?.delegate = homePostSearchResults
        
        resultSearchController?.hidesNavigationBarDuringPresentation = true
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.present(resultSearchController!, animated: true, completion: nil)
        return false
    }
    
    fileprivate func setupBottomToolbar() {

        
        let buttonView = UIView()

        let buttonStackView = UIStackView(arrangedSubviews: [gridButton, listButton])
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        
        let topDividerView = UIView()
        topDividerView.backgroundColor = UIColor.lightGray
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor.lightGray
        
        defaultSearchBar.barTintColor = UIColor.rgb(red: 128, green: 191, blue: 255)
//        defaultSearchBar.backgroundColor = UIColor.gray
        defaultSearchBar.layer.borderWidth = 0.5
        defaultSearchBar.layer.borderColor = UIColor.lightGray.cgColor
        defaultSearchBar.delegate = self
        
        view.addSubview(buttonStackView)
        view.addSubview(defaultSearchBar)
        view.addSubview(topDividerView)
        view.addSubview(bottomDividerView)
        
        
        buttonStackView.anchor(top: actionBar.topAnchor, left: actionBar.leftAnchor, bottom: actionBar.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 150, height: 0)
        
        defaultSearchBar.anchor(top: actionBar.topAnchor, left: buttonStackView.rightAnchor, bottom: actionBar.bottomAnchor, right: actionBar.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
        topDividerView.anchor(top: buttonStackView.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        bottomDividerView.anchor(top: nil, left: view.leftAnchor, bottom: buttonStackView.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
    }
    
    fileprivate func setupNavigationItems() {
        
        navigationItem.title = "Bookmarks"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "mailbox").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(openInbox))

        if self.filterGroup == defaultGroup && self.filterRange == defaultRange && self.filterTime == defaultTime && self.filterGroup == "All" {
            filterButton.image = #imageLiteral(resourceName: "blankfilter").withRenderingMode(.alwaysOriginal)
            filterButton.backgroundColor = UIColor.clear
        } else {
            filterButton.image = #imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal)
//            filterButton.backgroundColor = UIColor.mainBlue()
            filterButton.addGestureRecognizer(singleTap)
        }
        
        let rangeBarButton = UIBarButtonItem.init(customView: filterButton)
        navigationItem.rightBarButtonItem = rangeBarButton
        
    }

    // Search Delegate And Methods
    
    func activateFilter(){
        let filterController = FilterController()
        filterController.delegate = self
        filterController.selectedRange = self.filterRange
        filterController.selectedGroup = self.filterGroup
        filterController.selectedSort = self.filterSort
        filterController.selectedTime = self.filterTime
        self.navigationController?.pushViewController(filterController, animated: true)
    }
    
    
    func openInbox() {
    
        let inboxController = InboxController(collectionViewLayout: UICollectionViewFlowLayout())
        navigationController?.pushViewController(inboxController, animated: true)
    
    }
    
    
    func finalFilterAndSort(){
        
        self.displayedBookmarks.removeAll()
        self.displayedBookmarks = self.fetchedBookmarks
        print("Start Filter with Posts: ", self.displayedBookmarks.count)
        
        self.filterbyTime()
        print("After Time Filter Posts: ", self.displayedBookmarks.count)
        
        self.filterbyDistance()
        print("After Distance Filter Posts: ", self.displayedBookmarks.count)
        
        self.filterbyGroup()
        print("After Group Filter Posts: ", self.displayedBookmarks.count)
        
        self.filterbyCaption()
        print("After Caption Filter Posts: ", self.displayedBookmarks.count)
        
        self.sortBookmarks()
        print("After All Filter Posts: ", self.displayedBookmarks.count)
        
        self.collectionView.reloadData()
        
        
    }

    func filterbyCaption(){
        guard let searchedText = self.filterCaption else {return}
        // Check if caption are not just all spaces
        
        if searchedText != "" {
            self.displayedBookmarks = self.displayedBookmarks.filter { (bookmark) -> Bool in
            return bookmark.post.caption.lowercased().contains(searchedText.lowercased()) || bookmark.post.emoji.contains(searchedText.lowercased()) || bookmark.post.locationName.lowercased().contains(searchedText.lowercased()) || bookmark.post.locationAdress.lowercased().contains(searchedText.lowercased())
            }
        }
        
    }
    
    func filterbyGroup(){
        
        if self.filterGroup != self.defaultGroup{
        self.displayedBookmarks = self.displayedBookmarks.filter { (bookmark) -> Bool in
                return CurrentUser.groupUids.contains(bookmark.post.creatorUID!)
            }
        }
    }
    
    func filterbyTime(){
        if self.filterTime != self.defaultTime{
            guard let filterIndex = FilterSortTimeDefault.index(of: self.filterTime!) else {return}
            
            self.displayedBookmarks = self.displayedBookmarks.filter { (bookmark) -> Bool in
                let calendar = Calendar.current
                let tagHour = Double(calendar.component(.hour, from: bookmark.post.tagTime))
                return !(FilterSortTimeStart[filterIndex] > tagHour || tagHour > FilterSortTimeEnd[filterIndex])
            }
        }
    }
    
    
    func filterbyDistance(){
        
        guard let filterDistance = Double(self.filterRange!) else {
            print("Invalid Distance Number or Non Distance")
            return
        }
        
        guard let selectedLocation = self.filterLocation else {
            print("Invalid Location")
            return
        }
        
        var tempBookmarks = [] as [Bookmark]
        
        for bookmark in self.displayedBookmarks {
            
            var tempBookmark = bookmark
            if tempBookmark.post.locationGPS?.coordinate.latitude != 0 && tempBookmark.post.locationGPS?.coordinate.longitude != 0 {
                tempBookmark.post.distance = tempBookmark.post.locationGPS?.distance(from: selectedLocation)
                if tempBookmark.post.distance! <= filterDistance * 1000{
                    tempBookmarks.append(tempBookmark)
                }
            }
        }
        self.displayedBookmarks = tempBookmarks
        
    }
    
    
    func filterCaptionSelected(searchedText: String?){
        self.defaultSearchBar.text = searchedText
        self.finalFilterAndSort()
        
    }
    
    func userSelected(uid: String?){
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.userId = uid
        self.navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func locationSelected(googlePlaceId: String?){
        
    }
    
    
    func filterControllerFinished(selectedRange: String?, selectedLocation: CLLocation?, selectedGooglePlaceID: String?, selectedTime: String?, selectedGroup: String?, selectedSort: String?){
        
        self.filterRange = selectedRange
        self.filterLocation = selectedLocation
        self.filterGroup = selectedGroup
        self.filterSort = selectedSort
        self.filterTime = selectedTime
        
        self.finalFilterAndSort()
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

        func fetchBookmarkPosts() {
    
            guard let uid = Auth.auth().currentUser?.uid  else {return}
            let ref = Database.database().reference().child("bookmarks").child(uid)
    
            ref.observeSingleEvent(of: .value, with: {(snapshot) in
                //print(snapshot.value)
    
                guard let dictionaries = snapshot.value as? [String: Any] else {return}
    
                dictionaries.forEach({ (key,value) in
    
                    guard let dictionary = value as? [String: Any] else {return}
                    if let value = dictionary["bookmarked"] as? Int, value == 1 {
    
                        let bookmarkTime = dictionary["bookmarkDate"] as? Double ?? 0
                        if let creatorUID = dictionary["creatorUID"] as? String {
    
                        Database.fetchPostWithPostID(postId: key, completion: { (post, error) in
                        
                            if let error = error {
                                print("Failed to fetch post for bookmarks: ",key , error)
                                return
                            }
                        
                            guard let post = post else {
                                print("No Result for PostId: ", key)
                                //Delete Bookmark since post is unavailable
                                
                                Database.fetchUserWithUID(uid: creatorUID, completion: { (user) in
                                    
                                    let bookmarkDate = Date(timeIntervalSince1970: bookmarkTime)
                                    
                                    
                                    let deleteAlert = UIAlertController(title: "Delete Bookmark", message: "Post Created By \(user.username) and Bookmarked on \(bookmarkDate) Was Deleted", preferredStyle: UIAlertControllerStyle.alert)
                                    
                                    deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                                        
                                        Database.database().reference().child("bookmarks").child(uid).child(key).removeValue()
                                        
                                    }))
                                    
                                    self.present(deleteAlert, animated: true, completion: nil)
                                })
                                return}
                            
                        let tempBookmark = Bookmark.init(bookmarkCreatorUid: creatorUID, fetchedDate: bookmarkTime, post: post)
                        self.fetchedBookmarks.append(tempBookmark)
                        self.fetchedBookmarks.sort(by: { (p1, p2) -> Bool in
                        return p1.bookmarkDate.compare(p2.bookmarkDate) == .orderedDescending
                          })
                        self.displayedBookmarks = self.fetchedBookmarks
                        self.collectionView.reloadData()
                                })
                            }
                        }
                    })
                })
            }
    
    
    func clearFilter(){
        
        self.defaultSearchBar.text = nil
        self.filterCaption = nil
        self.filterLocation = nil
        self.filterGroup = defaultGroup
        self.filterRange = defaultRange
        self.filterSort = defaultSort
        self.filterTime = defaultTime
    }
    
    
    func handleRefresh() {

        clearFilter()
        fetchedBookmarks.removeAll()
        displayedBookmarks.removeAll()
        self.collectionView.reloadData()
        fetchBookmarkPosts()
        self.collectionView.refreshControl?.endRefreshing()
        print("Refresh Bookmark Feed")
    }
    
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedBookmarks.count
    }
    
     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var displayPost = displayedBookmarks[indexPath.item]
        
        if self.filterLocation != nil {
            displayPost.post.distance = Double((displayPost.post.locationGPS?.distance(from: self.filterLocation!))!)
        }
        
        if isGridView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: bookmarkCellId, for: indexPath) as! BookmarkPhotoCell
            cell.delegate = self
            cell.bookmarkDate = displayPost.bookmarkDate
            cell.post = displayPost.post


            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: homePostCellId, for: indexPath) as! HomePostCell
            cell.delegate = self
            cell.post = displayPost.post
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
        let index = displayedBookmarks.index { (bookmark) -> Bool in
            bookmark.post.id == post.id
        }
        
        let filteredindexpath = IndexPath(row:index!, section: 0)
        print(index)
        if post.hasBookmarked == false{
            self.displayedBookmarks.remove(at: index!)
            self.collectionView.deleteItems(at: [filteredindexpath])
        }

        
        self.displayedBookmarks[index!].post = post
        
        // Update Cache
        
        let postId = post.id
        postCache[postId!] = post
        
        //        self.collectionView?.reloadItems(at: [filteredindexpath])
    }
    
    func didTapMessage(post: Post) {
        
        let messageController = MessageController()
        messageController.post = post
        
        navigationController?.pushViewController(messageController, animated: true)
        
    }
    
    func userOptionPost(post:Post){
        
        let optionsAlert = UIAlertController(title: "User Options", message: "", preferredStyle: UIAlertControllerStyle.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "Edit Post", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.editPost(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Delete Post", style: .default, handler: { (action: UIAlertAction!) in
            self.deletePost(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true, completion: nil)
    }
    
    func editPost(post:Post){
        let editPost = SharePhotoController()
        
        // Post Edit Inputs
        editPost.editPost = true
        editPost.editPostImageUrl = post.imageUrl
        editPost.editPostId = post.id
        
        // Post Details
        editPost.selectedPostGooglePlaceID = post.locationGooglePlaceID
        editPost.selectedImageLocation = post.locationGPS
        editPost.selectedPostLocation = post.locationGPS
        editPost.selectedPostLocationName = post.locationName
        editPost.selectedPostLocationAdress = post.locationAdress
        editPost.selectedTime = post.tagTime
        editPost.ratingEmoji = post.ratingEmoji
        editPost.nonRatingEmoji = post.nonRatingEmoji
        editPost.nonRatingEmojiTags = post.nonRatingEmojiTags
        editPost.captionTextView.text = post.caption
        
        let navController = UINavigationController(rootViewController: editPost)
        self.present(navController, animated: false, completion: nil)
    }
    
    
    func deletePost(post:Post){
        
        let deleteAlert = UIAlertController(title: "Delete", message: "All data will be lost.", preferredStyle: UIAlertControllerStyle.alert)
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            
            // Remove from Current View
            let index = self.displayedBookmarks.index { (filteredpost) -> Bool in
                filteredpost.post.id  == post.id
            }
            
            let filteredindexpath = IndexPath(row:index!, section: 0)
            self.displayedBookmarks.remove(at: index!)
            self.collectionView.deleteItems(at: [filteredindexpath])
            Database.deletePost(post: post)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
        
    }

    
    func displaySelectedEmoji(emoji: String, emojitag: String) {
        
        emojiDetailLabel.text = emoji + " " + emojitag
        emojiDetailLabel.isHidden = false
        
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
