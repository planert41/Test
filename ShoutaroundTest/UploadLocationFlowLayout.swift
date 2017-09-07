//
//  UploadLocationFlowLayout.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/5/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

class UploadLocationTagList: UICollectionViewFlowLayout {
    
    // let itemHeight: CGFloat = 50
    
    override init() {
        super.init()
        setupLayout()
        
    }
    
    /**
     Init method
     
     - parameter aDecoder: aDecoder
     
     - returns: self
     */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }
    
    /**
     Sets up the layout for the collectionView. 0 distance between each cell, and vertical layout
     */
    func setupLayout() {
        
        estimatedItemSize = CGSize(width: 40, height: 40)
        minimumInteritemSpacing = 10
        minimumLineSpacing = 10
        scrollDirection = .horizontal
        sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
    }
    
    
    
    
//
//    func itemWidth() -> CGFloat {
//        return collectionView!.frame.width
//    }
//
//    func itemHeight() -> CGFloat {
//        return collectionView!.frame.height - 2
//    }
    
    
    
//     override var itemSize: CGSize {
//     set {
//     self.itemSize = CGSize(width: itemHeight(), height: itemHeight())
//
//     }
//     get {
//     return CGSize(width: itemHeight(), height: itemHeight())
//     }
//     }
//    
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        return collectionView!.contentOffset
    }
}
