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
import BTNavigationDropdownMenu


class ListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ListPhotoCellDelegate, HomePostCellDelegate, ListHeaderDelegate, SortFilterHeaderDelegate, FilterControllerDelegate, EmptyDataSetSource, EmptyDataSetDelegate, GridPhotoCellDelegate, PostSearchControllerDelegate {
    

    static let refreshListViewNotificationName = NSNotification.Name(rawValue: "RefreshListView")

    let bookmarkCellId = "bookmarkCellId"
    let gridCellId = "gridCellId"
    let listHeaderId = "listHeaderId"
    
    var enableListManagementView: Bool = false
    
    
    override func viewWillAppear(_ animated: Bool) {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
    }

    
    // INPUT
    var currentDisplayList: List? = nil {
        didSet{
            fetchPostsForList()
            if displayUser?.uid != currentDisplayList?.creatorUID{
                print("Fetching \(currentDisplayList?.creatorUID) for List \(currentDisplayList?.name): \(currentDisplayList?.id)")
                fetchUserForList()
            }
        }
    }
    
    // Used to fetch lists
    var displayUser: User? = nil
    var displayedLists: [List]? = [] {
        didSet{
            guard let uid = Auth.auth().currentUser?.uid else {return}
            guard var displayedLists = self.displayedLists else {
                // If Displayed list is null, set to default
                self.displayedLists = [emptyLegitList,emptyBookmarkList]
                self.displayedListNames = [legitListName, bookmarkListName]
                return
            }
            
            if displayUser?.uid != uid {
                // Exclude Private list if not current user
                if let filteredList = self.displayedLists?.filter({ (list) -> Bool in
                    return list.publicList == 1
                }){
                    displayedLists = filteredList
                } else {
                    displayedLists = []
                }
            }
            
            // Sort Display List
            displayedLists.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
            })
            
            // Populate Displayed List Names
            var tempListNames: [String] = []
            for list in displayedLists.reversed() {
                // Add List Name and List Count
                var listName = "\(list.name) (\((list.postIds?.count)!))"
                tempListNames.append(listName)
            }
            self.displayedListNames = tempListNames
            self.collectionView.reloadData()
        }
    }
    
    var displayedListNames: [String] = [legitListName, bookmarkListName] {
        didSet{
            setupNavigationItems()
        }
    }

    var menuView: BTNavigationDropdownMenu!

    //DISPLAY VARIABLES
    var fetchedPosts: [Post] = []
    
