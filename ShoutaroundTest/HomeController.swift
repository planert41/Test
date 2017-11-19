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


class HomeController: UICollectionViewController, UICollectionViewDelegateFlowLayout, HomePostCellDelegate, CLLocationManagerDelegate, UISearchControllerDelegate, HomePostSearchDelegate, UIGestureRecognizerDelegate, FilterControllerDelegate  {
    
    let cellId = "cellId"
    var displayedPosts = [Post](){
        didSet{
            if displayedPosts.count == 0 {
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

    var fetchPostIds: [PostId] = [] {
        didSet{
        }
    }
    
// Geo Filter Variables
    
    let geoFilterRange = geoFilterRangeDefault
    let geoFilterImage:[UIImage] = geoFilterImageDefault
    
// Pagination Variables
    var isFinishedPaging = false {
        didSet{
            if isFinishedPaging == true {
                print("Finished Paging :", self.fetchedPostCount)
            }
        }
    }
    var fetchedPostCount = 0
    
    static let finishFetchingPostIdsNotificationName = NSNotification.Name(rawValue: "FinishFetchingPostIds")
    static let finishPaginationNotificationName = NSNotification.Name(rawValue: "FinishPagination")
    
    
// Filter Variables
    
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

    let locationManager = CLLocationManager()

    override func viewDidLayoutSubviews() {
        
//        let filterBarHeight = (self.filterBar.isHidden == false) ? self.filterBar.frame.height : 0
//        
//        let topinset = (self.navigationController?.navigationBar.frame.size.height)! + UIApplication.shared.statusBarFrame.height + filterBarHeight
//        collectionView?.frame = CGRect(x: 0, y: topinset, width: view.frame.width, height: view.frame.height - topinset - (self.tabBarController?.tabBar.frame.size.height)!)
    }

    
    func updateFirebaseData(){
        let firebaseAlert = UIAlertController(title: "Firebase Update", message: "Do you want to update Firebase Data?", preferredStyle: UIAlertControllerStyle.alert)
    
        firebaseAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
    
            let ref = Database.database().reference().child("posts")
            
            ref.observeSingleEvent(of: .value, with: {(snapshot) in
                
                guard let userposts = snapshot.value as? [String:Any]  else {return}
                
                userposts.forEach({ (key,value) in
                    
                    guard let messageDetails = value as? [String: Any] else {return}
                    guard let selectedEmojis = messageDetails["emoji"] as? String else {return}
                    guard let creationDate = messageDetails["creationDate"] as? Double else {return}
                    
                    var fetchedTagDate = messageDetails["tagTime"] as? Double
                    var fetchedRatingEmoji = messageDetails["ratingEmoji"] as? String
                    var fetchedNonratingEmoji = messageDetails["nonRatingEmoji"] as? [String]
                    var fetchedNonratingEmojiTags = messageDetails["nonRatingEmojiTags"] as? [String]
                    var creatorUid = messageDetails["creatorUID"] as? String
                    
                    let tempEmojis = String(selectedEmojis.characters.prefix(1))
                    var selectedEmojisSplit = selectedEmojis.characters.map { String($0) }
                    
                    var newRatingEmoji: String? = nil
                    var newNonratingEmoji: [String]? = nil
                    var newNonratingEmojiTags: [String]? = nil
                    var newTagTime: Double? = nil
                    
                    print("Fetched Rating Emoji: ",fetchedRatingEmoji)
                    print("Fetched NonRating Emoji: ",fetchedNonratingEmoji)
                    print("Selected Emoji splits: ", selectedEmojisSplit)
                    
                    if (fetchedRatingEmoji == nil || fetchedRatingEmoji == "" || fetchedNonratingEmoji == nil) && selectedEmojisSplit != [] {
                        // Replace Rating emoji with First of NR emoji if its rating emoji
                        
                        if String(selectedEmojisSplit[0]).containsRatingEmoji {
                            print("First Emoji Char: ",tempEmojis)
                            newRatingEmoji = String(selectedEmojisSplit[0])
                            newNonratingEmoji = Array(selectedEmojisSplit.dropFirst(1))
                            newNonratingEmojiTags = Array(selectedEmojisSplit.dropFirst(1))
                            
                        } else {
                            newRatingEmoji = fetchedRatingEmoji
                            newNonratingEmoji = selectedEmojisSplit
                            newNonratingEmojiTags = selectedEmojisSplit
                        }
                    } else {
                        newRatingEmoji = fetchedRatingEmoji
                        newNonratingEmoji = fetchedNonratingEmoji
                        newNonratingEmojiTags = fetchedNonratingEmojiTags
                    }
                    
                    print("New R Emoji: ", newRatingEmoji, " New NR Emoji: ", newNonratingEmoji, " New NR Emoji Tags: ", newNonratingEmojiTags)
                    
                    if fetchedTagDate == nil {
                        newTagTime = creationDate
                        print("Update New Tag Time with: ", creationDate)
                    } else {
                        newTagTime = fetchedTagDate!
                    }
                    
                    let values = ["ratingEmoji": newRatingEmoji, "nonratingEmoji": newNonratingEmoji, "nonratingEmojiTags": newNonratingEmojiTags, "tagTime": newTagTime] as [String: Any]
                    
                    
                    print("Updating PostId: ",key," Values: ", values)
                    Database.updatePostwithPostID(postId: key, values: values)
                    
                    var saveNewRatingEmoji = newRatingEmoji ?? ""
                    var saveNewNonratingEmoji = newNonratingEmoji?.joined() ?? ""
                    
                    let emojiString = String(saveNewRatingEmoji + saveNewNonratingEmoji)
                    
                    // Update User Posts
                    let userPostValues = ["tagTime": newTagTime, "emoji": emojiString] as [String: Any]
                    Database.updateUserPostwithPostID(creatorId: creatorUid!, postId: key, values: userPostValues)
                    
                    
                })
            })
        }))
        
        firebaseAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))

        self.present(firebaseAlert, animated: true)
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()

