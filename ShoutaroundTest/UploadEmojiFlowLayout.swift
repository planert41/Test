//
//  UploadEmojiFlowLayout.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/13/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//


import UIKit

class UploadEmojiList: UICollectionViewFlowLayout {
    
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
        
     //   estimatedItemSize = CGSize(width: EmojiSize.width-5, height: EmojiSize.width-5)
        minimumInteritemSpacing = 1
        minimumLineSpacing = 1
        scrollDirection = .horizontal
        sectionInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        
    }
    
    
    
    
    
        func itemWidth() -> CGFloat {
            return EmojiSize.width
        }
    
        func itemHeight() -> CGFloat {
            return EmojiSize.width
        }
    
         override var itemSize: CGSize {
         set {
         self.itemSize = CGSize(width: itemHeight(), height: itemHeight())
    
         }
         get {
         return CGSize(width: itemHeight(), height: itemHeight())
         }
         }
    
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        return collectionView!.contentOffset
    }
}
