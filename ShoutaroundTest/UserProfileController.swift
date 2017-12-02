//
//  UserProfileController.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/26/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import IQKeyboardManagerSwift
import CoreLocation

class UserProfileController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UserProfileHeaderDelegate, HomePostCellDelegate,BookmarkPhotoCellDelegate, UserProfilePhotoCellDelegate, UISearchBarDelegate, HomePostSearchDelegate, FilterControllerDelegate, UISearchControllerDelegate, UIGestureRecognizerDelegate{
    
    let cellId = "cellId"
    let homePostCellId = "homePostCellId"
    
    var displayedPosts = [Post]() {
        didSet{
            if displayedPosts.count > 0 {
                self.noResultsLabel.isHidden = true
            }
        }
    }
    
    var userId:String?
    var isGroup: Bool = false {
        didSet{
            if (userId != Auth.auth().currentUser?.uid) {
            if isGroup && (userId != Auth.auth().currentUser?.uid) {
                self.navigationItem.rightBarButtonItem?.image = #imageLiteral(resourceName: "redstar").withRenderingMode(.alwaysOriginal)
            } else {
                self.navigationItem.rightBarButtonItem?.image = #imageLiteral(resourceName: "starunfill").withRenderingMode(.alwaysOriginal)
            }
        }
        }
    }
    var user: User?
    
    var isGridView = true
    
    var groupSelections:[String] = ["Family","Friends","Foodie","Group1", "Group2"]
    var unGroupSelections:[String] = ["Delete"]
    
// No Results Label
    
    var noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = UIColor.black
        label.backgroundColor = UIColor.clear
        label.isHidden = true
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
// Filter Variables
    
    // Filter Variables
//    
//    let defaultRange = geoFilterRangeDefault[geoFilterRangeDefault.endIndex - 1]
//    let defaultGroup = "All"
//    let defaultSort = FilterSortDefault[FilterSortDefault.endIndex - 1]
//    let defaultTime =  FilterSortTimeDefault[FilterSortTimeDefault.endIndex - 1]
    
    var filterCaption: String? = nil{
        didSet{
            
        }
    }
    var filterLocation: CLLocation? = nil
    var filterGroup: String = defaultGroup {
        didSet{
            setupNavigationItems()
        }
    }
    var filterRange: String = defaultRange {
        didSet{
            setupNavigationItems()
        }
    }
    
    var filterSort: String = defaultSort
    var filterTime: String = defaultTime{
        didSet{
            setupNavigationItems()
        }
    }
    
    lazy var singleTap: UIGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(activateFilter))
        tap.delegate = self
        return tap
    }()
    
    
    var resultSearchController:UISearchController? = nil
    
    let locationManager = CLLocationManager()
    
    
