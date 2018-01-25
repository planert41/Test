//
//  ListView.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/7/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import CoreLocation
import EmptyDataSet_Swift


class ExploreController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, ListPhotoCellDelegate, SortFilterHeaderDelegate, FilterControllerDelegate, EmptyDataSetSource, EmptyDataSetDelegate, GridPhotoCellDelegate, RankViewHeaderDelegate, PostSearchControllerDelegate {

    


    
    //INPUT
    var fetchedPostIds: [PostId] = []
    var displayedPosts: [Post] = []

    
    // Navigation Bar
    var defaultSearchBar = UISearchBar()
    
    var isListView: Bool = false
    let bookmarkCellId = "bookmarkCellId"
    let gridCellId = "gridCellId"
    let listHeaderId = "listHeaderId"
    
    // Pagination Variables
    var paginatePostsCount: Int = 0
    var isFinishedPaging = false {
        didSet{
            if isFinishedPaging == true {
//                print("Finished Paging :", self.paginatePostsCount)
            }
        }
    }
    
    // Filtering Variables
    
    var isFiltering: Bool = false {
        didSet {
            // Adjust Filter Button
            setupNavigationItems()
        }
    }
    var filterCaption: String? = nil
    var filterRange: String? = nil
    
    var filterLocationName: String? = nil
    var filterLocation: CLLocation? = nil
    var filterGoogleLocationID: String? = nil
    var filterGoogleLocationType: [String]? = []
    
    var filterMinRating: Double = 0
    var filterType: String? = nil
    var filterMaxPrice: String? = nil
    
    // Header Sort Variables

    // Default Rank is Most Votes
    var selectedHeaderRank:String = defaultRank
    
    // Default Sort is Most Recent Listed Date, But Set to Default Rank
    var selectedHeaderSort:String? = defaultRank

    static let finishFetchingPostIdsNotificationName = NSNotification.Name(rawValue: "FinishFetchingPostIds")
    static let searchRefreshNotificationName = NSNotification.Name(rawValue: "SearchRefresh")
    static let refreshListViewNotificationName = NSNotification.Name(rawValue: "RefreshListView")


    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        self.navigationController?.navigationBar.tintColor = UIColor.blue
        setupNavigationItems()
        setupCollectionView()
        
//        1. Fetches Post Ids Based on Social/Location
//        2. Fetches All Post for Post Ids
//        3. Filter Sorts Post based on Criteria
//        4. Paginates and Refreshes
        
        fetchPostIds()
        
        NotificationCenter.default.addObserver(self, selector: #selector(fetchSortFilterPosts), name: ExploreController.finishFetchingPostIdsNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: ExploreController.searchRefreshNotificationName, object: nil)
        
    }
    