//        self.updateFirebaseData()
//          self.reverseEmoji()
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
        
//        self.automaticallyAdjustsScrollViewInsets = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: SharePhotoController.updateFeedNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeedWithFilter), name: FilterController.updateFeedWithFilterNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishFetchingPosts), name: HomeController.finishFetchingPostIdsNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishPaginationCheck), name: HomeController.finishPaginationNotificationName, object: nil)

        view.addSubview(noResultsLabel)
        noResultsLabel.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        collectionView?.backgroundColor = .white
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: cellId)
        
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


// Fetch Post Informations
        
        self.clearFilter()
        self.refreshPagination()
        fetchAllPostIds()
        fetchGroupUserIds()
        
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
        self.fetchPostIds.removeAll()
    }
    
    func finishFetchingPosts(){
        print("Finish Fetching Post Ids")
        self.sortFetchPostIds()
        self.paginatePosts()
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
        
        resultSearchController?.hidesNavigationBarDuringPresentation = true
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
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

    
// Search Delegates
    
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
            self.fetchPostIds = tempPostIds
            
            self.sortFetchPostIds()
            print("Geofire Filtered Posts: ", self.fetchPostIds.count)
            self.paginatePosts()
        }
        
    }
    
    func sortFetchPostIds(){
        if self.filterSort == FilterSortDefault[1] {
            // Oldest
            self.fetchPostIds.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedAscending
            })
        } else if self.filterSort == FilterSortDefault[0] {
            // Nearest
            self.fetchPostIds.sort(by: { (p1, p2) -> Bool in
                return (p1.distance! < p2.distance!)
            })
        } else {
            //Latest
            self.fetchPostIds.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
        })
        }
    }
    
    // Home Post Search Delegates
    
    func filterCaptionSelected(searchedText: String?){
        
        if searchedText == nil {
            self.handleRefresh()

        } else {
            navigationItem.title = "Results For: " + searchedText!
            self.filterCaption = searchedText
            self.resultSearchController?.searchBar.text = searchedText
            self.refreshPagination()
            self.displayedPosts.removeAll()
            self.collectionView?.reloadData()
            self.paginatePosts()
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
    
    func handleUpdateFeed() {
        
        // Check for new post that was edited or uploaded
        if newPost != nil && newPostId != nil {
            self.displayedPosts.insert(newPost!, at: 0)
            self.fetchPostIds.insert(newPostId!, at: 0)
            
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
        navigationItem.title = "Shoutaround"
        refreshPagination()
        clearFilter()
        fetchPostIds.removeAll()
        displayedPosts.removeAll()
        self.collectionView?.reloadData()
        fetchAllPostIds()
        self.collectionView?.refreshControl?.endRefreshing()
        print("Refresh Home Feed. FetchPostIds: ", self.fetchPostIds.count, " DisplayedPost: ", self.displayedPosts.count)
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
            self.fetchPostIds = self.fetchPostIds + postIds
            self.fetchPostIds.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
            })
            print("Current User Posts: ", self.fetchPostIds.count)
        }
    }

    
    fileprivate func fetchFollowingUserPostIds(){
        
        let thisGroup = DispatchGroup()
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        var followingUsers: [String] = []
        Database.database().reference().child("following").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let userIdsDictionary = snapshot.value as? [String: Any] else {return}
            userIdsDictionary.forEach({ (key,value) in

                followingUsers.append(key)
                
                thisGroup.enter()
                Database.fetchAllPostIDWithCreatorUID(creatoruid: key) { (postIds) in
                    
                    self.checkDisplayPostIdForDups(postIds: postIds)
                    self.fetchPostIds = self.fetchPostIds + postIds
                    self.fetchPostIds.sort(by: { (p1, p2) -> Bool in
                        return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                    })
                    thisGroup.leave()
                }
            })
            
            thisGroup.notify(queue: .main) {
                
                CurrentUser.followingUids = followingUsers
                print("Current User And Following Posts: ", self.fetchPostIds.count)
                print("Number of Following: ",CurrentUser.followingUids.count)
                NotificationCenter.default.post(name: HomeController.finishFetchingPostIdsNotificationName, object: nil)
            }
            
        }) { (err) in
            print("Failed to fetch following user post ids:", err)
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

    
// Pagination

    
    func finishPaginationCheck(){
        
        if self.fetchedPostCount == (self.fetchPostIds.count) {
            self.isFinishedPaging = true
        }
        
        if self.displayedPosts.count < 1 && self.isFinishedPaging == true {
            print("No Results Pagination Finished")
            self.noResultsLabel.text = "No Results"
            self.noResultsLabel.isHidden = false
        }
        else if self.displayedPosts.count < 1 && self.isFinishedPaging != true {
            print("No Display Pagination Check Paginate")
            self.noResultsLabel.text = "Loading"
            self.noResultsLabel.isHidden = false
            self.paginatePosts()
        } else {
            DispatchQueue.main.async(execute: { self.collectionView?.reloadData() })
            
            if self.collectionView?.numberOfItems(inSection: 0) != 0 && self.displayedPosts.count < 4{
                let indexPath = IndexPath(item: 0, section: 0)
                self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                self.noResultsLabel.isHidden = true
            }
        }
    }
    
    
    func paginatePosts(){
        
        print("Start Paginate Loop FetchPostCount: ", self.fetchedPostCount)
        let paginateFetchPostSize = 4
        var paginateFetchPostsLimit = min(self.fetchedPostCount + paginateFetchPostSize, self.fetchPostIds.count)
        
        for i in self.fetchedPostCount ..< paginateFetchPostsLimit  {
            
//            print("Current number: ", i, "from", self.fetchedPostCount, " to ",paginateFetchPostsLimit)
            let fetchPostId = fetchPostIds[i]
            
            // Filter Time
            if self.filterTime != defaultTime  {
                
                let calendar = Calendar.current
                let tagHour = Double(calendar.component(.hour, from: fetchPostId.tagTime))
                guard let filterIndex = FilterSortTimeDefault.index(of: self.filterTime) else {return}
                
                if FilterSortTimeStart[filterIndex] > tagHour || tagHour > FilterSortTimeEnd[filterIndex] {
                    // Skip Post If not within selected time frame
//                    print("Skipped Post: ", fetchPostId.id, " TagHour: ",tagHour, " Start: ", FilterSortTimeStart[filterIndex]," End: ",FilterSortTimeEnd[filterIndex])
                    self.fetchedPostCount += 1
                    if self.fetchedPostCount == paginateFetchPostsLimit {
                        // End of loop functions are checked every iteration. Skipping iteration skipped the check
//                        print("Finish Paging @ TimeCheck")
                        NotificationCenter.default.post(name: HomeController.finishPaginationNotificationName, object: nil)
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
                        NotificationCenter.default.post(name: HomeController.finishPaginationNotificationName, object: nil)
                    }
                    continue
                }
            }
            
            Database.fetchPostWithPostID(postId: fetchPostId.id, completion: { (post, error) in
                self.fetchedPostCount += 1
                
                guard let post = post else {return}
                var tempPost = [post]
                
                if let error = error {
//                    print("Failed to fetch post for: ", fetchPostId.id)
                    return
                }
                
                // Filter Caption
                
                if self.filterCaption != nil && self.filterCaption != "" {
                    guard let searchedText = self.filterCaption else {return}
                    tempPost = tempPost.filter { (post) -> Bool in
                        
                    return post.caption.lowercased().contains(searchedText.lowercased()) || post.emoji.contains(searchedText.lowercased()) || post.locationName.lowercased().contains(searchedText.lowercased()) || post.locationAdress.lowercased().contains(searchedText.lowercased())
                    }
                }

                if tempPost.count > 0 {print("Adding Temp Post id: ", tempPost[0].id)}
                
                self.displayedPosts += tempPost

//                print("Current: ", i, "fetchedPostCount: ", self.fetchedPostCount, "Total: ", self.fetchPostIds.count, "Display: ", self.displayedPosts.count, "finished: ", self.isFinishedPaging, "paginate:", paginateFetchPostsLimit)
                
                if self.fetchedPostCount == paginateFetchPostsLimit {

//                print("Finish Paging")
                NotificationCenter.default.post(name: HomeController.finishPaginationNotificationName, object: nil)
                    
                    }
                })
            }
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
        
        navigationItem.title = "Shoutaround"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "search_selected").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(openSearch))
        
        if self.filterGroup == defaultGroup && self.filterRange == defaultRange && self.filterTime == defaultTime && self.filterGroup == "All" {
            filterButton.image = #imageLiteral(resourceName: "blankfilter").withRenderingMode(.alwaysOriginal)
            filterButton.backgroundColor = UIColor.clear
            filterButton.addGestureRecognizer(singleTap)
        } else {
            filterButton.image = #imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal)
//            filterButton.backgroundColor = UIColor.orange
            filterButton.addGestureRecognizer(singleTap)
        }
        
        let rangeBarButton = UIBarButtonItem.init(customView: filterButton)
        navigationItem.rightBarButtonItem = rangeBarButton
        
    }

    
    func openInbox() {
        let inboxController = InboxController(collectionViewLayout: UICollectionViewFlowLayout())
        navigationController?.pushViewController(inboxController, animated: true)
    }
    
    func openSearch(){
        self.present(resultSearchController!, animated: true, completion: nil)
    }


    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 40 + 8 + 8 //username userprofileimageview
        height += view.frame.width
        height += 50
        height += 60
        height += 20
        
        return CGSize(width: view.frame.width, height: height)
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        

        return displayedPosts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == self.displayedPosts.count - 1 && !isFinishedPaging{
            print("CollectionView Paginate")
            paginatePosts()
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! HomePostCell
        cell.post = displayedPosts[indexPath.item]
        
        if self.filterLocation != nil {
            cell.post?.distance = Double((cell.post?.locationGPS?.distance(from: self.filterLocation!))!)
        }
        
        cell.delegate = self
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //print(displayedPosts[indexPath.item])
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
        
        let postId = post.id
        postCache[postId!] = post
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
    
}