// UserProfileHeader Delegate Methods
    
    func didChangeToGridView() {
        isGridView = true
        collectionView?.reloadData()
    }
    
    func didChangeToListView() {
        isGridView = false
        collectionView?.reloadData()
    }

    func didSignOut(){
        self.handleLogOut()
    }
    
    func activateSearchBar(){
        self.present(resultSearchController!, animated: true, completion: nil)
    }
    
    func activateFilter(){
        let filterController = FilterController()
        filterController.delegate = self
        filterController.selectedRange = self.filterRange
        filterController.selectedGroup = self.filterGroup
        filterController.selectedSort = self.filterSort
        filterController.selectedTime = self.filterTime
        self.navigationController?.pushViewController(filterController, animated: true)
    }
    
    func didTapPicture(post: Post){
        let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
        pictureController.selectedPost = post
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    func handlePictureTap(post: Post){
        let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
        pictureController.selectedPost = post
        navigationController?.pushViewController(pictureController, animated: true)
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
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupEmojiDetailLabel()

        collectionView?.backgroundColor = .white
        
        collectionView?.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerId")
        
        collectionView?.register(UserProfilePhotoCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: homePostCellId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        
        collectionView?.addSubview(noResultsLabel)
        
        noResultsLabel.anchor(top: collectionView?.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 200, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        noResultsLabel.isHidden = true
        
        clearFilter()
        setupSearchController()
        fetchUser()
        // Pagination happens after post ids are fetched
        IQKeyboardManager.sharedManager().enable = false
        setupLogOutButton()
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishPaginationCheck), name: UserProfileController.finishProfilePaginationNotificationName, object: nil)
        
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
    
    func setupEmojiDetailLabel(){
        view.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: topLayoutGuide.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 150, height: 25)
        emojiDetailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        emojiDetailLabel.isHidden = true
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        emojiDetailLabel.isHidden = true
    }
    
    func handleGroupOrUngroup(){
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else {return}
        
        guard let userId = user?.uid else {return}
        
        if currentLoggedInUserId == userId {return}

        if isGroup {
            
            Database.database().reference().child("group").child(currentLoggedInUserId).child(userId).removeValue(completionBlock: { (err, ref) in
                if let err = err {
                    print("Failed to ungroup user:", err)
                    return
                }
                print("Successfully group user", self.user?.username ?? "")
                self.isGroup = false
            //    self.setupFollowStyle()
                
            })
            
        }   else {
            
            let ref = Database.database().reference().child("group").child(currentLoggedInUserId)
            
            let values = [userId: 1]
            
            ref.updateChildValues(values) { (err, ref) in
                if let err = err {
                    
                    print("Failed to Group User", err)
                    return
                }
                print("Successfully Group user: ", self.user?.username ?? "")
                self.isGroup = true
                
            }
        }

    }
    
    fileprivate func setupNavigationItems() {
        
//        navigationItem.title = "Shoutaround"
//        
//        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(openSearch))
//        
//        if self.filterGroup == defaultGroup && self.filterRange == defaultRange && self.filterTime == defaultTime && self.filterGroup == "All" {
//            filterButton.image = #imageLiteral(resourceName: "blankfilter").withRenderingMode(.alwaysOriginal)
//            filterButton.backgroundColor = UIColor.clear
//        } else {
//            filterButton.image = #imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal)
//            //            filterButton.backgroundColor = UIColor.orange
//            filterButton.addGestureRecognizer(singleTap)
//        }
//        
//        let rangeBarButton = UIBarButtonItem.init(customView: filterButton)
//        navigationItem.rightBarButtonItem = rangeBarButton
        
    }
    
    // Search Delegate And Methods
    
    fileprivate func setupGroupButton() {
        guard let currentLoggedInUserID = Auth.auth().currentUser?.uid else {return}
        guard let userId = user?.uid else {return}
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "starunfill").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.handleGroupOrUngroup))
        
        if currentLoggedInUserID == userId {
            //                Edit Profile
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        }else {
            
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            
            
            // check if following
            
            Database.database().reference().child("group").child(currentLoggedInUserID).child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let isGroupVal = snapshot.value as? Int, isGroupVal == 1 {
                    self.isGroup = true
                    
                } else{
                    self.isGroup = false
                }
                
                if self.isGroup {
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "redstar").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.handleGroupOrUngroup))} else {
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "starunfill").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.handleGroupOrUngroup))
                }
                
            }, withCancel: { (err) in
                
                print("Failed to check if group", err)
                
            })
            
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        IQKeyboardManager.sharedManager().enable = true
    }
    
    // IOS9 - let refreshControl = UIRefreshControl()
    
    func handleRefresh() {
        
        // RemoveAll so that when user follow/unfollows it updates
        
        refreshPagination()
        clearFilter()
        fetchPostIds.removeAll()
        displayedPosts.removeAll()
        collectionView?.reloadData()
        fetchUser()
        self.collectionView?.refreshControl?.endRefreshing()
        print("Refresh Profile Page")
    }
    