    fileprivate func setupNavigationItems() {
        
        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
        navigationItem.titleView = defaultSearchBar
        defaultSearchBar.delegate = self
        defaultSearchBar.placeholder = "Food, User, Location"
        
        // Fill in Default Search Bar Text
        if isFiltering {
            var searchTerm: String = ""
            if filterCaption != nil {searchTerm += " \(filterCaption!)"}
            if filterLocationName != nil {searchTerm += " @\(filterLocationName!)"}
            if (filterRange != nil) {searchTerm += " Within \(filterRange!) Mi"}
            if filterMaxPrice != nil {searchTerm += " \(filterMaxPrice!)"}
            if filterType != nil {searchTerm += " \(filterType!)"}
            defaultSearchBar.text = searchTerm
        }
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: (isFiltering ? #imageLiteral(resourceName: "filterclear") : #imageLiteral(resourceName: "filter_unselected")).withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(openFilter))
    }
    
    func setupCollectionView(){
        
        collectionView?.register(ListPhotoCell.self, forCellWithReuseIdentifier: bookmarkCellId)
        collectionView?.register(GridPhotoCell.self, forCellWithReuseIdentifier: gridCellId)
        collectionView?.register(RankViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: listHeaderId)
        
        collectionView?.backgroundColor = .white
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.delegate = self
        collectionView?.dataSource = self

        // Adding Empty Data Set
        collectionView?.emptyDataSetSource = self
        collectionView?.emptyDataSetDelegate = self
        
    }
    
    // Setup for Geo Range Button, Dummy TextView and UIPicker
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.openSearch(index: 0)
        return false
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.length == 0) {
            self.filterCaption = nil
            self.checkFilter()
            self.handleRefresh()
            searchBar.endEditing(true)
        }
    }
    
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        self.fetchCaptionSearchPostIds()
//    }
//
    func openSearch(index: Int?){
        
        let postSearch = PostSearchController()
        postSearch.delegate = self
        postSearch.searchController.searchBar.text = self.filterCaption
        
        self.navigationController?.pushViewController(postSearch, animated: true)
        if index != nil {
            postSearch.selectedScope = index!
            postSearch.searchController.searchBar.selectedScopeButtonIndex = index!
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
            self.checkFilter()
            self.refreshPostsForSearch()
        }
    }
    
    func userSelected(uid: String?){
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.userId = uid
        self.navigationController?.pushViewController(userProfileController, animated: true)
    }
    

    
    func locationSelected(googlePlaceId: String?, googlePlaceName: String?, googlePlaceLocation: CLLocation?, googlePlaceType: [String]?) {
        self.filterRange = nil
        self.filterGoogleLocationID = googlePlaceId
        self.filterLocation = googlePlaceLocation
        self.filterLocationName = googlePlaceName
        self.filterGoogleLocationType = googlePlaceType
        self.refreshPostsForSearch()

    }
    
    
    // Post Fetching
    
    func fetchSortFilterPosts(){
        Database.fetchAllPosts(fetchedPostIds: self.fetchedPostIds, completion: { (firebaseFetchedPosts) in
            self.displayedPosts = firebaseFetchedPosts
            self.filterSortFetchedPosts()
        })
    }
    
    func fetchPostIds(){
        self.checkFilter()
        
        if filterLocation == nil && filterCaption == nil {
            // If No Filter Location and Caption, Fetch Top Posts by Social
            fetchPostIdsBySocialRank()
        } else if filterCaption != nil && filterLocation == nil {
            // If has Filter Caption, Fetch All Posts with Emoji Tags
            fetchPostIdsByTag()
        } else if filterLocation != nil {
            // If has Filter Location, Pull all Post Id for Location
            if (self.filterGoogleLocationType?.contains("establishment"))! {
                // Selected Google Location is a restaurant, search posts by Restaurant
                fetchPostIdsByRestaurant()
            } else {
                // Selected Google Location not a restaurant, search posts by Location with Range
                fetchPostIdsByLocation()
            }
            
        }
    }
    
    func fetchPostIdsBySocialRank(){
        print("Fetching Post Id By \(self.selectedHeaderRank)")
        Database.fetchPostIDBySocialRank(firebaseRank: self.selectedHeaderRank, fetchLimit: 250) { (postIds) in
            guard let postIds = postIds else {
                print("Fetched Post Id By \(self.selectedHeaderRank) : Error, No Post Ids")
                return}
            
            print("Fetched Post Id By \(self.selectedHeaderRank) : Success, \(postIds.count) Post Ids")
            self.fetchedPostIds = postIds
            NotificationCenter.default.post(name: ExploreController.finishFetchingPostIdsNotificationName, object: nil)
        }
    }
    
    func fetchPostIdsByTag(){
        
        guard let searchText = self.filterCaption else {return}

        Database.translateToEmojiArray(stringInput: searchText) { (emojiTags) in
            guard let emojiTags = emojiTags else {
                print("Search Post With Emoji Tags: ERROR, No Emoji Tags")
                return
            }
            
            var tempPostIds: [PostId] = []
            let myGroup = DispatchGroup()

            for emoji in emojiTags {
                if !emoji.isEmptyOrWhitespace(){
                    myGroup.enter()
                    Database.fetchAllPostIDWithTag(emojiTag: emoji, completion: { (fetchedPostIds) in
                        myGroup.leave()
                        print("\(emoji): \((fetchedPostIds?.count)!) Posts")
                        if let fetchedPostIds = fetchedPostIds {
                            tempPostIds = tempPostIds + fetchedPostIds
                        }
                    })
                }
            }
            
            myGroup.notify(queue: .main) {
                print("\(emojiTags) Fetched Total \(tempPostIds.count) Posts")
                self.fetchedPostIds = tempPostIds
                NotificationCenter.default.post(name: ExploreController.finishFetchingPostIdsNotificationName, object: nil)
            }
        }
    }
    
    
    func fetchPostIdsByLocation(){
        guard let location = self.filterLocation else {
            print("Fetch Post ID By Location GPS: ERROR, No Location GPS")
            return}
        
        if (self.filterGoogleLocationType?.contains("establishment"))!{
            print("Fetch Post ID By Location: ERROR, Is an Establishment")
            return}
        
        var range: Double = 0
        if (self.filterGoogleLocationType?.contains("locality"))! {
            // Selected City, So range is 25 Miles
            range = 25
            self.filterRange = "25"
        } else if (self.filterGoogleLocationType?.contains("neighbourhood"))! {
            // Selected City, So range is 25 Miles
            range = 5
            self.filterRange = "5"
        } else {
            range = 5
            self.filterRange = "5"
        }
        
        Database.fetchAllPostWithLocation(location: location, distance: range) { (fetchedPosts, fetchedPostIds) in
            self.fetchedPostIds = fetchedPostIds
            self.displayedPosts = fetchedPosts
            self.filterSortFetchedPosts()
            print("Fetch Posts By Location: Success, Posts: \(self.displayedPosts.count), Range: \(range), Location: \(location.coordinate.latitude),\(location.coordinate.longitude)")
        }
        
        
    }
    
    func fetchPostIdsByRestaurant(){
        guard let googlePlaceID = self.filterGoogleLocationID else {
            print("Fetch Post ID By Restaurant: ERROR, No Google Place ID")
            return}
        
        if !(self.filterGoogleLocationType?.contains("establishment"))!{
            print("Fetch Post ID By Restaurant: ERROR, Not An Establishment")
            return}
        
        Database.fetchAllPostWithGooglePlaceID(googlePlaceId: googlePlaceID) { (fetchedPosts, fetchedPostIds) in
            
            self.fetchedPostIds = fetchedPostIds
            self.displayedPosts = fetchedPosts
            self.filterSortFetchedPosts()
            print("Fetch Posts By Location: Success, Posts: \(self.displayedPosts.count), Google Place Id: \(googlePlaceID)")
        }
    }
    
    func filterSortFetchedPosts(){
        
        // Filter Posts
        Database.filterPosts(inputPosts: self.displayedPosts, filterCaption: self.filterCaption, filterRange: self.filterRange, filterLocation: self.filterLocation, filterMinRating: self.filterMinRating, filterType: self.filterType, filterMaxPrice: self.filterMaxPrice) { (filteredPosts) in
            
            // Sort Posts
            Database.sortPosts(inputPosts: filteredPosts, selectedSort: self.selectedHeaderRank, selectedLocation: self.filterLocation, completion: { (filteredPosts) in
                
                self.displayedPosts = []
                if filteredPosts != nil {
                    self.displayedPosts = filteredPosts!
                }
                print("Filter Sort Post: Success: \(self.displayedPosts.count) Posts")
                self.paginatePosts()
            })
        }
    }
    
    // Refresh Functions
    func handleRefresh(){
        print("Refresh All")
        self.clearAllPosts()
        self.clearFilter()
        self.fetchPostIds()
        self.collectionView?.refreshControl?.endRefreshing()
    }
    
    func refreshPostsForSearch(){
        print("Refresh Posts For New Search")
        self.clearAllPosts()
        self.fetchPostIds()
        self.collectionView?.refreshControl?.endRefreshing()
    }
    
    func refreshPostsForSort(){
        print("Refresh Posts For Filter")
        // Does not repull post ids, just resorts displayed posts
        self.displayedPosts = []
        self.fetchSortFilterPosts()
        self.paginatePosts()
        self.collectionView?.refreshControl?.endRefreshing()
    }
    
    func clearAllPosts(){
        self.fetchedPostIds = []
        self.displayedPosts = []
        self.refreshPagination()
    }
    
    func clearFilter(){
        self.filterLocation = nil
        self.filterLocationName = nil
        self.filterRange = nil
        self.filterGoogleLocationID = nil
        self.filterGoogleLocationType = []
        self.filterMinRating = 0
        self.filterType = nil
        self.filterMaxPrice = nil
        
        self.filterCaption = nil
        self.defaultSearchBar.text?.removeAll()
        
        self.selectedHeaderRank = defaultRank
        self.selectedHeaderSort = defaultSort
        self.isFiltering = false
    }
    
    func refreshPagination(){
        self.isFinishedPaging = false
        self.paginatePostsCount = 0
    }
    
    // Search Delegates
    
    
    func filterControllerFinished(selectedCaption: String?, selectedRange: String?, selectedLocation: CLLocation?, selectedLocationName: String?, selectedGooglePlaceId: String?, selectedGooglePlaceType: [String]?, selectedMinRating: Double, selectedType: String?, selectedMaxPrice: String?, selectedSort: String){
        
        // Clears all Filters, Puts in new Filters, Refreshes all Post IDS and Posts
        
        self.clearFilter()
        
        self.filterCaption = selectedCaption
        self.filterRange = selectedRange!
        self.filterLocation = selectedLocation
        self.filterLocationName = selectedLocationName
        
        self.filterMinRating = selectedMinRating
        self.filterType = selectedType
        self.filterMaxPrice = selectedMaxPrice
        
        self.selectedHeaderSort = selectedSort
        
        // Check for filtering
        self.checkFilter()
        
        // Refresh Everything
        self.refreshPostsForSearch()
    }
    
    func checkFilter(){
        if self.filterCaption != nil || (self.filterRange != nil) || (self.filterMinRating != 0) || (self.filterType != nil) || (self.filterMaxPrice != nil) || (self.filterLocation != nil) {
            self.isFiltering = true
        } else {
            self.isFiltering = false
        }
    }
    func headerSortSelected(sort: String) {
        self.selectedHeaderSort = sort
        self.collectionView?.reloadData()
        
        if (self.selectedHeaderSort == HeaderSortOptions[1] && self.filterLocation == nil){
            print("Sort by Nearest, No Location, Look up Current Location")
            LocationSingleton.sharedInstance.determineCurrentLocation()
            let when = DispatchTime.now() + defaultGeoWaitTime // change 2 to desired number of seconds
            DispatchQueue.main.asyncAfter(deadline: when) {
                //Delay for 1 second to find current location
                self.filterLocation = CurrentUser.currentLocation
                self.refreshPostsForSort()
            }
        } else {
            self.refreshPostsForSort()
        }
        
        print("Filter Sort is ", self.selectedHeaderSort)
    }
    
    // Pagination
    
    func paginatePosts(){
        
        let paginateFetchPostSize = 4
        
        self.paginatePostsCount = min(self.paginatePostsCount + paginateFetchPostSize, self.displayedPosts.count)
        
        if self.paginatePostsCount == self.displayedPosts.count {
            self.isFinishedPaging = true
        } else {
            self.isFinishedPaging = false
        }
        
        print("Home Paginate \(self.paginatePostsCount) : \(self.displayedPosts.count), Finished Paging: \(self.isFinishedPaging)")
        
        // NEED TO RELOAD ON MAIN THREAD OR WILL CRASH COLLECTIONVIEW
        DispatchQueue.main.async(execute: { self.collectionView?.reloadData() })

    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if isListView {
            // List View Size
            return CGSize(width: view.frame.width, height: 120)
        } else {
            // Grid View Size
            let width = (view.frame.width - 2) / 3
            return CGSize(width: width, height: width)
        }
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.paginatePostsCount
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var displayPost = displayedPosts[indexPath.item]
        
        if indexPath.item == self.paginatePostsCount - 1 && !isFinishedPaging{
            print("CollectionView Paginate")
            paginatePosts()
        }
        
        if isListView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: bookmarkCellId, for: indexPath) as! ListPhotoCell
            cell.delegate = self
            cell.post = displayPost
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! GridPhotoCell
            cell.delegate = self
            cell.post = displayPost
            return cell
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //print(displayedPosts[indexPath.item])
    }
    
    // SORT FILTER HEADER
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: listHeaderId, for: indexPath) as! RankViewHeader
//
//        if self.filterRange == nil {
//            header.selectedRange = globalRangeDefault
//        } else {
//            header.selectedRange = self.filterRange
//        }
        header.selectedLocation = self.filterLocation
        header.selectedRange = self.filterRange
        header.selectedRank = self.selectedHeaderRank
        header.isListView = self.isListView
        header.delegate = self
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 150, height: 30 + 5 + 5)

