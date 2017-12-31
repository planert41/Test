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


class HomeController: UICollectionViewController, UICollectionViewDelegateFlowLayout, HomePostCellDelegate, CLLocationManagerDelegate, UISearchControllerDelegate, HomePostSearchDelegate, UIGestureRecognizerDelegate, FilterControllerDelegate, UISearchBarDelegate, SortFilterHeaderDelegate  {
    
    let cellId = "cellId"
    var scrolltoFirst: Bool = false
    
//    1. Fetch All Post Ids to fetchedPostIds
//    2. Fetch All Posts to fetchedPosts
//    3. Filter Posts based on Conditions/Sorting to displayedPosts
//    4. Control Pagination by increasing count of posts to max
    
    
    var fetchedPostIds: [PostId] = [] {
        didSet{
        }
    }
    
    var fetchedPosts: [Post] = [] {
        didSet{
            
        }
    }
    
    var displayedPostsCount: Int = 0
    
    var displayedPosts = [Post](){
        didSet{
            if displayedPosts.count == 0 {
                // Won't need to scroll if 0 results as it will default to the top
//                self.scrolltoFirst = false
//                self.collectionView?.setContentOffset(CGPoint.zero, animated: true)
                
                if self.isFinishedPaging {
                    self.noResultsLabel.text = "No Results"
                } else {
                    self.noResultsLabel.text = "Loading"
                }
                self.noResultsLabel.isHidden = false
            } else {
                self.noResultsLabel.isHidden = true
                self.noResultsLabel.text = "Loading"
            }
            
        }
    }

// Header Sort Variables
    var currentHeaderSort = HeaderSortDefault
    
    
// Geo Filter Variables
    
    let geoFilterRange = geoFilterRangeDefault
    let geoFilterImage:[UIImage] = geoFilterImageDefault
    
// Pagination Variables
    
    var userPostIdFetched = false
    var followingPostIdFetched = false
    
    var isFinishedPaging = false {
        didSet{
            if isFinishedPaging == true {
                print("Finished Paging :", self.fetchedPostCount)
            }
        }
    }
    var fetchedPostCount = 0
    
    static let finishFetchingUserPostIdsNotificationName = NSNotification.Name(rawValue: "FinishFetchingUserPostIds")
    static let finishFetchingFollowingPostIdsNotificationName = NSNotification.Name(rawValue: "FinishFetchingFollowingPostIds")
    static let finishSortingFetchedPostsNotificationName = NSNotification.Name(rawValue: "FinishSortingFetchedPosts")
    static let finishPaginationNotificationName = NSNotification.Name(rawValue: "FinishPagination")
    
    
// Filter Variables
    
