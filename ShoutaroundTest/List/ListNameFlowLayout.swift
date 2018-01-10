//
//  ListNameFlowLayout.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/10/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
//
//  UploadLocationFlowLayout.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/5/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

class ListNameFlowLayout: UICollectionViewFlowLayout {
    
     let minItemWidth: CGFloat = 40
    
    override init() {
        super.init()
        setupLayout()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }
    
    /**
     Sets up the layout for the collectionView. 0 distance between each cell, and vertical layout
     */
    func setupLayout() {
        
        estimatedItemSize = CGSize(width: 30, height: 30)
        //        itemSize = CGSize(width: 60, height: 30)
        if itemSize.width < minItemWidth {
            itemSize = CGSize(width: minItemWidth, height: itemSize.height)
        }
        
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0
        scrollDirection = .horizontal
        sectionInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        
    }
    
    
    override var collectionViewContentSize: CGSize {
        
        var size = super.collectionViewContentSize
        if size.width < minItemWidth {
            size.width = minItemWidth
        }
        return size
        
    }
    
    //
    //    func itemWidth() -> CGFloat {
    //        return collectionView!.frame.width
    //    }
    //
    //    func itemHeight() -> CGFloat {
    //        return collectionView!.frame.height - 2
    //    }
    
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        return collectionView!.contentOffset
    }
}
