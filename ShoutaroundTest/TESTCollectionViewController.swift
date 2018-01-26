//
//  TESTCollectionViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/25/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import EmptyDataSet_Swift


private let reuseIdentifier = "Cell"

class TESTCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, RankViewHeaderDelegate, EmptyDataSetDelegate, EmptyDataSetSource {
    func headerSortSelected(sort: String) {
        
    }
    
    func rangeSelected(range: String) {
        
    }
    

    
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

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        
        // Do any additional setup after loading the view.
        setupCollectionView()
        setupNavigationItems()
        fetchRankedPostIds()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(fetchPosts), name: ExploreController.finishFetchingPostIdsNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: ExploreController.searchRefreshNotificationName, object: nil)

    }
    
    func setupCollectionView(){
        
        collectionView?.register(ListPhotoCell.self, forCellWithReuseIdentifier: bookmarkCellId)
        collectionView?.register(GridPhotoCell.self, forCellWithReuseIdentifier: gridCellId)
        
        collectionView?.register(RankViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: listHeaderId)
        
        collectionView?.backgroundColor = .white
        //        collectionView.translatesAutoresizingMaskIntoConstraints = true
        
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
                return
            }
            
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
    
    // Pagination
    
    func paginatePosts(){
        
        let paginateFetchPostSize = 4
        
        self.paginatePostsCount = min(self.paginatePostsCount + paginateFetchPostSize, self.displayedPosts.count)
        
        if self.paginatePostsCount == self.displayedPosts.count {
            self.isFinishedPaging = true
        } else {
            self.isFinishedPaging = false
        }
        print("Paginating \(self.paginatePostsCount) : \(self.displayedPosts.count), Finished Paging: \(self.isFinishedPaging)")

        
        self.collectionView?.reloadData()
        
    }
    
    fileprivate func setupNavigationItems() {
        
        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
        navigationItem.titleView = defaultSearchBar
        defaultSearchBar.placeholder = "Food, User, Location"
        
        // Inbox
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "filter_unselected").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleRefresh))
        
    }
    
    func refreshPagination(){
        self.isFinishedPaging = false
        self.paginatePostsCount = 0
    }
    
    func handleRefresh(){
        print("Refreshing")
//        self.refreshPagination()
        self.collectionView?.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        print("Paginate Post Count: \(self.paginatePostsCount)")
        return self.displayedPosts.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
        var displayPost = displayedPosts[indexPath.item]

//        if indexPath.item == self.paginatePostsCount - 1 && !isFinishedPaging{
//            print("CollectionView Paginate")
//            paginatePosts()
//        }
        
        if isListView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: bookmarkCellId, for: indexPath) as! ListPhotoCell
//            cell.delegate = self
            cell.post = displayPost
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! GridPhotoCell
//            cell.delegate = self
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
        
        if isListView {
            // List View Size
            return CGSize(width: view.frame.width, height: 120)
        } else {
            // Grid View Size
            let width = (view.frame.width - 2) / 3
            return CGSize(width: width, height: width)
        }
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
        return CGSize(width: 150, height: 30 + 5 + 5)
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
//        filterController.delegate = self
        
        filterController.selectedRange = self.filterRange
        filterController.selectedMinRating = self.filterMinRating
        filterController.selectedMaxPrice = self.filterMaxPrice
        filterController.selectedType = self.filterType
        
        filterController.selectedSort = self.selectedHeaderSort!
        
        self.navigationController?.pushViewController(filterController, animated: true)
    }
    
    func headerRankSelected(rank: String) {
        self.selectedHeaderRank = rank
//        self.clearAllPosts()
        self.fetchRankedPostIds()
        print("Selected Rank is \(self.selectedHeaderRank), Refreshing")
    }
    
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

}
