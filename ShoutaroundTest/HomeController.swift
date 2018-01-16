//
//  HomeController.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import Firebase
import mailgun
import GeoFire
import CoreGraphics
import CoreLocation
import EmptyDataSet_Swift



class HomeController: UICollectionViewController, UICollectionViewDelegateFlowLayout, HomePostCellDelegate, HomePostSearchDelegate, UIGestureRecognizerDelegate, FilterControllerDelegate, UISearchBarDelegate, SortFilterHeaderDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SharePhotoListControllerDelegate, PostSearchControllerDelegate, EmptyDataSource, EmptyDataSetDelegate  {
    
    let cellId = "cellId"
    var scrolltoFirst: Bool = false
    
    var fetchedPostIds: [PostId] = []
    var fetchedPosts: [Post] = []
    var displayedPostsCount: Int = 0

// Pagination Variables
    
    var userPostIdFetched = false
    var followingPostIdFetched = false
    
    var isFinishedPaging = false {
        didSet{
            if isFinishedPaging == true {
                print("Finished Paging :", self.displayedPostsCount)
            }
        }
    }
    
    static let refreshPostsNotificationName = NSNotification.Name(rawValue: "RefreshPosts")
    static let finishFetchingUserPostIdsNotificationName = NSNotification.Name(rawValue: "FinishFetchingUserPostIds")
    static let finishFetchingFollowingPostIdsNotificationName = NSNotification.Name(rawValue: "FinishFetchingFollowingPostIds")
    static let finishSortingFetchedPostsNotificationName = NSNotification.Name(rawValue: "FinishSortingFetchedPosts")
    static let finishPaginationNotificationName = NSNotification.Name(rawValue: "FinishPagination")
    
    
    // Geo Filter Variables
    
    let geoFilterRange = geoFilterRangeDefault
    let geoFilterImage:[UIImage] = geoFilterImageDefault
    
    
// Filter Variables
    
    var isFiltering: Bool = false
    
    var filterCaption: String? = nil{
        didSet{
        }
    }
    
    
    var filterRange: String? = nil {
        didSet{
            setupNavigationItems()
        }
    }
    
    var filterLocation: CLLocation? = nil{
        didSet{
            self.updatePostDistances(refLocation: filterLocation){}
            if filterLocation == nil {
                self.filterLocationName = nil
            } else if filterLocation == CurrentUser.currentLocation{
                self.filterLocationName = "Current Location"
            }
        }
    }
    var filterLocationName: String? = nil
    

    
    var filterGoogleLocationID: String? = nil {
        didSet{
            
        }
    }

    
    var filterMinRating: Double = 0 {
        didSet{
            
        }
    }
        
    var filterType: String? = nil{
        didSet{
            setupNavigationItems()
        }
    }
    
    var filterMaxPrice: String? = nil{
        didSet{
            setupNavigationItems()
        }
    }
    
    // Header Sort Variables
    var selectedHeaderSort = HeaderSortDefault
    
    
    