    var filterCaption: String? = nil{
        didSet{

        }
    }
    var filterLocation: CLLocation? = nil{
        didSet{
            if let filterLocation = filterLocation {
                let count = fetchedPosts.count
                for i in 0 ..< count {
                    var tempPost = fetchedPosts[i]
                    tempPost.distance = Double((tempPost.locationGPS?.distance(from: filterLocation))!)
                    fetchedPosts[i] = tempPost
                }
            } else {
                print("No Filter Location")
            }
        }
    }
    
    
    
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
    
    
    var filterButton: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        view.image = #imageLiteral(resourceName: "blankfilter").withRenderingMode(.alwaysOriginal)
        view.contentMode = .scaleAspectFit
        view.sizeToFit()
//        view.layer.cornerRadius = 25/2
//        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    lazy var singleTap: UIGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(activateFilter))
        tap.delegate = self
        return tap
    }()

    
    var resultSearchController:UISearchController? = nil
    var defaultSearchBar = UISearchBar()

    let locationManager = CLLocationManager()

    override func viewDidLayoutSubviews() {
                
//        let filterBarHeight = (self.filterBar.isHidden == false) ? self.filterBar.frame.height : 0
//        
//        let topinset = (self.navigationController?.navigationBar.frame.size.height)! + UIApplication.shared.statusBarFrame.height + filterBarHeight
//        collectionView?.frame = CGRect(x: 0, y: topinset, width: view.frame.width, height: view.frame.height - topinset - (self.tabBarController?.tabBar.frame.size.height)!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        self.updateFirebaseData()
//          self.reverseEmoji()
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
        
//        self.automaticallyAdjustsScrollViewInsets = false

        NotificationCenter.default.addObserver(self, selector: #selector(finishFetchingPostIds), name: HomeController.finishFetchingUserPostIdsNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishFetchingPostIds), name: HomeController.finishFetchingFollowingPostIdsNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(paginatePosts), name: HomeController.finishSortingFetchedPostsNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishPaginationCheck), name: HomeController.finishPaginationNotificationName, object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: SharePhotoListController.updateFeedNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeedWithFilter), name: FilterController.updateFeedWithFilterNotificationName, object: nil)
        

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
        
        
// Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
// For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }


// 1. Clear out all Filters and Pagination Variables
        self.refreshAll()
        
// 2. Fetch All Relevant Post Ids, then pull in all Post information to fetchedPosts
        fetchAllPostIds()
        
// Post Ids are fetched, then fetches all posts, then sorts/filters, then paginates and displays
        
//        fetchGroupUserIds()
        self.scrolltoFirst = false
        
        // Search Controller
        setupSearchController()
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
    }
    
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    func clearPostIds(){
        self.fetchedPostIds.removeAll()
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
    
    
    func setupSearchController() {
        let homePostSearchResults = HomePostSearch()
        homePostSearchResults.delegate = self
        resultSearchController = UISearchController(searchResultsController: homePostSearchResults)
        resultSearchController?.searchResultsUpdater = homePostSearchResults
        resultSearchController?.delegate = self
        
        let searchBar = resultSearchController?.searchBar
        searchBar?.backgroundColor = UIColor.white
        searchBar?.scopeButtonTitles = searchScopeButtons
        searchBar?.placeholder =  searchBarPlaceholderText
        searchBar?.delegate = homePostSearchResults
        searchBar?.showsScopeBar = true
        
        resultSearchController?.hidesNavigationBarDuringPresentation = true
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
    }
    
    
    func openSearch(){
        
        self.present(resultSearchController!, animated: true, completion: nil)
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

// Sort Delegate
    
    func headerSortSelected(sort: String) {
        self.currentHeaderSort = sort
        self.refreshPagination()
        self.collectionView?.reloadData()
        self.filterSortFetchedPosts()
        print("Filter Sort is ", self.currentHeaderSort)
    }
    
    
// Search Delegates
    
    func filterControllerFinished(selectedRange: String, selectedLocation: CLLocation?, selectedGooglePlaceID: String?, selectedTime: String, selectedGroup: String, selectedSort: String){
        
        self.filterRange = selectedRange
        self.filterLocation = selectedLocation
        self.filterGroup = selectedGroup
        self.filterSort = selectedSort
        self.filterTime = selectedTime
        self.refreshPagination()
        self.collectionView?.reloadData()
        self.filterSortFetchedPosts()
        self.scrolltoFirst = true
//        self.collectionView?.refreshControl?.endRefreshing()
//        self.collectionView?.setContentOffset(CGPoint.zero, animated: true)
        
        
        self.displayedPosts.removeAll()
        self.collectionView?.reloadData()
    
        // No Distance Filter is Selected
        
        guard let filterDistance = Double(self.filterRange) else {
                    print("Invalid Distance Number or Non Distance")
                    self.clearPostIds()
                    self.fetchAllPostIds()
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
            self.fetchedPostIds = tempPostIds
            
            self.sortFetchPostIds()
            print("Geofire Filtered Posts: ", self.fetchedPostIds.count)
            self.paginatePosts()
        }
        
    }
    
    func sortFetchPostIds(){
        if self.filterSort == FilterSortDefault[1] {
            // Oldest
            self.fetchedPostIds.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate!.compare(p2.creationDate!) == .orderedAscending
            })
        } else if self.filterSort == FilterSortDefault[0] {
            // Nearest
            self.fetchedPostIds.sort(by: { (p1, p2) -> Bool in
                return (p1.distance! < p2.distance!)
            })
        } else {
            //Latest
            self.fetchedPostIds.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate!.compare(p2.creationDate!) == .orderedDescending
        })
        }
    }
    

    
    func sortDisplayedPosts(){
        if self.displayedPosts.count > 1 {
//            print(self.displayedPosts)
            
        if self.filterSort == FilterSortDefault[0] {
            // Oldest
            self.displayedPosts.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedAscending
            })
        } else if self.filterSort == FilterSortDefault[1] {
            // Nearest
            self.displayedPosts.sort(by: { (p1, p2) -> Bool in
                return (p1.distance! < p2.distance!)
            })
        } else if self.filterSort == FilterSortDefault[2] {
            //Latest
            self.displayedPosts.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
            })
        } else {
            print("Header Sort: ERROR, Not Valid Filter Sort")
        }
        } else {
            print("0 Display Post when filtering")
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
            self.resultSearchController?.searchBar.text = searchedText
            self.refreshPagination()
            self.displayedPosts.removeAll()
            self.scrolltoFirst = true
//            self.collectionView?.refreshControl?.endRefreshing()
//            self.collectionView?.setContentOffset(CGPoint.zero, animated: true)
            self.collectionView?.reloadData()
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
    
    
    
// Handle Update
    
    
    func refreshAll(){
        self.clearFilter()
        self.refreshPagination()
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
        self.displayedPostsCount = 0
        self.userPostIdFetched = false
        self.followingPostIdFetched = false
    }
    
    func handleUpdateFeed() {
        
        // Check for new post that was edited or uploaded
        if newPost != nil && newPostId != nil {
            self.displayedPosts.insert(newPost!, at: 0)
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
    
    func handleUpdateFeedWithFilter() {
        displayedPosts.removeAll()
        self.collectionView?.reloadData()
        self.paginatePosts()
        print("Refresh Home Feed With Filter")
        
    }
    
    func handleRefresh() {
        
        // RemoveAll so that when user follow/unfollows it updates
//        navigationItem.title = "Shoutaround"
        defaultSearchBar.text?.removeAll()
        refreshPagination()
        clearFilter()
        fetchedPostIds.removeAll()
        displayedPosts.removeAll()
        self.collectionView?.reloadData()
        fetchAllPostIds()
        self.collectionView?.refreshControl?.endRefreshing()
        print("Refresh Home Feed. FetchPostIds: ", self.fetchedPostIds.count, " DisplayedPost: ", self.displayedPosts.count)
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
        
        if self.fetchedPostCount == (self.fetchedPostIds.count) {
            self.isFinishedPaging = true
        }
        
        if self.displayedPosts.count == 0 && self.isFinishedPaging == true {
            print("No Results Pagination Finished")
            self.noResultsLabel.text = "No Results"
            self.noResultsLabel.isHidden = false
        }
        else if self.displayedPosts.count == 0 && self.isFinishedPaging != true {
            print("No Display Pagination Check Paginate")
            self.noResultsLabel.text = "Loading"
            self.noResultsLabel.isHidden = false
            self.paginatePosts()
        } else {
            
            // Sort Displayed Post - Firebase does not return post in order
            self.sortDisplayedPosts()
            print("Refreshing CollectionView")
            
            DispatchQueue.main.async(execute: { self.collectionView?.reloadData()
            
                // Scrolling for refreshed results
                if self.scrolltoFirst && self.displayedPosts.count > 1{
                    print("Refresh Control Status: ", self.collectionView?.refreshControl?.state)
                    self.collectionView?.refreshControl?.endRefreshing()
                    let indexPath = IndexPath(item: 0, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
//                    self.collectionView?.setContentOffset(CGPoint(x: 0, y: 0 - self.topLayoutGuide.length), animated: true)
                    print("Scrolled to Top")
                    self.scrolltoFirst = false
                    self.noResultsLabel.isHidden = true
                    
                }
            
            })

//            print("Visible Cells: ",self.collectionView?.indexPathsForVisibleItems, " ScrollToFirst: ",self.scrolltoFirst, "No of items: ", self.collectionView?.numberOfItems(inSection: 0))
//            
//            if self.collectionView?.numberOfItems(inSection: 0) != 0 && self.scrolltoFirst {
//                if (self.collectionView?.indexPathsForVisibleItems)! != [] {
//                let indexPath = IndexPath(item: 0, section: 0)
//                self.collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
//                self.scrolltoFirst = false
//                self.noResultsLabel.isHidden = true
//                    print("Scolled to First")}
//                else {
//                self.scrolltoFirst = false
//                }
//            }        
//            print("Displayed Posts: ",displayedPosts)
        
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
            self.filterSortFetchedPosts()
        }
    }
    
    func filterFetchedPosts(completion: @escaping () ->()){
        
        // Filter Caption
        
        if self.filterCaption != nil && self.filterCaption != "" {
            guard let searchedText = self.filterCaption else {return}
            print("Sort Post By Caption: \(searchedText)")
            self.fetchedPosts = self.fetchedPosts.filter { (post) -> Bool in
                
                let searchedEmoji = ReverseEmojiDictionary[searchedText.lowercased()] ?? ""
                
                return post.caption.lowercased().contains(searchedText.lowercased()) || post.emoji.contains(searchedText.lowercased()) || post.nonRatingEmojiTags.joined(separator: " ").lowercased().contains(searchedText.lowercased()) || post.nonRatingEmojiTags.joined(separator: " ").lowercased().contains(searchedEmoji) || post.locationName.lowercased().contains(searchedText.lowercased()) || post.locationAdress.lowercased().contains(searchedText.lowercased())
            }
        }
        
        completion()
    }
    
    func filterSortFetchedPosts(){
        self.filterFetchedPosts {
            self.sortFetchedPosts {
                print("Finish Filter and Sorting Post")
                NotificationCenter.default.post(name: HomeController.finishSortingFetchedPostsNotificationName, object: nil)
            }
        }
    }
    
    func sortFetchedPosts(completion: @escaping () ->()){
        print("Sort Posts: \(self.currentHeaderSort)")

        if self.currentHeaderSort == HeaderSortOptions[0] {
            // Recent
            self.fetchedPosts.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
            })
            completion()
        } else if self.currentHeaderSort == HeaderSortOptions[1] {
            // Nearest
            
            // Check for current filter location
            if self.filterLocation == nil {
                print("Header Sort: Nearest, No Location, Finding Current Location")
                self.determineCurrentLocation()
                // Posts are refreshed with distances when filter location is updated
                let when = DispatchTime.now() + 1 // change 2 to desired number of seconds
                DispatchQueue.main.asyncAfter(deadline: when) {
                    self.fetchedPosts.sort(by: { (p1, p2) -> Bool in
                        return (p1.distance! < p2.distance!)
                    })
                    completion()
                }
            } else {
                self.fetchedPosts.sort(by: { (p1, p2) -> Bool in
                    return (p1.distance! < p2.distance!)
                })
                completion()
            }
        } else if self.currentHeaderSort == HeaderSortOptions[2] {
            //Trending/Oldest For Now
            self.fetchedPosts.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedAscending
            })
            completion()
        } else {
            print("Fetched Post Sort: ERROR, Invalid Sort")
            completion()
        }
        
        print("Finish Sorting")
    }
    
    
    func paginatePosts(){

        let paginateFetchPostSize = 4

        self.displayedPostsCount = min(self.displayedPostsCount + paginateFetchPostSize, self.fetchedPosts.count)
        
        if self.displayedPostsCount == self.fetchedPosts.count {
            self.isFinishedPaging = true
        }
        
        collectionView?.reloadData()

        print("Home Paginate \(self.displayedPostsCount) : \(self.fetchedPosts.count)")

        //                print("Finish Paging")
//        NotificationCenter.default.post(name: HomeController.finishPaginationNotificationName, object: nil)

    }
    