// CollectionView Setup
    
    var isListView: Bool = true
    
    lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: HomeSortFilterHeaderFlowLayout())
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()
    
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        emojiDetailLabel.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
        menuView.hide()
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
    // Default Sort is Most Recent Listed Date
    var selectedHeaderSort:String? = defaultRecentSort
    
    func fetchPostsForList(){
        guard let displayListId = currentDisplayList?.id else {
            print("Fetch Post for List: ERROR, No List or ListId")
            return
        }
        
        Database.fetchPostFromList(list: self.currentDisplayList, completion: { (fetchedPosts) in
            print("Fetch Post for List : Success, \(displayListId):\(self.currentDisplayList?.name), Count: \(fetchedPosts?.count) Posts")
            
            if let fetchedPosts = fetchedPosts {
                self.fetchedPosts = fetchedPosts
            } else {
                self.fetchedPosts = []
            }
            self.filterSortFetchedPosts()
        })
    }
    
    func fetchUserForList(){
        guard let currentDisplayList = self.currentDisplayList else {
            print("Fetch User For List: Error, No Display List")
            return
        }
        
        Database.fetchUserWithUID(uid: (currentDisplayList.creatorUID)!) { (fetchedUser) in
            self.displayUser = fetchedUser
            self.fetchListsForUser()
        }
    }
    
    func fetchListsForUser(){
        guard let displayListIds = self.displayUser?.listIds else {
            print("Fetch Lists for User: Error, No List Ids, Default List, \(self.displayUser?.uid)")
            self.displayedLists = [emptyLegitList, emptyBookmarkList]
            return
        }
        
        Database.fetchListForMultListIds(listUid: displayListIds) { (fetchedLists) in
            if fetchedLists.count == 0 {
                print("Fetch List Error, No Lists, Displaying Default Empty Lists")
                self.displayedLists = [emptyLegitList, emptyBookmarkList]
            } else {
                self.displayedLists = fetchedLists
            }
            
            print("Fetched Lists: \(self.displayedLists?.count) Lists for \(self.displayUser?.uid)")
//            NotificationCenter.default.post(name: ListViewController.refreshListViewNotificationName, object: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationItem.title = currentDisplayList?.name
        

        setupCollectionView()
        view.addSubview(collectionView)
        collectionView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: ListViewController.refreshListViewNotificationName, object: nil)
    }
    
    func setupNavigationItems(){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
    // Setup List Drop Down Bar
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
       
        var menuOptions = self.displayedListNames
        var manageListString = "Manage Lists"
        if self.currentDisplayList?.creatorUID == uid {
            menuOptions.append(manageListString)
        }

        menuView = BTNavigationDropdownMenu(navigationController: self.navigationController, containerView: self.navigationController!.view, title: (self.currentDisplayList?.name)!, items: menuOptions)
        menuView.navigationBarTitleFont = UIFont(font: .noteworthyBold, size: 18)
        
        menuView.cellHeight = 50
        menuView.cellBackgroundColor = self.navigationController?.navigationBar.barTintColor
        menuView.cellSelectionColor = UIColor(red: 0.0/255.0, green:160.0/255.0, blue:195.0/255.0, alpha: 1.0)
        menuView.shouldKeepSelectedCellColor = true
        menuView.cellTextLabelColor = UIColor.white
        menuView.cellTextLabelFont = UIFont(font: .noteworthyBold, size: 18)
        menuView.cellTextLabelAlignment = .left // .Center // .Right // .Left
        menuView.arrowPadding = 15
        menuView.animationDuration = 0.5
        menuView.maskBackgroundColor = UIColor.black
        menuView.maskBackgroundOpacity = 0.3
        
        
        menuView.didSelectItemAtIndexHandler = {(indexPath: Int) -> Void in
            print("Did select item at index: \(indexPath)")
            if menuOptions[indexPath] == manageListString {
                print("Selected Manage Lists")
                self.menuView.shouldChangeTitleText = false
                self.manageList()
            } else {
                self.menuView.shouldChangeTitleText = true
                self.currentDisplayList = self.displayedLists![indexPath]
            }
        }
        
        self.navigationItem.titleView = menuView
        
    // Setup Map Button (Right Bar)
        let mapImage = #imageLiteral(resourceName: "google_map_alt").resizeImageWith(newSize: CGSize(width: 30, height: 30))
        
        let mapButton = UIBarButtonItem(image: #imageLiteral(resourceName: "map_personal").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(openMap))
        navigationItem.rightBarButtonItem = mapButton
        
        if enableListManagementView {
            let listButton = UIBarButtonItem(image: #imageLiteral(resourceName: "list_tab_unfill").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(manageList))
            navigationItem.leftBarButtonItem = listButton
        }
        
        // Setup User Profile Button (Left Bar)
//        let userImage = CustomImageView()
//        userImage.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
//        userImage.contentMode = .scaleAspectFill
//        userImage.clipsToBounds = true
//        userImage.loadImage(urlString: (displayUser?.profileImageUrl)!)
//
//        let newImage = userImage.image?.resizeImageWith(newSize: CGSize(width: userImage.frame.width, height: userImage.frame.width))
//        userImage.image = newImage
//        userImage.isUserInteractionEnabled = true
//        userImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userSelected)))
//        userImage.layer.cornerRadius = userImage.frame.width/2
//
//        let userProfileButton = UIBarButtonItem(customView: userImage)
//
//        if navigationItem.leftBarButtonItems?.count == 0 {
//            navigationItem.leftBarButtonItem = userProfileButton
//        } else {
//            navigationItem.leftBarButtonItems?.append(userProfileButton)
//        }
        
    }
    
    func openMap(){
        print("Open Map")
        let mapView = MapViewController()
        mapView.currentDisplayList = self.currentDisplayList
        navigationController?.pushViewController(mapView, animated: true)
    }
    
    func manageList(){
        let sharePhotoListController = ManageListViewController()
        navigationController?.pushViewController(sharePhotoListController, animated: true)
    }
    
    func userSelected(){
        let userProfileController = UserProfileController(collectionViewLayout: StickyHeadersCollectionViewFlowLayout())
        userProfileController.userId = displayUser?.uid
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func setupCollectionView(){
        collectionView.register(ListPhotoCell.self, forCellWithReuseIdentifier: bookmarkCellId)
        collectionView.register(GridPhotoCell.self, forCellWithReuseIdentifier: gridCellId)
        collectionView.register(ListViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: listHeaderId)
        
        collectionView.collectionViewLayout = HomeSortFilterHeaderFlowLayout()
        collectionView.backgroundColor = .white
        collectionView.translatesAutoresizingMaskIntoConstraints = true
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.bounces = true
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
        
        // Adding Empty Data Set
        collectionView.emptyDataSetSource = self
        collectionView.emptyDataSetDelegate = self
    }
    

    
    func filterSortFetchedPosts(){
        
        self.checkFilter()
        // Filter Posts
        Database.filterPosts(inputPosts: self.fetchedPosts, filterCaption: self.filterCaption, filterRange: self.filterRange, filterLocation: self.filterLocation, filterMinRating: self.filterMinRating, filterType: self.filterType, filterMaxPrice: self.filterMaxPrice) { (filteredPosts) in
            
            // Sort Recent Post By Listed Date
            var listSort: String = "Listed"
            if self.selectedHeaderSort == defaultRecentSort {
                listSort = "Listed"
            } else {
                listSort = self.selectedHeaderSort!
            }
            
            Database.sortPosts(inputPosts: filteredPosts, selectedSort: listSort, selectedLocation: self.filterLocation, completion: { (filteredPosts) in
                
                self.fetchedPosts = []
                if filteredPosts != nil {
                    self.fetchedPosts = filteredPosts!
                }
                print("Finish Filter and Sorting Post")
                self.collectionView.reloadData()
            })
        }
    }
    
    // Refresh Functions
    
    
    func handleRefresh(){
        print("Refresh List")
        self.clearAllPost()
        self.clearFilter()
//        self.collectionView.reloadData()
        self.fetchPostsForList()
        self.collectionView.refreshControl?.endRefreshing()
    }
    
    func refreshPostsForFilter(){
        self.checkFilter()
        self.clearAllPost()
        self.collectionView.reloadData()
        self.fetchPostsForList()
        self.collectionView.refreshControl?.endRefreshing()
    }
    
    
    func clearAllPost(){
        self.fetchedPosts = []
    }
    
    
    func clearFilter(){
        self.filterCaption = nil
        self.filterLocation = nil
        self.filterLocationName = nil
        self.filterRange = nil
        self.filterGoogleLocationID = nil
        self.filterMinRating = 0
        self.filterType = nil
        self.filterMaxPrice = nil
        self.selectedHeaderSort = defaultRecentSort
        self.isFiltering = false
    }
    
   

    // Search Delegates
    
    func clearCaptionSearch(){
        self.filterCaption = nil
        self.checkFilter()
        self.refreshPostsForFilter()
    }
    
    func filterCaptionSelected(searchedText: String?){
        print("Filter Caption Selected: \(searchedText)")
        self.filterCaption = searchedText
        self.refreshPostsForFilter()
    }
    
//    func userSelected(uid: String?){
//
//    }
    
//    func locationSelected(googlePlaceId: String?, googlePlaceName: String?, googlePlaceLocation: CLLocation?, googlePlaceType: [String]?){
//
//    }
    
    
    func filterControllerFinished(selectedCaption: String?, selectedRange: String?, selectedLocation: CLLocation?, selectedLocationName: String?, selectedGooglePlaceId: String?, selectedGooglePlaceType: [String]?, selectedMinRating: Double, selectedType: String?, selectedMaxPrice: String?, selectedSort: String) {

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
        self.collectionView.reloadData()
        
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
    
    
    
    

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if isListView {
            return CGSize(width: view.frame.width, height: 120)
        } else {
            let width = (view.frame.width - 2) / 3
            return CGSize(width: width, height: width)
            
            // Home Post Cell Size
//            var height: CGFloat = 40 + 8 + 8 //username userprofileimageview
//            height += view.frame.width  // Picture
//            height += 50    // Location View
//            height += 60    // Action Bar
//            height += 20    // Social Counts
//            height += 20    // Caption
//
//            return CGSize(width: view.frame.width, height: height)
        }
    }
    
    
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return fetchedPosts.count
    }
    
     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var displayPost = fetchedPosts[indexPath.item]
        
        if isListView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: bookmarkCellId, for: indexPath) as! ListPhotoCell
            cell.delegate = self
            cell.bookmarkDate = displayPost.listedDate
            cell.post = displayPost
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: gridCellId, for: indexPath) as! GridPhotoCell
            cell.delegate = self
            cell.post = displayPost
            return cell
        }
    }
    
     func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //print(displayedPosts[indexPath.item])
    }
    
    // SORT FILTER HEADER
    
     func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: listHeaderId, for: indexPath) as! ListViewHeader
        header.isFiltering = self.isFiltering
        header.isListView = self.isListView
        header.selectedCaption  = self.filterCaption
        header.delegate = self
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        var height = 30 + 5 + 5 // Header Sort with 5 Spacing
        height += 40 // Search bar View
        return CGSize(width: view.frame.width, height: 30 + 5 + 5 + (40))
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
        collectionView.reloadData()
    }
    
    func didChangeToPostView() {
        self.isListView = false
        collectionView.reloadData()
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
    
    func openSearch(index: Int?){
        
        let postSearch = PostSearchController()
        postSearch.delegate = self
        
        // Disbale Scope Options, only allow filter by emoji or caption
        postSearch.enableScopeOptions = false
        
        self.navigationController?.pushViewController(postSearch, animated: true)
        if index != nil {
            postSearch.selectedScope = index!
            postSearch.searchController.searchBar.selectedScopeButtonIndex = index!
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
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
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
                    self.alert(title: "List Display Error", message: "List Does Not Exist Anymore")
                } else {
                    if fetchedList?.publicList == 0 && fetchedList?.creatorUID != uid {
                        self.alert(title: "List Display Error", message: "List Is Private")
                    } else {
                        let listViewController = ListViewController()
                        listViewController.currentDisplayList = fetchedList
                        self.navigationController?.pushViewController(listViewController, animated: true)
                    }
                }
            })
        }
    }
    
    func refreshPost(post: Post) {
        let index = fetchedPosts.index { (fetchedPost) -> Bool in
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
            let index = self.fetchedPosts.index { (filteredpost) -> Bool in
                filteredpost.id  == post.id
            }
            
            let filteredindexpath = IndexPath(row:index!, section: 0)
            self.fetchedPosts.remove(at: index!)
            self.collectionView.deleteItems(at: [filteredindexpath])
            Database.deletePost(post: post)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func deletePostFromList(post: Post) {
        
        let deleteAlert = UIAlertController(title: "Delete", message: "Remove Post From List?", preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                // Remove from Current View
                let index = self.fetchedPosts.index { (filteredpost) -> Bool in
                    filteredpost.id  == post.id
                }
            
                let deleteindexpath = IndexPath(row:index!, section: 0)
                self.fetchedPosts.remove(at: index!)
                self.collectionView.deleteItems(at: [deleteindexpath])
                Database.DeletePostForList(postId: post.id!, listId: self.currentDisplayList?.id, postCreationDate: nil)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        if self.currentDisplayList?.creatorUID == uid{
            // Only Allow Deletion if current user is list creator
            present(deleteAlert, animated: true, completion: nil)
        }
    }
    
    func displaySelectedEmoji(emoji: String, emojitag: String) {
        
        emojiDetailLabel.text = emoji + " " + emojitag
        emojiDetailLabel.isHidden = false
        
    }
    
    
    
    
    
    

}