    var filterButton: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        view.image = #imageLiteral(resourceName: "search_blank").withRenderingMode(.alwaysOriginal)
        view.contentMode = .scaleAspectFit
        view.sizeToFit()
//        view.layer.cornerRadius = 25/2
//        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    lazy var singleTap: UIGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(openFilter))
        tap.delegate = self
        return tap
    }()

    
    var defaultSearchBar = UISearchBar()

    override func viewDidLayoutSubviews() {
                
//        let filterBarHeight = (self.filterBar.isHidden == false) ? self.filterBar.frame.height : 0
//        
//        let topinset = (self.navigationController?.navigationBar.frame.size.height)! + UIApplication.shared.statusBarFrame.height + filterBarHeight
//        collectionView?.frame = CGRect(x: 0, y: topinset, width: view.frame.width, height: view.frame.height - topinset - (self.tabBarController?.tabBar.frame.size.height)!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
        
//        self.automaticallyAdjustsScrollViewInsets = false

        
        //    1. Fetch All Post Ids to fetchedPostIds
        //    2. Fetch All Posts to fetchedPosts
        //    3. Filter displayedPosts based on Conditions/Sorting (All Fetched Posts are saved to cache anyways)
        //    4. Control Pagination by increasing displayedPostsCount to fetchedpostCount
        
        
// 1.  Checks if Both User and Following Post Ids are colelctved before proceeding
        NotificationCenter.default.addObserver(self, selector: #selector(finishFetchingPostIds), name: HomeController.finishFetchingUserPostIdsNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(finishFetchingPostIds), name: HomeController.finishFetchingFollowingPostIdsNotificationName, object: nil)

// 2.  Fetches all Posts and Filters/Sorts

// 3. Paginates Post by increasing displayedPostCount after Filtering and Sorting
        NotificationCenter.default.addObserver(self, selector: #selector(paginatePosts), name: HomeController.finishSortingFetchedPostsNotificationName, object: nil)
        
// 4. Checks after pagination Ends
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishPaginationCheck), name: HomeController.finishPaginationNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: SharePhotoListController.updateFeedNotificationName, object: nil)

        view.addSubview(noResultsLabel)
        noResultsLabel.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        collectionView?.backgroundColor = .white
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView?.register(SortFilterHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerId")
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: HomeController.refreshPostsNotificationName, object: nil)


// 1. Clear out all Filters, Fetched Post Ids and Pagination Variables
        self.refreshAll()
        
// 2. Fetch All Relevant Post Ids, then pull in all Post information to fetchedPosts
        fetchAllPostIds()
        self.scrolltoFirst = false
        
        setupNavigationItems()
        setupEmojiDetailLabel()
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
        

        for cell in (collectionView?.visibleCells)! {
            let tempCell = cell as! HomePostCell
            tempCell.hideCaptionBubble()
        }
        
        
    }
    
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
// Setup for Geo Range Button, Dummy TextView and UIPicker
    
    var noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = UIColor.black
        label.isHidden = true
        label.textAlignment = NSTextAlignment.center
        return label
    }()

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.openSearch()
        return false
    }
    

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.length == 0) {
            self.filterCaption = nil
            self.refreshPostsForFilter()
            searchBar.endEditing(true)
        }
    }
    

    
    func openSearch(){

        let postSearch = PostSearchController()
        postSearch.delegate = self
        self.navigationController?.pushViewController(postSearch, animated: true)
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
        filterController.selectedLocation = self.filterLocation
        filterController.selectedLocationName = self.filterLocationName

        filterController.selectedSort = self.selectedHeaderSort
        
        self.navigationController?.pushViewController(filterController, animated: true)
    }

