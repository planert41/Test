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

class ExploreTestController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, UISearchBarDelegate, RankViewHeaderDelegate, SortFilterHeaderDelegate {
    
    let cellId = "cellId"
    let rankHeaderId = "rankHeaderId"
    
    var fetchedPostIds: [PostId] = []
    var fetchedPostCount = 0
    var displayedPosts = [Post]()

    
    // Filter Variables
    
    var isFiltering: Bool = false
    var filterCaption: String? = nil
    var filterRange: String? = nil
    
    var filterLocation: CLLocation? = nil{
        didSet{
//            self.updatePostDistances(refLocation: filterLocation){}
            if filterLocation == nil {
                self.filterLocationName = nil
            } else if filterLocation == CurrentUser.currentLocation{
                self.filterLocationName = "Current Location"
            }
        }
    }
    var filterLocationName: String? = nil
    var filterGoogleLocationID: String? = nil
    var filterMinRating: Double = 0
    var filterType: String? = nil
    var filterMaxPrice: String? = nil
    
    // Header Sort Variables
    var selectedHeaderSort = HeaderSortDefault {
        didSet {
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Collection View
        collectionView?.backgroundColor = .white
        collectionView?.register(UserProfilePhotoCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.register(SortFilterHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: rankHeaderId)
        
        collectionView?.backgroundColor = UIColor.blue
        
        
    }
    
    // CollectionView Delegate Methods
    
    func didTapPicture(post: Post){
        let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
        pictureController.selectedPost = post
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedPosts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
//        if indexPath.item == self.displayedPosts.count - 1 && !isFinishedPaging{
//            print("CollectionView Paginate")
//            paginatePosts()
//        } else if indexPath.item == self.displayedPosts.count - 1 && isFinishedPaging && !isFinishedPagingPostIds{
//            print("CollectionView Paginate more Post Ids")
//            fetchingPostIds()
//        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! UserProfilePhotoCell
        cell.post = displayedPosts[indexPath.item]
//        cell.delegate = self
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
    
    // RANK FILTER HEADER
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: rankHeaderId, for: indexPath) as! SortFilterHeader
        
        header.isFiltering = self.isFiltering
        //        header.isGridView = self.isGridView
        //        header.isGlobal = self.isGlobal
        header.delegate = self
        //        header.selectedSort = self.selectedHeaderSort
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 35 + 5)
    }
    
    //RANK FILTER HEADER DELEGATE FUNCTIONS
    
    func didChangeToListView() {
        
    }
    
    func didChangeToPostView() {
        
    }
    
    func headerRankSelected(rank: String) {
        
    }
    
    func headerSortSelected(sort: String) {
        
    }
    
    func openFilter(){
        let filterController = FilterController()
//        filterController.delegate = self
        
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

    
    
    
}