// HomePost Cell Delegate Functions
    
    func didTapComment(post: Post) {
        
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.post = post
        
        navigationController?.pushViewController(commentsController, animated: true)
    }
    
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

    
    func refreshPost(post: Post) {
        let index = displayedPosts.index { (filteredpost) -> Bool in
        filteredpost.id  == post.id
            
    }
        let filteredindexpath = IndexPath(row:index!, section: 0)
        self.displayedPosts[index!] = post
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
            let index = self.displayedPosts.index { (filteredpost) -> Bool in
                filteredpost.id  == post.id
            }
            
            let filteredindexpath = IndexPath(row:index!, section: 0)
            self.displayedPosts.remove(at: index!)
            self.collectionView?.deleteItems(at: [filteredindexpath])
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
    
// Home Post Search Delegates
    
    func filterCaptionSelected(searchedText: String?){
        
        if searchedText == nil {
            self.handleRefresh()
        } else {
         self.filterCaption = searchedText
            self.refreshPagination()
            self.displayedPosts.removeAll()
            self.collectionView?.reloadData()
            self.paginatePosts()
        }
    }
    
    func userSelected(uid: String?){
        
    }
    
    func locationSelected(googlePlaceId: String?){
        
    }
    
// Filter Delegate
    
    func filterControllerFinished(selectedRange: String, selectedLocation: CLLocation?, selectedGooglePlaceID: String?, selectedTime: String, selectedGroup: String, selectedSort: String){
        
        self.filterRange = selectedRange
        self.filterLocation = selectedLocation
        self.filterGroup = selectedGroup
        self.filterSort = selectedSort
        self.filterTime = selectedTime
        self.refreshPagination()
        self.displayedPosts.removeAll()
        self.collectionView?.reloadData()
        
        // No Distance Filter is Selected
        
        guard let filterDistance = Double(self.filterRange) else {
            print("Invalid Distance Number or Non Distance")
            fetchPostIds.removeAll()
            displayedPosts.removeAll()
            fetchUser()
            return
        }
        
        // Distance Filter is Selected
        
        Database.fetchAllPostIDWithinLocation(selectedLocation: self.filterLocation!, distance: filterDistance) { (firebasePostIds) in
            
            let currentUserUid = Auth.auth().currentUser?.uid
            var tempPostIds = firebasePostIds
            
            // Check for User UID
            
            for (i,str) in firebasePostIds.enumerated().reversed() {
                if CurrentUser.followingUids.contains(str.creatorUID!) || str.creatorUID! == currentUserUid! {
                } else {
                    tempPostIds.remove(at: i)
                }
            }
            self.fetchPostIds = tempPostIds
            print("Geofire Filtered Posts: ", self.fetchPostIds.count)
            self.paginatePosts()
        }
        
        
    }
    
    
    
// Pagination
    
    
    var fetchPostIds: [PostId] = []
    var fetchedPostCount = 0
    var isFinishedPaging = false
    
    static let finishProfilePaginationNotificationName = NSNotification.Name(rawValue: "UserProfileFinishPagination")
    
    
    
    fileprivate func fetchUser() {
        
        // uid using userID if exist, if not, uses current user, if not uses blank
        let uid = userId ?? Auth.auth().currentUser?.uid ?? ""
        
        Database.fetchUserWithUID(uid: uid) { (user) in
            self.user = user
            self.navigationItem.title = self.user?.username
            if user.uid != Auth.auth().currentUser?.uid {
                self.setupGroupButton()
            } else {
                self.setupLogOutButton()
            }
            self.collectionView?.reloadData()
            self.paginatePosts()
        }
        
        Database.fetchAllPostIDWithCreatorUID(creatoruid: uid) { (postIds) in
            
            self.checkDisplayPostIdForDups(postIds: postIds)
            self.fetchPostIds = self.fetchPostIds + postIds
            self.fetchPostIds.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate!.compare(p2.creationDate!) == .orderedDescending
            })
            print("Current User Posts: ", self.fetchPostIds.count)
            self.paginatePosts()
            
        }
    }
    
    fileprivate func checkDisplayPostIdForDups( postIds : [PostId]){
        
        for postId in postIds {
            
            let postIdCheck = postId.id
            if let dupIndex = self.fetchPostIds.index(where: { (item) -> Bool in
                item.id == postIdCheck
            }) {
                self.fetchPostIds.remove(at: dupIndex)
                print("Deleted from fetchPostIds Dup Post ID: ", postIdCheck)
            }
        }
    }
    
    
    func clearFilter(){
        self.resultSearchController?.searchBar.text = nil
        self.filterCaption = nil
        self.filterLocation = nil
        self.filterGroup = defaultGroup
        self.filterRange = defaultRange
        self.filterSort = defaultSort
        self.filterTime = defaultTime
    }
    
    func refreshPagination(){
        self.isFinishedPaging = false
        self.fetchedPostCount = 0
    }
    
    
    func finishPaginationCheck(){
        
        if self.fetchedPostCount == (self.fetchPostIds.count) {
            print("Finished Paging")
            self.isFinishedPaging = true
        }
        
        else if self.displayedPosts.count < 1 && self.isFinishedPaging != true {
            print("No Display Pagination Check Paginate")
            self.paginatePosts()
        } else {
            DispatchQueue.main.async(execute: { self.collectionView?.reloadData() })
            
            if self.collectionView?.numberOfItems(inSection: 0) != 0 && self.displayedPosts.count < 4{
                let indexPath = IndexPath(item: 0, section: 0)
                self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                self.noResultsLabel.isHidden = true
            }
            
            else if self.collectionView?.numberOfItems(inSection: 0) == 0 {
                if self.isFinishedPaging{
                    self.noResultsLabel.isHidden = false
                    self.noResultsLabel.text = "No Results"
                    print("Finished Paging No Results")
                    self.collectionView?.scrollsToTop = true
                    self.collectionView?.reloadData()
                } else {
                    self.noResultsLabel.isHidden = false
                    self.noResultsLabel.text = "Loading"
                }
            }
            
        }
    }
    
    
    
    fileprivate func paginatePosts(){
        
        let paginateFetchPostSize = 4
        var paginateFetchPostsLimit = min(self.fetchedPostCount + paginateFetchPostSize, self.fetchPostIds.count)
        
        print("Start Paginate Loop FetchPostCount: \(self.fetchedPostCount) to \(paginateFetchPostsLimit)")
        
        
        for i in self.fetchedPostCount ..< paginateFetchPostsLimit  {

            let fetchPostId = fetchPostIds[i]

            // Filter Time
            if self.filterTime != defaultTime  {
                
                let calendar = Calendar.current
                let tagHour = Double(calendar.component(.hour, from: fetchPostId.tagTime!))
                guard let filterIndex = FilterSortTimeDefault.index(of: self.filterTime) else {return}
                
                if FilterSortTimeStart[filterIndex] > tagHour || tagHour > FilterSortTimeEnd[filterIndex] {
                    // Skip Post If not within selected time frame
                    //                    print("Skipped Post: ", fetchPostId.id, " TagHour: ",tagHour, " Start: ", FilterSortTimeStart[filterIndex]," End: ",FilterSortTimeEnd[filterIndex])
                    self.fetchedPostCount += 1
                    if self.fetchedPostCount == paginateFetchPostsLimit {
                        // End of loop functions are checked every iteration. Skipping iteration skipped the check
                        //                        print("Finish Paging @ TimeCheck")
                        NotificationCenter.default.post(name: UserProfileController.finishProfilePaginationNotificationName, object: nil)
                    }
                    continue
                }
            }
            
            // Filter Group
            
            if self.filterGroup != defaultGroup{
                if CurrentUser.groupUids.contains(fetchPostId.creatorUID!){
                } else {
                    // Skip Post if not in group
                    //                    print("Skipped Post: ", fetchPostId.id, " Creator Not in Group: ",fetchPostId.creatorUID!)
                    
                    self.fetchedPostCount += 1
                    if self.fetchedPostCount == paginateFetchPostsLimit {
                        // End of loop functions are checked every iteration. Skipping iteration skipped the check
                        //                        print("Finish Paging @ GroupCheck")
                        NotificationCenter.default.post(name: UserProfileController.finishProfilePaginationNotificationName, object: nil)
                    }
                    continue
                }
            }
            
            // Fetch Posts
            
            Database.fetchPostWithPostID(postId: fetchPostId.id, completion: { (post, error) in
                self.fetchedPostCount += 1
                
//                print("\(self.fetchedPostCount): \(post)")
                
                guard let post = post else {
                    print("No Post Returned from Fetching \(fetchPostId.id)")
                    return}
                
                var fetchedPost = post
                // Update Post with Location Distance from selected Location
                if self.filterLocation != nil {
                    fetchedPost.distance = Double((fetchedPost.locationGPS?.distance(from: self.filterLocation!))!)
                }
                
                var tempPost = [fetchedPost]
                
                if let error = error {
                    print("Failed to fetch post for: ", fetchPostId.id)
                    return
                }
                
                // Filter Caption (Only possible after grabbing post)
                
                if self.filterCaption != nil && self.filterCaption != "" {
                    guard let searchedText = self.filterCaption else {return}
                    tempPost = tempPost.filter { (post) -> Bool in
                        
                        let searchedEmoji = ReverseEmojiDictionary[searchedText.lowercased()] ?? ""
                        
                        return post.caption.lowercased().contains(searchedText.lowercased()) || post.emoji.contains(searchedText.lowercased()) || post.nonRatingEmojiTags.joined(separator: " ").lowercased().contains(searchedText.lowercased()) || post.nonRatingEmojiTags.joined(separator: " ").lowercased().contains(searchedEmoji) || post.locationName.lowercased().contains(searchedText.lowercased()) || post.locationAdress.lowercased().contains(searchedText.lowercased())
                    }
                }
                
//                if tempPost.count > 0 {print("Adding Temp Post id: ", tempPost[0].id)}
                
                self.displayedPosts += tempPost
                
//                                print("Current: ", i, "fetchedPostCount: ", self.fetchedPostCount, "Total: ", self.fetchPostIds.count, "Display: ", self.displayedPosts.count, "finished: ", self.isFinishedPaging, "paginate:", paginateFetchPostsLimit)
                
                if self.fetchedPostCount == paginateFetchPostsLimit {
                    
                    //                print("Finish Paging")
                    NotificationCenter.default.post(name: UserProfileController.finishProfilePaginationNotificationName, object: nil)
                    
                }
            })
            
        }
    }
    
    fileprivate func fetchOrderedPosts() {
        
        guard let uid = self.user?.uid  else {return}
        
        let ref = Database.database().reference().child("posts").child(uid)
        
        // Might add pagination later
        ref.queryOrdered(byChild: "creationDate").observe(.childAdded, with: { (snapshot) in

            guard let dictionary = snapshot.value as? [String:Any] else {return}
            guard let user = self.user else {return}
            
            let post = Post(user: user, dictionary: dictionary)

//            Helps insert new photos at the front
            self.displayedPosts.insert(post, at: 0)
//            self.posts.append(post)

            self.collectionView?.reloadData()
            
        }) { (err) in
            
            print("Failed to fetch ordered posts:", err)
        }
        
    }
    
      
    fileprivate func setupLogOutButton() {
        if user?.uid == Auth.auth().currentUser?.uid {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "signout").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleLogOut))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "starunfill").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.handleGroupOrUngroup))
        }
    }


    func handleLogOut() {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (_) in
            
            do {
                try Auth.auth().signOut()
                let manager = FBSDKLoginManager()
                try manager.logOut()
                let loginController = LoginController()
                let navController = UINavigationController( rootViewController: loginController)
                self.present(navController, animated: true, completion: nil)
                
            } catch let signOutErr {
                print("Failed to sign out:", signOutErr)
            }

        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    
        present(alertController, animated: true, completion: nil)
    
    }
    
    
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedPosts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
//        print("collectionview post count", self.allPosts.count)
//        print("isfinishedpaging",self.isFinishedPaging)
//        print(indexPath.item)
        if indexPath.item == self.displayedPosts.count - 1 && !isFinishedPaging{
            
            paginatePosts()
        }
        
        
        if isGridView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! UserProfilePhotoCell
            cell.post = displayedPosts[indexPath.item]
            cell.delegate = self
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: homePostCellId, for: indexPath) as! HomePostCell
            cell.enableDelete = true
            cell.post = displayedPosts[indexPath.item]
            cell.delegate = self
            return cell
        }
    

        

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ cofllectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if isGridView {
        let width = (view.frame.width - 2) / 3
            return CGSize(width: width, height: width)
        } else {
            var height: CGFloat = 40 + 8 + 8 //username userprofileimageview
            height += view.frame.width
            height += 50
            height += 60
            
            return CGSize(width: view.frame.width, height: height)
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerId", for: indexPath) as! UserProfileHeader
        
        header.user = self.user
        header.delegate = self
        header.defaultSearchBar.text = self.filterCaption
        if self.filterGroup == defaultGroup && self.filterRange == defaultRange && self.filterTime == defaultTime && self.filterSort == defaultSort {
            header.isFiltering = false
        } else {
            header.isFiltering = true
        }
        
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 200)
    }
    

    
}