// Sort Delegate
    
    func headerSortSelected(sort: String) {
        self.selectedHeaderSort = sort
        
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
        
        // Refresh Everything
        self.refreshPagination()
        self.collectionView?.reloadData()
        
        self.refreshPostsForFilter()
        self.scrolltoFirst = true
        
        // Check for filtering
        self.checkFilter()
        
        if filterCaption != nil {
            defaultSearchBar.text = self.filterCaption ?? ""
        }
        
        if self.filterLocationName != nil {
            defaultSearchBar.text = defaultSearchBar.text! + " @ " + self.filterLocationName!
        }
        
        if self.filterMinRating != nil {
//            defaultSearchBar.text = defaultSearchBar.text! + " @ " + String(self.filterMinRating)
        }
        
        if self.filterType != nil {
            defaultSearchBar.text = defaultSearchBar.text! + " @ " + self.filterType!
        }
        
        if self.filterMaxPrice != nil {
            defaultSearchBar.text = defaultSearchBar.text! + " @ " + self.filterMaxPrice!
        }
        
        
        
        
    }
    
    func checkFilter(){
        if self.filterCaption != nil || (self.filterRange != nil) || (self.filterMinRating != 0) || (self.filterType != nil) || (self.filterMaxPrice != nil) {
            self.isFiltering = true
        } else {
            self.isFiltering = false
        }
    }

    // Home Post Search Delegates
    
    func filterCaptionSelected(searchedText: String?){
        
        if searchedText == nil {
            self.handleRefresh()

        } else {
            print("Searching for \(searchedText)")
            defaultSearchBar.text = searchedText!
            self.filterCaption = searchedText
            self.refreshPagination()
            self.collectionView?.reloadData()
            self.scrolltoFirst = true
            self.fetchAllPosts()
        }
    }
    
    func userSelected(uid: String?){
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.userId = uid
        self.navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func locationSelected(googlePlaceId: String?){
        let locationController = LocationController()
        locationController.googlePlaceId = googlePlaceId
        navigationController?.pushViewController(locationController, animated: true)
    }
    
    
    
// Handle Refresh/Update
    
    func clearPostIds(){
        self.fetchedPostIds.removeAll()
    }
    
    func clearAllPosts(){
        self.fetchedPostIds.removeAll()
        self.fetchedPosts.removeAll()
        self.refreshPagination()
    }
    
    func clearSort(){
        self.selectedHeaderSort = defaultSort
    }
    
    func clearSearch(){
        self.defaultSearchBar.text?.removeAll()
        self.filterCaption = nil
    }
    
    func clearFilter(){
        self.filterLocation = nil
        self.filterLocationName = nil
        self.filterRange = nil
        self.filterGoogleLocationID = nil
        self.filterMinRating = 0
        self.filterType = nil
        self.filterMaxPrice = nil
        self.selectedHeaderSort = defaultSort
        self.isFiltering = false
    }
    
    func refreshPagination(){
        self.isFinishedPaging = false
        self.displayedPostsCount = 0
        self.userPostIdFetched = false
        self.followingPostIdFetched = false
    }
    
    func refreshAll(){
        self.clearSearch()
        self.clearFilter()
        self.clearSort()
        self.clearPostIds()
        self.refreshPagination()
        self.collectionView?.reloadData()
    }
    
    func refreshPosts(){
        self.clearAllPosts()
    }
    
    func refreshPostsForFilter(){
        self.clearAllPosts()
        self.collectionView?.reloadData()
        self.fetchAllPostIds()
    }
    

    func handleUpdateFeed() {
        
        // Check for new post that was edited or uploaded
        if newPost != nil && newPostId != nil {
            self.fetchedPosts.insert(newPost!, at: 0)
            self.fetchedPostIds.insert(newPostId!, at: 0)
            
            newPost = nil
            newPostId = nil
            
            self.collectionView?.reloadData()
            if self.collectionView?.numberOfItems(inSection: 0) != 0 {
                let indexPath = IndexPath(item: 0, section: 0)
                self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
            }
            print("Pull in new post")

        } else {
            self.handleRefresh()
        }
    }
    
    func handleRefresh() {
        self.refreshAll()
        fetchAllPostIds()
        self.collectionView?.refreshControl?.endRefreshing()
        print("Refresh Home Feed. FetchPostIds: ", self.fetchedPostIds.count, "FetchedPostCounr: ", self.fetchedPosts.count, " DisplayedPost: ", self.displayedPostsCount)
    }

// Post ID Fetching
    fileprivate func fetchAllPostIds(){
        fetchUserPostIds()
        fetchFollowingUserPostIds()
    }
    
    
    fileprivate func fetchUserPostIds(){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}

        Database.fetchUserWithUID(uid: uid) { (user) in
            CurrentUser.username = user.username
            CurrentUser.profileImageUrl = user.profileImageUrl
            CurrentUser.uid = uid
            CurrentUser.status = user.status
            CurrentUser.user = user
        }
        
        Database.fetchAllPostIDWithCreatorUID(creatoruid: uid) { (postIds) in
            self.checkDisplayPostIdForDups(postIds: postIds)
            self.fetchedPostIds = self.fetchedPostIds + postIds
            self.fetchedPostIds.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate!.compare(p2.creationDate!) == .orderedDescending
            })
            print("Current User Posts: ", self.fetchedPostIds.count)
            self.userPostIdFetched = true
            NotificationCenter.default.post(name: HomeController.finishFetchingUserPostIdsNotificationName, object: nil)
        }
    }

    
    fileprivate func fetchFollowingUserPostIds(){
        
        let thisGroup = DispatchGroup()
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        Database.fetchFollowingUserUids(uid: uid) { (fetchedFollowingUsers) in
            
            CurrentUser.followingUids = fetchedFollowingUsers
            thisGroup.enter()
            for userId in fetchedFollowingUsers {
                thisGroup.enter()
                Database.fetchAllPostIDWithCreatorUID(creatoruid: userId) { (postIds) in
                    
                    self.checkDisplayPostIdForDups(postIds: postIds)
                    self.fetchedPostIds = self.fetchedPostIds + postIds
                    self.fetchedPostIds.sort(by: { (p1, p2) -> Bool in
                        return p1.creationDate!.compare(p2.creationDate!) == .orderedDescending
                    })
                    thisGroup.leave()
                }
            }
            thisGroup.leave()
            
            thisGroup.notify(queue: .main) {
                print("Current User And Following Posts: ", self.fetchedPostIds.count)
                print("Number of Following: ",CurrentUser.followingUids.count)
                self.followingPostIdFetched = true
                NotificationCenter.default.post(name: HomeController.finishFetchingFollowingPostIdsNotificationName, object: nil)
            }
        }
    }
    
    
    
    fileprivate func checkDisplayPostIdForDups( postIds : [PostId]){
        
        for postId in postIds {
            
            let postIdCheck = postId.id
            if let dupIndex = self.fetchedPostIds.index(where: { (item) -> Bool in
                item.id == postIdCheck
            }) {
                self.fetchedPostIds.remove(at: dupIndex)
                print("Deleted from fetchPostIds Dup Post ID: ", postIdCheck)
            }
        }
    }

    