//    func paginatePosts(){
//
//        let paginateFetchPostSize = 4
//
//        var paginateFetchPostsLimit = min(self.displayedPostsCount + paginateFetchPostSize, self.fetchedPostIds.count)
//
//        print("Home Paginate \(self.displayedPostsCount) to \(paginateFetchPostsLimit) : \(self.fetchedPostIds.count)")
//
//        for i in self.displayedPostsCount ..< paginateFetchPostsLimit  {
//
//            let fetchPostId = fetchedPostIds[i]
//
////            print("Current number: ", i, "from", self.fetchedPostCount, " to ",paginateFetchPostsLimit)
////            print(" Paginate \(i): \(fetchPostId.id)")
//
//
//            Database.fetchPostWithPostID(postId: fetchPostId.id, completion: { (post, error) in
//                self.fetchedPostCount += 1
//
//                guard var fetchedPost = post else {return}
//
//                // Update Post with Location Distance from selected Location
//                if self.filterLocation != nil {
//                    fetchedPost.distance = Double((fetchedPost.locationGPS?.distance(from: self.filterLocation!))!)
//                }
//
//                var tempPost = [fetchedPost]
//
//                if let error = error {
////                    print("Failed to fetch post for: ", fetchPostId.id)
//                    return
//                }
//
//                // Filter Caption
//
//                if self.filterCaption != nil && self.filterCaption != "" {
//                    guard let searchedText = self.filterCaption else {return}
//                    tempPost = tempPost.filter { (post) -> Bool in
//
//                        let searchedEmoji = ReverseEmojiDictionary[searchedText.lowercased()] ?? ""
//
//                        return post.caption.lowercased().contains(searchedText.lowercased()) || post.emoji.contains(searchedText.lowercased()) || post.nonRatingEmojiTags.joined(separator: " ").lowercased().contains(searchedText.lowercased()) || post.nonRatingEmojiTags.joined(separator: " ").lowercased().contains(searchedEmoji) || post.locationName.lowercased().contains(searchedText.lowercased()) || post.locationAdress.lowercased().contains(searchedText.lowercased())
//                    }
//                }
//
//                if tempPost.count > 0 {print("Adding Temp Post id: ", tempPost[0].id)}
//
//                // Update Location if nil
//
//                self.displayedPosts += tempPost
//
////                print("Current: ", i, "fetchedPostCount: ", self.fetchedPostCount, "Total: ", self.fetchPostIds.count, "Display: ", self.displayedPosts.count, "finished: ", self.isFinishedPaging, "paginate:", paginateFetchPostsLimit)
//
//                if self.fetchedPostCount == paginateFetchPostsLimit {
//
////                print("Finish Paging")
//                NotificationCenter.default.post(name: HomeController.finishPaginationNotificationName, object: nil)
//
//                    }
//                })
//            }
//        }
    
    

    
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
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "mailbox").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(openInbox))
        
        if self.filterGroup == defaultGroup && self.filterRange == defaultRange && self.filterTime == defaultTime && self.filterGroup == "All" {
            filterButton.image = #imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal)
            filterButton.backgroundColor = UIColor.clear
            filterButton.addGestureRecognizer(singleTap)
        } else {
            filterButton.image = #imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal)
            filterButton.backgroundColor = UIColor.mainBlue()
//            filterButton.layer.cornerRadius = filterButton.layer.frame.width / 2
            filterButton.addGestureRecognizer(singleTap)
        }
        
        let rangeBarButton = UIBarButtonItem.init(customView: filterButton)
        navigationItem.rightBarButtonItem = rangeBarButton
        
    }

    
    func openInbox() {
        let inboxController = InboxController(collectionViewLayout: UICollectionViewFlowLayout())
        navigationController?.pushViewController(inboxController, animated: true)
    }



    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 40 + 8 + 8 //username userprofileimageview
        height += view.frame.width  // Picture
        height += 50    // Location View
        height += 60    // Action Bar
        height += 20    // Social Counts
        height += 20    // Caption
        
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
        
//        header.user = self.user
//        header.delegate = self
//        header.defaultSearchBar.text = self.filterCaption
//        if self.filterGroup == defaultGroup && self.filterRange == defaultRange && self.filterTime == defaultTime && self.filterSort == defaultSort {
//            header.isFiltering = false
//        } else {
//            header.isFiltering = true
//        }
        
        header.delegate = self
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 30 + 2)
    }
    
    
    
    
    
// HOME POST CELL DELEGATE METHODS
    
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
        print(index)
        let filteredindexpath = IndexPath(row:index!, section: 0)
        self.displayedPosts[index!] = post
//        self.collectionView?.reloadItems(at: [filteredindexpath])
        
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
            self.filterLocation = CurrentUser.currentLocation
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("GPS Location Not Found")
    }
    
}





