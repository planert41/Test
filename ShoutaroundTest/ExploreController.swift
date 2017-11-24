//
//  ExploreController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 11/21/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import mailgun
import GeoFire
import CoreGraphics
import CoreLocation

class ExploreController: UIViewController, UISearchBarDelegate, HomePostSearchDelegate, UISearchControllerDelegate, FilterControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UserProfilePhotoCellDelegate {

    
    // CollectionView Variables
    
    let cellId = "cellId"
    
    lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()
    
    static let finishFetchingRankPostIdsNotificationName = NSNotification.Name(rawValue: "FinishFetchingRankPostIds")
    static let finishPaginationRankPostIdsNotificationName = NSNotification.Name(rawValue: "FinishPaginationRankPostIds")

    
    
    var selectedRankIndex = 0
    var selectedRankVariable: String = defaultRankOptions[0]
    let rankOptions = defaultRankOptions
    
    var fetchedPostIds: [PostId] = []
    var fetchedPostCount = 0
    var isFinishedPaging = false {
        didSet{
            if isFinishedPaging == true {
                print("Finished Paging :", self.fetchedPostCount)
            }
        }
    }
    
    var isFinishedPagingPostIds = false {
        didSet{
            if isFinishedPagingPostIds == true {
                print("Finished Paging Post Ids :", self.fetchedPostIds.count)
            }
        }
    }
    
    var displayedPosts = [Post]() {
        didSet{
            
        }
    }
    
    
    // Search and Filter Variables
    
    var searchView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    var defaultSearchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.searchBarStyle = .prominent
        sb.barTintColor = UIColor.white
        sb.backgroundImage = UIImage()
        sb.layer.borderWidth = 0
//        sb.layer.borderColor = UIColor.lightGray.cgColor
        return sb
    }()
    
    lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "blankfilter").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activateFilter), for: .touchUpInside)
//        button.layer.borderColor = UIColor.lightGray.cgColor
//        button.layer.borderWidth = 0.5
        return button
    }()
    
    var resultSearchController:UISearchController? = nil

    var filterCaption: String? = nil{
        didSet{
            
        }
    }
    var filterLocation: CLLocation? = nil
    var filterGroup: String = defaultGroup {
        didSet{
//            setupNavigationItems()
        }
    }
    var filterRange: String = defaultRange {
        didSet{
//            setupNavigationItems()
        }
    }
    
    var filterSort: String = defaultSort
    var filterTime: String = defaultTime{
        didSet{
//            setupNavigationItems()
        }
    }
    
    var isFiltering: Bool = false {
        didSet {
            if isFiltering{
                filterButton.setImage(#imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal), for: .normal)
            } else {
                filterButton.setImage(#imageLiteral(resourceName: "blankfilter").withRenderingMode(.alwaysOriginal), for: .normal)
            }
        }
    }
    
// Ranking Variables
    
    var segmentView: SMSegmentView!
    var margin: CGFloat = 0
    
    var rankVariables = ["likes", "bookmarks", "messages"]
    
    var rankingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    let rankingIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "ranking").withRenderingMode(.alwaysOriginal), for: .normal)
        return button
    }()
    
    lazy var rankingLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Rank By"
        ul.isUserInteractionEnabled = true
//        ul.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(activateMap)))
        return ul
    }()
    
    lazy var rankLikeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "like_unselected"), for: .normal)
        button.tintColor = UIColor(white: 0, alpha: 0.2)
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 0.5
        //        button.addTarget(self, action: #selector(rankLike), for: .touchUpInside)
        return button
    }()
    
    lazy var rankBookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "bookmark_ribbon_unfilled"), for: .normal)
        button.tintColor = UIColor(white: 0, alpha: 0.2)
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 0.5
        //        button.addTarget(self, action: #selector(rankLike), for: .touchUpInside)
        return button
    }()
    
    lazy var rankMessageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "message"), for: .normal)
        button.tintColor = UIColor(white: 0, alpha: 0.2)
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 0.5
        //        button.addTarget(self, action: #selector(rankLike), for: .touchUpInside)
        return button
    }()

    var noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = UIColor.black
        label.isHidden = true
        label.textAlignment = NSTextAlignment.center
        return label
    }()

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Explore"
        
        // Add search bar and filter button
        setupSearchController()
        view.addSubview(searchView)
        view.addSubview(filterButton)
        view.addSubview(defaultSearchBar)
        searchView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        filterButton.anchor(top: searchView.topAnchor, left: nil, bottom: searchView.bottomAnchor, right: searchView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width/6, height: 0)