// Pagination
    
    func finishPaginationCheck(){
        
        print("Finish Paging Check")
        
        if self.displayedPostsCount == (self.fetchedPosts.count) {
            self.isFinishedPaging = true
        }
        
        if self.fetchedPosts.count == 0 && self.isFinishedPaging == true {
            print("Finish Pagination Check: No Results")
            self.noResultsLabel.text = "No Results"
            self.noResultsLabel.isHidden = false
        }
        else if self.fetchedPosts.count == 0 && self.isFinishedPaging != true {
            print("Finish Pagination Check: No Results, Still Paging")
            self.noResultsLabel.text = "Loading"
            self.noResultsLabel.isHidden = false
            self.paginatePosts()
        } else {
            print("Finish Pagination Check: Success, Post: \(self.fetchedPosts.count)")
            DispatchQueue.main.async(execute: { self.collectionView?.reloadData()
            
                self.noResultsLabel.isHidden = true
                
                // Scrolling for refreshed results
                if self.scrolltoFirst && self.fetchedPosts.count > 1{
                    print("Refresh Control Status: ", self.collectionView?.refreshControl?.state)
                    self.collectionView?.refreshControl?.endRefreshing()
                    let indexPath = IndexPath(item: 0, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
//                    self.collectionView?.setContentOffset(CGPoint(x: 0, y: 0 - self.topLayoutGuide.length), animated: true)
                    print("Scrolled to Top")
                    self.scrolltoFirst = false
                    
                }
            
            })
        }
    }
    
    func finishFetchingPostIds(){
        
        // Function is called after User Post are called AND following user post ids are called. So need to check that all post are picked up before refresh
        print("User PostIds Fetched: \(self.userPostIdFetched), Following PostIds Fetched: \(self.followingPostIdFetched)")
        
        if self.userPostIdFetched && self.followingPostIdFetched {
            print("Finish Fetching Post Ids: \(fetchedPostIds.count)")
            self.fetchAllPosts()
        } else {
            print("Wait for user/following user post ids to be fetched")
        }
    }
    
    func fetchAllPosts(){
        print("Fetching All Post, Current User Location: ", CurrentUser.currentLocation)
        Database.fetchAllPosts(fetchedPostIds: self.fetchedPostIds){fetchedPostsFirebase in
            self.fetchedPosts = fetchedPostsFirebase
            // Update Post Distances
            self.updatePostDistances(refLocation: self.filterLocation, completion: {
                self.filterSortFetchedPosts()
            })
        }
    }
    
    func filterSortFetchedPosts(){
        
    // Filter Posts
        Database.filterPosts(inputPosts: self.fetchedPosts, filterCaption: self.filterCaption, filterRange: self.filterRange, filterLocation: self.filterLocation, filterMinRating: self.filterMinRating, filterType: self.filterType, filterMaxPrice: self.filterMaxPrice) { (filteredPosts) in
            
    // Sort Posts
            Database.sortPosts(inputPosts: filteredPosts, selectedSort: self.selectedHeaderSort, selectedLocation: self.filterLocation, completion: { (filteredPosts) in
                
                self.fetchedPosts = []
                if filteredPosts != nil {
                    self.fetchedPosts = filteredPosts!
                }
                    print("Finish Filter and Sorting Post")
                    NotificationCenter.default.post(name: HomeController.finishSortingFetchedPostsNotificationName, object: nil)
            })
        }
    }
    
    
    func paginatePosts(){

        let paginateFetchPostSize = 4

        self.displayedPostsCount = min(self.displayedPostsCount + paginateFetchPostSize, self.fetchedPosts.count)
        print("Home Paginate \(self.displayedPostsCount) : \(self.fetchedPosts.count)")

        NotificationCenter.default.post(name: HomeController.finishPaginationNotificationName, object: nil)
    }
    
    
    fileprivate func fetchGroupUserIds() {
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        Database.database().reference().child("group").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let userIdsDictionary = snapshot.value as? [String: Any] else {return}
            var groupUsers: [String] = []
            
            userIdsDictionary.forEach({ (key,value) in
                groupUsers.append(key)
            })
            CurrentUser.groupUids = groupUsers
            
        }) { (err) in
            print("Failed to fetch group user ids:", err)
        }
    }
    
    
    fileprivate func setupNavigationItems() {
        
        navigationItem.titleView = defaultSearchBar
        defaultSearchBar.delegate = self
        defaultSearchBar.placeholder = "Food, User, Location"
        
        // Camera
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "camera3").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(openCamera))
        
        // Inbox
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "mailbox").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(openInbox))
        
    }

    
    func openInbox() {
        let inboxController = InboxController(collectionViewLayout: UICollectionViewFlowLayout())
        navigationController?.pushViewController(inboxController, animated: true)
    }



    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 40 + 8 + 8 //username userprofileimageview
        height += view.frame.width  // Picture
        height += 25    // Location View
        height += 40    // Action Bar
        height += 25    // Extra Tag Bar
        height += 30    // Date Bar

        
