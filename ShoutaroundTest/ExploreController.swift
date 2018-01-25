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
                print("Finished Paging :", self.paginatePostsCount)
            }
        }
    }
    
    // Filtering Variables
    
    var isFiltering: Bool = false
    var filterCaption: String? = nil
    var filterRange: String? = nil
    var filterLocation: CLLocation? = nil
    var filterLocationName: String? = nil
    var filterGoogleLocationID: String? = nil
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
        
        fetchRankedPostIds()
        
        NotificationCenter.default.addObserver(self, selector: #selector(fetchPosts), name: ExploreController.finishFetchingPostIdsNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: ExploreController.searchRefreshNotificationName, object: nil)
        
    }
    
    fileprivate func setupNavigationItems() {
        
        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
        navigationItem.titleView = defaultSearchBar
        defaultSearchBar.delegate = self
        defaultSearchBar.placeholder = "Food, User, Location"
        
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
            self.refreshPostsForFilter()
            searchBar.endEditing(true)
        }
    }
    
    func openSearch(index: Int?){
        
        let postSearch = PostSearchController()
        postSearch.delegate = self
        
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
            self.refreshPostsForFilter()
        }
    }
    
    func userSelected(uid: String?){
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.userId = uid
        self.navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func locationSelected(googlePlaceId: String?, googlePlaceLocation: CLLocation?, googlePlaceType: [String]?){
        let locationController = LocationController()
        locationController.googlePlaceId = googlePlaceId
        navigationController?.pushViewController(locationController, animated: true)
    }
    
    
    // Post Fetching
    
    func fetchPosts(){
        Database.fetchAllPosts(fetchedPostIds: self.fetchedPostIds, completion: { (firebaseFetchedPosts) in
            self.displayedPosts = firebaseFetchedPosts
            self.filterSortFetchedPosts()
        })
    }
    
    func fetchRankedPostIds(){
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
    
    func fetchCaptionSearchPostIds(){
        
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
                print("Finish Filter and Sorting Post, \(self.displayedPosts.count) Posts")
                self.paginatePosts()
            })
        }
    }
    
    // Refresh Functions
    func handleRefresh(){
        print("Refresh All")
        self.clearAllPosts()
        self.clearFilter()
        self.fetchRankedPostIds()
        self.collectionView?.refreshControl?.endRefreshing()
    }
    
    func refreshPostsForFilter(){
        print("Refresh Posts For Filter")
        self.displayedPosts = []
        self.fetchPosts()
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
    
    func fetchPostFromList(list: List?, completion: @escaping ([Post]?) -> ()){
        
        guard let list = list else {
            print("Fetch Post from List: ERROR, No List")
            completion(nil)
            return
        }
        
        let thisGroup = DispatchGroup()
        var tempPosts: [Post] = []
        
        for (postId,postListDate) in list.postIds! {
            thisGroup.enter()
            
            Database.fetchPostWithPostID(postId: postId, completion: { (fetchedPost, error) in
                if let error = error {
                    print("Fetch Post: ERROR, \(postId)", error)
                    return
                }
                
                // Work around to handle if listed post was deleted
                if let fetchedPost = fetchedPost {
                    var tempDate = postListDate as! Double
                    var tempPost = fetchedPost
                    let listDate = Date(timeIntervalSince1970: tempDate)
                    tempPost.listedDate = listDate
                    tempPosts.append(tempPost)
                    thisGroup.leave()
                } else {
                    print("Fetch Post: ERROR, \(postId), No Post, Will Delete from List")
                    Database.DeletePostForList(postId: postId, listId: list.id, postCreationDate: nil)
                    thisGroup.leave()
                }
                
            })
        }
        
        thisGroup.notify(queue: .main) {
            print("Fetched \(tempPosts.count) Post for List: \(list.id)")
            
            // Initial Sort by Listed Dates
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return p1.listedDate?.compare((p2.listedDate)!) == .orderedDescending
            })
            completion(tempPosts)
        }
        
    }
    
    // Search Delegates
    
    
    func filterControllerFinished(selectedCaption: String?, selectedRange: String?, selectedLocation: CLLocation?, selectedLocationName: String?, selectedGooglePlaceId: String?, selectedGooglePlaceType: [String]?, selectedMinRating: Double, selectedType: String?, selectedMaxPrice: String?, selectedSort: String){
        
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
    
    func checkFilter(){
        if self.filterCaption != nil || (self.filterRange != nil) || (self.filterMinRating != 0) || (self.filterType != nil) || (self.filterMaxPrice != nil) {
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
                self.refreshPostsForFilter()
            }
        } else {
            self.refreshPostsForFilter()
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
        
        print("number items: \(self.paginatePostsCount)")
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
        
        header.selectedRank = self.selectedHeaderRank
        header.isListView = self.isListView
        header.delegate = self
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        print(view.frame.width)
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
        
        filterController.selectedRange = self.filterRange
        filterController.selectedMinRating = self.filterMinRating
        filterController.selectedMaxPrice = self.filterMaxPrice
        filterController.selectedType = self.filterType
        
        filterController.selectedSort = self.selectedHeaderSort!
        
        self.navigationController?.pushViewController(filterController, animated: true)
    }
    
    func headerRankSelected(rank: String) {
        self.selectedHeaderRank = rank
        self.clearAllPosts()
        self.fetchRankedPostIds()
        print("Selected Rank is \(self.selectedHeaderRank), Refreshing")
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


