//
//  StickyHeadersCollectionViewFlowLayout.swift
//  StickyHeaders
//
//  Created by Bart Jacobs on 01/10/16.
//  Copyright © 2016 Cocoacasts. All rights reserved.
//

import UIKit

class StickyHeadersCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    // MARK: - Collection View Flow Layout Methods
    var priorYOffset: CGFloat? = nil
    var priorHeaderPosition: CGFloat? = nil
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let layoutAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
        
        // Helpers
        let sectionsToAdd = NSMutableIndexSet()
        var newLayoutAttributes = [UICollectionViewLayoutAttributes]()
        
        for layoutAttributesSet in layoutAttributes {
            if layoutAttributesSet.representedElementCategory == .cell {
                // Add Layout Attributes
                newLayoutAttributes.append(layoutAttributesSet)
                
                // Update Sections to Add
                sectionsToAdd.add(layoutAttributesSet.indexPath.section)
                
            } else if layoutAttributesSet.representedElementCategory == .supplementaryView {
                // Update Sections to Add
                sectionsToAdd.add(layoutAttributesSet.indexPath.section)
            }
            
        }
        //        print("Sections to Add: ", sectionsToAdd)
        //        print("New Layout Attributes: ", newLayoutAttributes)
        
        for section in sectionsToAdd {
            let indexPath = IndexPath(item: 0, section: section)
            
            if let sectionAttributes = self.layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: indexPath) {
                newLayoutAttributes.append(sectionAttributes)
            }
        }
        
        return newLayoutAttributes
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let layoutAttributes = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath) else { return nil }
        guard let boundaries = boundaries(forSection: indexPath.section) else { return layoutAttributes }
        guard let collectionView = collectionView else { return layoutAttributes }
        
        // Helpers
        let contentOffsetY = collectionView.contentOffset.y
        var frameForSupplementaryView = layoutAttributes.frame
        // Set minimum to zero for 0 cell collectionview 
        let minimum = max(0,boundaries.minimum - frameForSupplementaryView.height)
        let maximum = boundaries.maximum - frameForSupplementaryView.height
        
        // 64 is the initial default content inset (nav bar height) 150 is height for profile view
        
        if contentOffsetY < minimum + ((200-50) - 64) {
            frameForSupplementaryView.origin.y = minimum
        } else if contentOffsetY > maximum {
            frameForSupplementaryView.origin.y = maximum
        } else {
            frameForSupplementaryView.origin.y = contentOffsetY - ((200-50) - 64)
        }

        // TEST
//        if self.priorYOffset != nil {
//            // Not init
//            let distance = contentOffsetY - self.priorYOffset!
//
//            if contentOffsetY > self.priorYOffset!{
//                // Scroll Down
//
//                if contentOffsetY > (200 - 64) {
//                    frameForSupplementaryView.origin.y = contentOffsetY - (200 - 64)
//                } else {
//                    frameForSupplementaryView.origin.y = 0
//                }
////                    frameForSupplementaryView.origin.y = max(0,max(self.priorHeaderPosition!,contentOffsetY - (200 - 64)))
//
//            } else if contentOffsetY < self.priorYOffset! {
//                // Scroll Up
//
//                if (self.priorHeaderPosition! - contentOffsetY) > 64 {
//                    frameForSupplementaryView.origin.y = self.priorYOffset! + max(0,self.priorHeaderPosition! - contentOffsetY - 64)
//                }
//                else {
//                    frameForSupplementaryView.origin.y = self.priorHeaderPosition!
//                }
//
////                if contentOffsetY < minimum + ((200-50) - 64) {
////                    frameForSupplementaryView.origin.y = minimum
////                } else {
////                    frameForSupplementaryView.origin.y = min(self.priorHeaderPosition!,contentOffsetY + (200 - 64 - 64))
////                }
//
//            } else {
//                frameForSupplementaryView.origin.y = self.priorHeaderPosition!
//            }
//        }
//
        
        layoutAttributes.frame = frameForSupplementaryView
        
        
//        print("contentoffsety : ", contentOffsetY, "Prior Offset: ", self.priorYOffset, " min: ", minimum, "max: ", maximum, "Haader Postion ", layoutAttributes.frame.origin.y)
        self.priorYOffset = contentOffsetY
        self.priorHeaderPosition = frameForSupplementaryView.origin.y
        
        return layoutAttributes
    }
    
    // MARK: - Helper Methods
    
    func boundaries(forSection section: Int) -> (minimum: CGFloat, maximum: CGFloat)? {
        // Helpers
        var result = (minimum: CGFloat(0.0), maximum: CGFloat(0.0))
        
        // Exit Early
        guard let collectionView = collectionView else { return result }
        
        // Fetch Number of Items for Section
        let numberOfItems = collectionView.numberOfItems(inSection: section)
        
        // Exit Early
        guard numberOfItems > 0 else { return result }
        
        if let firstItem = layoutAttributesForItem(at: IndexPath(item: 0, section: section)),
            let lastItem = layoutAttributesForItem(at: IndexPath(item: (numberOfItems - 1), section: section)) {
            result.minimum = firstItem.frame.minY
            result.maximum = lastItem.frame.maxY
            
            // Take Header Size Into Account
            result.minimum -= headerReferenceSize.height
            result.maximum -= headerReferenceSize.height
            
            // Take Section Inset Into Account
            result.minimum -= sectionInset.top
            result.maximum += (sectionInset.top + sectionInset.bottom)
        }
        
        return result
    }
    
}