////        height += 20    // Social Counts
////        height += 20    // Caption
        
        return CGSize(width: view.frame.width, height: height)
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
//        return min(4, self.displayedPostsCount)
        return displayedPostsCount
//        return displayedPosts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
//        if indexPath.item == self.displayedPosts.count - 1 && !isFinishedPaging{
//            print("CollectionView Paginate")
//            paginatePosts()
//        }
        
        if indexPath.item == self.displayedPostsCount - 1 && !isFinishedPaging{
            print("CollectionView Paginate")
            paginatePosts()
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! HomePostCell
//        cell.post = displayedPosts[indexPath.item]
        cell.post = fetchedPosts[indexPath.item]

        
        if self.filterLocation != nil {
            cell.post?.distance = Double((cell.post?.locationGPS?.distance(from: self.filterLocation!))!)
        }
        
        cell.delegate = self
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //print(displayedPosts[indexPath.item])
    }
    
// SORT FILTER HEADER
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerId", for: indexPath) as! SortFilterHeader
        header.isFiltering = self.isFiltering
        header.delegate = self
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 40 + 5)
    }
    
    
    
    
    
// HOME POST CELL DELEGATE METHODS
    
    func didTapBookmark(post: Post) {
        
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = post
        sharePhotoListController.isBookmarkingPost = true
        sharePhotoListController.delegate = self
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
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
    
    func didTapExtraTag(tagName: String, tagId: String, post: Post) {
        
        // Check to see if its a list, price or something else
        if tagId == "price"{
            // Price Tag Selected
            print("Price Selected")
            self.filterMaxPrice = tagName
            self.refreshPostsForFilter()
        }
        else if tagId == "creatorLists"{
            // Additional Tags
            let listController  = ListController()
            listController.displayedPost = post
            listController.displayedListNameDictionary = post.creatorListId
            self.navigationController?.pushViewController(listController, animated: true)
        }
        else if tagId == "userLists"{
            // Additional Tags
            let listController  = ListController()
            listController.displayedPost = post
            listController.displayedListNameDictionary = post.selectedListId
            self.navigationController?.pushViewController(listController, animated: true)
        }
        else {
            // List Tag Selected
            Database.checkUpdateListDetailsWithPost(listName: tagName, listId: tagId, post: post, completion: { (fetchedList) in
                if fetchedList == nil {
                    // List Does not Exist
                    self.alert(title: "List Error", message: "List Does Not Exist Anymore")
                } else {
                    let listViewController = ListViewController()
                    listViewController.displayListId = tagId
                    listViewController.displayList = fetchedList
                    self.navigationController?.pushViewController(listViewController, animated: true)
                }
            })
        }
    }
    
    func refreshPost(post: Post) {
        let index = fetchedPosts.index { (filteredpost) -> Bool in
            filteredpost.id  == post.id
        }
        print("Refreshing Post @ \(index) for post \(post.id)")
        let filteredindexpath = IndexPath(row:index!, section: 0)
        
        self.fetchedPosts[index!] = post
        self.collectionView?.reloadItems(at: [filteredindexpath])
        
        // Update Cache
        postCache.removeValue(forKey: post.id!)
        postCache[post.id!] = post
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
        
        present(optionsAlert, animated: true) {
            optionsAlert.view.superview?.isUserInteractionEnabled = true
            optionsAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:))))
            
        }
        
    }
    

    func editPost(post:Post){
        let editPost = SharePhotoController()
        
        // Post Edit Inputs
        editPost.editPostInd = true
        editPost.editPost = post
        
        let navController = UINavigationController(rootViewController: editPost)
        self.present(navController, animated: false, completion: nil)
    }
    
    
    func deletePost(post:Post){
        
        let deleteAlert = UIAlertController(title: "Delete", message: "All data will be lost.", preferredStyle: UIAlertControllerStyle.alert)
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            
            // Remove from Current View
            let index = self.fetchedPosts.index { (filteredpost) -> Bool in
                filteredpost.id  == post.id
            }
            
            let filteredindexpath = IndexPath(row:index!, section: 0)
            self.fetchedPosts.remove(at: index!)
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
    
    
//// LOCATION MANAGER DELEGATE METHODS
//
//    func determineCurrentLocation(){
//
//        CurrentUser.currentLocation = nil
//
//        if CLLocationManager.locationServicesEnabled() {
//            locationManager.startUpdatingLocation()
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        let userLocation:CLLocation = locations[0] as CLLocation
//
//        if userLocation != nil {
//            print("Current User Location", userLocation)
//            CurrentUser.currentLocation = userLocation
//            self.filterLocation = CurrentUser.currentLocation
//            manager.stopUpdatingLocation()
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("GPS Location Not Found")
//    }
    
    func updatePostDistances(refLocation: CLLocation?, completion:() -> ()){
        if let refLocation = refLocation {
            let count = fetchedPosts.count
            for i in 0 ..< count {
                var tempPost = fetchedPosts[i]
                tempPost.distance = Double((tempPost.locationGPS?.distance(from: refLocation))!)
                fetchedPosts[i] = tempPost
            }
            completion()
        } else {
            print("No Filter Location")
            completion()
        }
    }
    
    // Camera Functions
    func openCamera(){
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            var imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)

            // Detect Current Location for Photo
            LocationSingleton.sharedInstance.determineCurrentLocation()

        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true) {
            let image = info[UIImagePickerControllerEditedImage] as! UIImage

            let sharePhotoController = SharePhotoController()
            sharePhotoController.selectedImage = image
            sharePhotoController.selectedImageLocation  = CurrentUser.currentLocation
            sharePhotoController.selectedImageTime  = Date()
            let navController = UINavigationController(rootViewController: sharePhotoController)
            self.present(navController, animated: false, completion: nil)
            print("Upload Picture")
        }
    }
    
}