//        filterButton.widthAnchor.constraint(equalTo: filterButton.heightAnchor, multiplier: 1).isActive = true
        
        defaultSearchBar.delegate = self
        defaultSearchBar.anchor(top: searchView.topAnchor, left: searchView.leftAnchor, bottom: searchView.bottomAnchor, right: filterButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        // Add Ranking buttons
        view.addSubview(rankingView)
        rankingView.anchor(top: searchView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        setupRankingView()

        
        let topDividerView = UIView()
        topDividerView.backgroundColor = UIColor.lightGray
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor.lightGray
        
        view.addSubview(topDividerView)
        topDividerView.anchor(top: searchView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        view.addSubview(bottomDividerView)
        bottomDividerView.anchor(top: nil, left: view.leftAnchor, bottom: rankingView.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        
        // Collection View
        collectionView.backgroundColor = .white
        collectionView.register(UserProfilePhotoCell.self, forCellWithReuseIdentifier: cellId)
        view.addSubview(collectionView)
        collectionView.anchor(top: rankingView.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        view.addSubview(noResultsLabel)
        noResultsLabel.anchor(top: collectionView.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        noResultsLabel.isHidden = true
        
        // Add Pagination Notifications
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishFetchingPostIds), name: ExploreController.finishFetchingRankPostIdsNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishPaginationCheck), name: ExploreController.finishPaginationRankPostIdsNotificationName, object: nil)
        
        fetchingPostIds()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
        
    }

    func handleRefresh(){
        self.fetchedPostIds.removeAll()
        self.displayedPosts.removeAll()
        self.clearFilter()
        self.refreshPagination()
        fetchingPostIds()
        self.collectionView.refreshControl?.endRefreshing()
    }
    
    func refreshPagination(){
        self.isFinishedPaging = false
        self.isFinishedPagingPostIds = false
        self.fetchedPostCount = 0
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
    

    
    
    fileprivate func setupRankingView(){
        
//        let rankingStackView = UIStackView(arrangedSubviews: [rankLikeButton, rankBookmarkButton, rankMessageButton])
//        rankingStackView.axis = .horizontal
//        rankingStackView.distribution = .fillEqually
//        
//        view.addSubview(rankingStackView)
//        rankingStackView.anchor(top: rankingView.topAnchor, left: nil, bottom: rankingView.bottomAnchor, right: rankingView.rightAnchor, paddingTop: 0, paddingLeft: 1, paddingBottom: 0, paddingRight: 0, width: view.frame.width/2, height: 0)
//        
//        
        let appearance = SMSegmentAppearance()
//        appearance.segmentOnSelectionColour = UIColor(red: 245.0/255.0, green: 174.0/255.0, blue: 63.0/255.0, alpha: 1.0)
        appearance.segmentOnSelectionColour = UIColor.mainBlue()
        appearance.segmentOffSelectionColour = UIColor.white
        appearance.titleOnSelectionFont = UIFont.systemFont(ofSize: 12.0)
        appearance.titleOffSelectionFont = UIFont.systemFont(ofSize: 12.0)
        appearance.contentVerticalMargin = 10.0
        
        let segmentFrame = CGRect(x: 0, y: 0, width: (view.frame.size.width/3), height: 50.0)
        self.segmentView = SMSegmentView(frame: segmentFrame, dividerColour: UIColor(white: 0.95, alpha: 0.3), dividerWidth: 1.0, segmentAppearance: appearance)
        self.segmentView.backgroundColor = UIColor.clear
        
        self.segmentView.layer.cornerRadius = 5.0
        self.segmentView.layer.borderColor = UIColor(white: 0.85, alpha: 1.0).cgColor
        self.segmentView.layer.borderWidth = 1.0
        
        self.segmentView.addSegmentWithTitle("", onSelectionImage: #imageLiteral(resourceName: "like_selected"), offSelectionImage: #imageLiteral(resourceName: "like_unselected"))
        self.segmentView.addSegmentWithTitle("", onSelectionImage: #imageLiteral(resourceName: "bookmark_ribbon_filled"), offSelectionImage: #imageLiteral(resourceName: "bookmark_ribbon_unfilled"))
        self.segmentView.addSegmentWithTitle("", onSelectionImage: #imageLiteral(resourceName: "shoutaround"), offSelectionImage: #imageLiteral(resourceName: "message"))
        
        self.segmentView.addTarget(self, action: #selector(selectSegmentInSegmentView(segmentView:)), for: .valueChanged)
        
        // Set segment with index 0 as selected by default
        self.segmentView.selectedSegmentIndex = 0
        
        view.addSubview(segmentView)
        view.addSubview(rankingIcon)
        view.addSubview(rankingLabel)
        
        segmentView.anchor(top: rankingView.topAnchor, left: nil, bottom: rankingView.bottomAnchor, right: rankingView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width/2, height: 0)
        rankingIcon.anchor(top: rankingView.topAnchor, left: rankingView.leftAnchor, bottom: rankingView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width/6, height: 0)
        rankingLabel.anchor(top: rankingView.topAnchor, left: rankingIcon.rightAnchor, bottom: rankingView.bottomAnchor, right: segmentView.leftAnchor, paddingTop: 0, paddingLeft: 1, paddingBottom: 0, paddingRight: 1, width: 0, height: 0)
        
    }
    
    func selectSegmentInSegmentView(segmentView: SMSegmentView) {

        selectedRankIndex = segmentView.selectedSegmentIndex
        selectedRankVariable = rankOptions[selectedRankIndex]
        print("Selected Rank By \(selectedRankVariable)")
        self.handleRefresh()
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
    
    
    func activateFilter(){
        let filterController = FilterController()
        filterController.delegate = self
        filterController.selectedRange = self.filterRange
        filterController.selectedGroup = self.filterGroup
        filterController.selectedSort = self.filterSort
        filterController.selectedTime = self.filterTime
        self.navigationController?.pushViewController(filterController, animated: true)
    }
    
    // Search Delegate And Methods
    
    func filterCaptionSelected(searchedText: String?){
//        if searchedText == nil {
//            self.handleRefresh()
//        } else {
//            self.defaultSearchBar.text = searchedText
//            self.filterCaption = searchedText
//            self.finalFilterAndSort()
//        }
    }
    
    func userSelected(uid: String?){
        
    }
    
    func locationSelected(googlePlaceId: String?){
        
    }
    
    func filterControllerFinished(selectedRange: String, selectedLocation: CLLocation?, selectedGooglePlaceID: String?, selectedTime: String, selectedGroup: String, selectedSort: String){
        
//        self.filterRange = selectedRange
//        self.filterLocation = selectedLocation
//        self.filterGroup = selectedGroup
//        self.filterSort = selectedSort
//        self.filterTime = selectedTime
//        self.finalFilterAndSort()
    }
    
// Pagination
    
    
    func finishFetchingPostIds() {
        print("Finish Fetching Post Ids: \(self.fetchedPostIds.count)")
        self.paginatePosts()
    }
    
    func finishPaginationCheck() {
        if self.fetchedPostCount == (self.fetchedPostIds.count) {
            self.isFinishedPaging = true
        }
        
        if self.displayedPosts.count < 1 && self.isFinishedPaging == true && self.isFinishedPagingPostIds == true{
            print("No Results Pagination Finished")
            self.noResultsLabel.text = "No Results"
            self.noResultsLabel.isHidden = false
        }
        else if self.displayedPosts.count < 1 && self.isFinishedPaging != true && self.isFinishedPagingPostIds == true{
            print("No Display Pagination Check Paginate")
            self.noResultsLabel.text = "Loading"
            self.noResultsLabel.isHidden = false
            self.paginatePosts()
        } else {
            DispatchQueue.main.async(execute: { self.collectionView.reloadData() })
            if self.collectionView.numberOfItems(inSection: 0) != 0 && self.displayedPosts.count < 4{
                let indexPath = IndexPath(item: 0, section: 0)
                self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                self.noResultsLabel.isHidden = true
            }
        }
    }
    

    
    fileprivate func fetchingPostIds(){
        
        var fetchingPostIds = [] as [PostId]
        var fetchLimit = 8
        self.isFinishedPaging = false
        
        let firebaseRank = self.selectedRankVariable
        guard let firebaseCount = firebaseCountVariable[firebaseRank] else {return}
        
        print("Query Firebase by \(firebaseRank) : \(firebaseCount)")
        
        var query = Database.database().reference().child(firebaseRank).queryOrdered(byChild: "sort").queryLimited(toLast: UInt(fetchLimit))
        var lastPost: PostId? = nil
        
        if fetchedPostIds.count > 0 {
            lastPost = fetchedPostIds.last
            query = query.queryEnding(atValue: lastPost?.sort, childKey: lastPost?.id)
            print("Pagination Query starting at \(lastPost?.id)")
        }
        
        query.observe(.value, with: { (snapshot) in

            print("Firebase Snapshot: ",snapshot)
            guard let postIds = snapshot.value as? [String:Any] else {return}
            
            postIds.forEach({ (key,value) in

                let details = value as? [String:Any]
                var varCount = details?[firebaseCount] as! Int
                var varSort = details?["sort"] as! Double
                
                
                var tempPostId = PostId.init(id: key, creatorUID: " ", fetchedTagTime: 0, fetchedDate: 0, distance: 0, postGPS: nil, postEmoji: nil)
                
                if firebaseRank  == "likes" {
                    tempPostId.likeCount = varCount
                } else if firebaseRank  == "bookmarks" {
                    tempPostId.bookmarkCount = varCount
                } else if firebaseRank == "messages" {
                    tempPostId.messageCount = varCount
                }

                tempPostId.sort = varSort
                
                print("Current Fetched Post: \(self.fetchedPostIds.count): \(key)")
                // Add to fetched post if not dup post id from before
                if tempPostId.id != lastPost?.id {
                    fetchingPostIds.append(tempPostId)
                }
                
            })
            
            
            
//             Sort post ids before adding so that existing post ids don't get re-ordered if more postids are paginated
            fetchingPostIds.sort(by: { (p1, p2) -> Bool in
                return (p1.sort! > p2.sort!)
            })
            
            self.fetchedPostIds += fetchingPostIds
//            print("Final fetched Post Ids: \(self.fetchedPostIds)")
            
            // Determine if end of post ids to fetch
            if fetchingPostIds.count < (fetchLimit - 2) {
                self.isFinishedPagingPostIds = true
            } else {
                self.isFinishedPagingPostIds = false
            }
            
//            print("Fetched PostIds: \(fetchingPostIds.count). Total PostIds: \(self.fetchedPostIds.count). Finish Fetching Post Ids: \(self.isFinishedPagingPostIds)")
            NotificationCenter.default.post(name: ExploreController.finishFetchingRankPostIdsNotificationName, object: nil)
            
        }) { (error) in
            print("Failed to Paginate for Posts:", error)
        }
    }

    
    func paginatePosts(){
        
        print("Start Paginate Loop FetchPostCount: ", self.fetchedPostCount)
        let paginateFetchPostSize = 4
        var paginateFetchPostsLimit = min(self.fetchedPostCount + paginateFetchPostSize, self.fetchedPostIds.count)
        
        for i in self.fetchedPostCount ..< paginateFetchPostsLimit  {
            let fetchPostId = fetchedPostIds[i]
            var fetchedPost: Post? = nil

            //Fetch Post
            Database.fetchPostWithPostID(postId: fetchPostId.id, completion: { (post, error) in
                
                self.fetchedPostCount += 1
                if let error = error {
                    print("Error Fetching \(fetchPostId.id), \(error)")
                }
                
                // Filter Post based on conditions
                self.filterPosts(post: post!, completion: { (filteredPost, filterCondition) in
                    
                    if filteredPost == nil {
                        print("\(post?.id) was filtered by \(filterCondition)")
                    } else {
                        self.displayedPosts.append(filteredPost!)
                    }
                    
                    if self.fetchedPostCount == paginateFetchPostsLimit {
                        print("Finish Paging Posts")
                        NotificationCenter.default.post(name: ExploreController.finishPaginationRankPostIdsNotificationName, object: nil)
                    }
                })
            })
        }
    }
    
    
    func filterPosts(post:Post, completion: @escaping (Post?, String?) -> () ){
        
        guard var fetchedPost: Post? = post else {return}
        var filterCondition: String? = nil
        
        // Filter Time
        if self.filterTime != defaultTime && fetchedPost != nil {
            
            let calendar = Calendar.current
            let tagHour = Double(calendar.component(.hour, from: (fetchedPost?.tagTime)!))
            guard let filterIndex = FilterSortTimeDefault.index(of: self.filterTime) else {return}
            
            if FilterSortTimeStart[filterIndex] > tagHour || tagHour > FilterSortTimeEnd[filterIndex] {
                // Delete Post If not within selected time frame
                // print("Skipped Post: ", fetchPostId.id, " TagHour: ",tagHour, " Start: ", FilterSortTimeStart[filterIndex]," End: ",FilterSortTimeEnd[filterIndex])
                
                fetchedPost = nil
                filterCondition = "Time"
            }
        }
        
        // Filter Group
        
        if self.filterGroup != defaultGroup && fetchedPost != nil{
            if CurrentUser.groupUids.contains((fetchedPost?.creatorUID)!){
            } else {
                // Skip Post if not in group
                // print("Skipped Post: ", fetchPostId.id, " Creator Not in Group: ",fetchPostId.creatorUID!)
                
                fetchedPost = nil
                filterCondition = "Group"
                
            }
        }
        
        // Filter Caption
        
        if self.filterCaption != nil && self.filterCaption != "" && fetchedPost != nil {
            guard let searchedText = self.filterCaption else {return}
            guard let post = fetchedPost else {return}
            let searchedEmoji = ReverseEmojiDictionary[searchedText.lowercased()] ?? ""
            
            if post.caption.lowercased().contains(searchedText.lowercased()) || post.emoji.contains(searchedText.lowercased()) || post.nonRatingEmojiTags.joined(separator: " ").lowercased().contains(searchedText.lowercased()) || post.nonRatingEmojiTags.joined(separator: " ").lowercased().contains(searchedEmoji) || post.locationName.lowercased().contains(searchedText.lowercased()) || post.locationAdress.lowercased().contains(searchedText.lowercased()) {
                // Post Contains Caption
                
            } else {
                fetchedPost = nil
                filterCondition = "Caption"
                
            }
        }
        
        // Filter Distance
        
        if self.filterRange != defaultRange && self.filterLocation != nil && fetchedPost != nil{
            
            guard let filterDistance = Double(self.filterRange) else {return}
            fetchedPost?.distance = Double((fetchedPost?.locationGPS?.distance(from: self.filterLocation!))!)
            
            
            if (fetchedPost?.distance)! > filterDistance {
                fetchedPost = nil
                filterCondition = "Distance"
            }
        }
        
        completion(fetchedPost, filterCondition)
    }
    
    
    
// CollectionView Delegate Methods
    
    func didTapPicture(post: Post){
        let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
        pictureController.selectedPost = post
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedPosts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == self.displayedPosts.count - 1 && !isFinishedPaging{
            print("CollectionView Paginate")
            paginatePosts()
        } else if indexPath.item == self.displayedPosts.count - 1 && isFinishedPaging && !isFinishedPagingPostIds{
            print("CollectionView Paginate more Post Ids")
            fetchingPostIds()
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! UserProfilePhotoCell
        cell.post = displayedPosts[indexPath.item]
        cell.delegate = self
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 2) / 3
        return CGSize(width: width, height: width)
    }


    
    
}
