//
//  Testing.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/24/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import CoreLocation
import EmptyDataSet_Swift

class ExploreControllerTESTING: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    //INPUT
    var fetchedPostIds: [PostId] = []
    var displayedPosts: [Post] = []
    
    
    // Navigation Bar
    var defaultSearchBar = UISearchBar()
    
    // CollectionView Setup
    
    lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()
    
    var isFiltering: Bool = false
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
    
    // Default Rank is Most Votes
    var selectedHeaderRank:String = defaultRank
    
    // Default Sort is Most Recent Listed Date, But Set to Default Rank
    var selectedHeaderSort:String? = defaultRank
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        self.navigationController?.navigationBar.tintColor = UIColor.blue
        setupNavigationItems()
        setupCollectionView()
        
        view.addSubview(collectionView)
        collectionView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 50, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        collectionView.backgroundColor = UIColor.blue
        fetchRankedPostIds()
        
        NotificationCenter.default.addObserver(self, selector: #selector(fetchPosts), name: ExploreController.finishFetchingPostIdsNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: ExploreController.searchRefreshNotificationName, object: nil)
        
    }
    
    fileprivate func setupNavigationItems() {
        
        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
        navigationItem.titleView = defaultSearchBar
//        defaultSearchBar.delegate = self
        defaultSearchBar.placeholder = "Food, User, Location"
        
        // Inbox
        //        navigationItem.rightBarButtonItem = UIBarButtonItem(image: (isFiltering ? #imageLiteral(resourceName: "filterclear") : #imageLiteral(resourceName: "filter_unselected")).withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(openFilter))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: (isFiltering ? #imageLiteral(resourceName: "filterclear") : #imageLiteral(resourceName: "filter_unselected")).withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleRefresh))
        
    }
    
    func setupCollectionView(){
        
        collectionView.register(ListPhotoCell.self, forCellWithReuseIdentifier: bookmarkCellId)
        collectionView.register(GridPhotoCell.self, forCellWithReuseIdentifier: gridCellId)
//        collectionView.register(RankViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: listHeaderId)
        
        collectionView.backgroundColor = .white
        //        collectionView.translatesAutoresizingMaskIntoConstraints = true
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
        
        
        // Adding Empty Data Set
        //        collectionView.emptyDataSetSource = self
        //        collectionView.emptyDataSetDelegate = self
        
        //        collectionView.delegate = self
        
        
    }
    
    
    
    func handleRefresh(){
        self.collectionView.reloadData()
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
            self.fetchPosts()
            NotificationCenter.default.post(name: ExploreController.finishFetchingPostIdsNotificationName, object: nil)
        }
    }
    
    func fetchPosts(){
        Database.fetchAllPosts(fetchedPostIds: self.fetchedPostIds, completion: { (firebaseFetchedPosts) in
            self.displayedPosts = firebaseFetchedPosts
            self.paginatePosts()
//            self.filterSortFetchedPosts()
        })
    }
    
    func paginatePosts(){
        
        let paginateFetchPostSize = 4
        
        self.paginatePostsCount = min(self.paginatePostsCount + paginateFetchPostSize, self.displayedPosts.count)
        print("Home Paginate \(self.paginatePostsCount) : \(self.displayedPosts.count)")
        
        if self.paginatePostsCount == self.displayedPosts.count {
            self.isFinishedPaging = true
        } else {
            self.isFinishedPaging = false
        }
        self.collectionView.reloadData()
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
//        if isListView {
//            // List View Size
//            return CGSize(width: view.frame.width, height: 120)
//        } else {
//            // Grid View Size
//            let width = (view.frame.width - 2) / 3
//            return CGSize(width: width, height: width)
//        }
        
        
        let width = (view.frame.width - 2) / 3
        return CGSize(width: width, height: width)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return displayedPosts.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var displayPost = displayedPosts[indexPath.item]
        
        if indexPath.item == self.paginatePostsCount - 1 && !isFinishedPaging{
            print("CollectionView Paginate")
            paginatePosts()
        }
        
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //print(displayedPosts[indexPath.item])
    }
    
    
    

    
    

    
    
    // SORT FILTER HEADER
    
//    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: listHeaderId, for: indexPath) as! RankViewHeader
//
//        header.selectedRank = self.selectedHeaderRank
//        header.isListView = self.isListView
////        header.delegate = self
//        return header
//
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: view.frame.width, height: 30 + 5 + 5)
//    }
//
    
    
    
}