//        return CGSize(width: view.frame.width, height: 30 + 5 + 5)
    }
    
    // Empty Data Set Delegates
    
    // EMPTY DATA SET DELEGATES
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if isFiltering {
            text = "We Found Nothing Legit"
        } else {
            text = "Fill Up Your List!"
        }
        
        font = UIFont.boldSystemFont(ofSize: 17.0)
        textColor = UIColor(hexColor: "25282b")
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: textColor])
        
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        //        if isFiltering {
        //            text = "Try Something Further or Ramen"
        //        } else {
        //            text = "Fill Up Your List!"
        //        }
        
        
        font = UIFont.boldSystemFont(ofSize: 13.0)
        textColor = UIColor(hexColor: "7b8994")
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: textColor])
        
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return #imageLiteral(resourceName: "emptydataset")
    }
    
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> NSAttributedString? {
        
        var text: String?
        var font: UIFont?
        var textColor: UIColor?
        
        if isFiltering {
            text = "Try Searching For Something Else"
        } else {
            text = "Start Adding Posts to Your Lists!"
        }
        
        font = UIFont.boldSystemFont(ofSize: 14.0)
        textColor = UIColor(hexColor: "00aeef")
        
        if text == nil {
            return nil
        }
        
        return NSMutableAttributedString(string: text!, attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: textColor])
        
    }
    
    func buttonBackgroundImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> UIImage? {
        
        var capInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        var rectInsets = UIEdgeInsets.zero
        
        capInsets = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)
        rectInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
        let image = #imageLiteral(resourceName: "emptydatasetbutton")
        return image.resizableImage(withCapInsets: capInsets, resizingMode: .stretch).withAlignmentRectInsets(rectInsets)
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return UIColor(hexColor: "fcfcfa")
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        if isFiltering {
            self.openFilter()
        } else {
            // Returns To Home Tab
            self.tabBarController?.selectedIndex = 0
        }
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView) {
        self.handleRefresh()
    }
    
    //    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
    //        let offset = (self.collectionView.frame.height) / 5
    //        return -50
    //    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return 9
    }
    
    
    
    
    
    // List Header Delegate
    
    func didChangeToListView(){
        self.isListView = true
        collectionView?.reloadData()
    }
    
    func didChangeToGridView() {
        self.isListView = false
        collectionView?.reloadData()
    }
    
    func openFilter(){
        let filterController = FilterController()
        filterController.delegate = self
        
        if self.filterLocation != nil {
            filterController.selectedLocation = self.filterLocation
            filterController.selectedLocationName = self.filterLocationName
            filterController.selectedGooglePlaceID = self.filterGoogleLocationID
            filterController.selectedGooglePlaceType = self.filterGoogleLocationType
        }
        
        filterController.selectedRange = self.filterRange
        filterController.selectedMinRating = self.filterMinRating
        filterController.selectedMaxPrice = self.filterMaxPrice
        filterController.selectedType = self.filterType
        
        filterController.selectedSort = self.selectedHeaderSort!
        
        self.navigationController?.pushViewController(filterController, animated: true)
    }
    
    func headerRankSelected(rank: String) {
        
        if !self.isFiltering {
            // Not Filtering for anything, so Pull in Post Ids by top social rank
            self.selectedHeaderRank = rank
            self.clearAllPosts()
            self.fetchPostIds()
            print("Refreshing Post Ids for Rank: \(self.selectedHeaderRank), No Location")
        } else {
            // Filtered for something else, so just resorting posts based on social
            self.refreshPostsForSort()
        }
    }
    
    
    // HOME POST CELL DELEGATE METHODS
    
    func didTapBookmark(post: Post) {
        
        let sharePhotoListController = SharePhotoListController()
        sharePhotoListController.uploadPost = post
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    
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
        
    }
    
    func refreshPost(post: Post) {
        let index = displayedPosts.index { (fetchedPost) -> Bool in
            fetchedPost.id == post.id
        }
        
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
        editPost.editPostInd = true
        editPost.editPostImageUrl = post.imageUrl
        editPost.editPostId = post.id
        
        // Post Details
        editPost.selectPostGooglePlaceID = post.locationGooglePlaceID
        editPost.selectedImageLocation = post.locationGPS
        editPost.selectPostLocation = post.locationGPS
        editPost.selectPostLocationName = post.locationName
        editPost.selectPostLocationAdress = post.locationAdress
        editPost.selectTime = post.tagTime
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
    
    
    
    
    
    
    
    
}


