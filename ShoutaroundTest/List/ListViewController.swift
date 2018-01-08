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

class ListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, BookmarkPhotoCellDelegate, HomePostCellDelegate, ListViewHeaderDelegate, SortFilterHeaderDelegate, FilterControllerDelegate {

    let bookmarkCellId = "bookmarkCellId"
    let homePostCellId = "homePostCellId"
    let listHeaderId = "listHeaderId"
    
// CollectionView Setup
    
    var isListView: Bool = true
    
    lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
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
    var selectedHeaderSort:String? = defaultSort
    
    
    
// Posts
    
    var displayListId: String? = nil
    var displayList: List? = nil
    var fetchedPosts: [Post] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        self.navigationController?.navigationBar.tintColor = UIColor.blue
        self.navigationItem.title = displayList?.name
        
        collectionView.register(BookmarkPhotoCell.self, forCellWithReuseIdentifier: bookmarkCellId)
        collectionView.register(HomePostCell.self, forCellWithReuseIdentifier: homePostCellId)
        collectionView.register(ListViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: listHeaderId)
        
        collectionView.backgroundColor = .white
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
        
        view.addSubview(collectionView)
        collectionView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        fetchListPosts()
    
    }
    
    func fetchListPosts(){
        guard let displayListId = displayListId else {
            print("Fetch Post for List: ERROR, No ListID")
            return
        }
        
        if displayList == nil {
            print("Fetch Post for List: No List, Pulling List for \(displayListId)")
            Database.fetchListforSingleListId(listId: displayListId, completion: { (fetchedList) in
                self.displayList = fetchedList
                self.fetchPostFromList(list: self.displayList, completion: { (fetchedPosts) in
                    if let fetchedPosts = fetchedPosts {
                        self.fetchedPosts = fetchedPosts
                    } else {
                        self.fetchedPosts = []
                    }
                    self.filterSortFetchedPosts()
                })
            })
        } else {
            self.fetchPostFromList(list: self.displayList, completion: { (fetchedPosts) in
                print("Fetch Post for List: Success, Post Count: \(fetchedPosts?.count)")

                if let fetchedPosts = fetchedPosts {
                    self.fetchedPosts = fetchedPosts
                } else {
                    self.fetchedPosts = []
                }
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
                self.collectionView.reloadData()
            })
        }
    }
    
    // Refresh Functions
    
    
    func handleRefresh(){
        print("Refresh List")
        self.clearAllPost()
        self.clearFilter()
        self.collectionView.reloadData()
        self.fetchListPosts()
        self.collectionView.refreshControl?.endRefreshing()
    }
    
    func refreshPostsForFilter(){
        self.clearAllPost()
        self.collectionView.reloadData()
        self.fetchListPosts()
        self.collectionView.refreshControl?.endRefreshing()
    }
    
    
    func clearAllPost(){
        self.displayList = nil
        self.fetchedPosts = []
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
                    Database.DeletePostForList(postId: postId, listId: list.id)
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
    
    
    func filterControllerFinished(selectedRange: String?, selectedLocation: CLLocation?, selectedLocationName: String?, selectedMinRating: Double, selectedType: String?, selectedMaxPrice: String?, selectedSort: String){
        
        // Clears all Filters, Puts in new Filters, Refreshes all Post IDS and Posts
        
        self.clearFilter()
        
        self.filterRange = selectedRange
        self.filterLocation = selectedLocation
        self.filterLocationName = selectedLocationName
        
        self.filterMinRating = selectedMinRating
        self.filterType = selectedType
        self.filterMaxPrice = selectedMaxPrice
        
        self.selectedHeaderSort = selectedSort
        
        // Refresh Everything
        self.refreshPostsForFilter()
        
        // Check for filtering
        if (self.filterRange != nil) || (self.filterMinRating != 0) || (self.filterType != nil) || (self.filterMaxPrice != nil) {
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
            var height: CGFloat = 40 + 8 + 8 //username userprofileimageview
            height += view.frame.width  // Picture
            height += 50    // Location View
            height += 60    // Action Bar
            height += 20    // Social Counts
            height += 20    // Caption
            
            return CGSize(width: view.frame.width, height: height)
        }
    }
    
    
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return fetchedPosts.count
    }
    
     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var displayPost = fetchedPosts[indexPath.item]
        
        if isListView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: bookmarkCellId, for: indexPath) as! BookmarkPhotoCell
            cell.delegate = self
            cell.bookmarkDate = displayPost.listedDate
            cell.post = displayPost
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: homePostCellId, for: indexPath) as! HomePostCell
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
        header.delegate = self
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 30 + 5 + 5)
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
    
    func activateFilter(){
        let filterController = FilterController()
        filterController.delegate = self
        
        filterController.selectedRange = self.filterRange
        filterController.selectedMinRating = self.filterMinRating
        filterController.selectedMaxPrice = self.filterMaxPrice
        filterController.selectedType = self.filterType
        
        filterController.selectedSort = self.selectedHeaderSort!
        
        self.navigationController?.pushViewController(filterController, animated: true)
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
    
    func displaySelectedEmoji(emoji: String, emojitag: String) {
        
        emojiDetailLabel.text = emoji + " " + emojitag
        emojiDetailLabel.isHidden = false
        
    }
    
    
    
    
    
    

}

