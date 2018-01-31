//
//  StickyHeadersCollectionViewFlowLayout.swift
//  StickyHeaders
//
//  Created by Bart Jacobs on 01/10/16.
//  Copyright © 2016 Cocoacasts. All rights reserved.
//

import UIKit

class HomeSortFilterHeaderFlowLayout: UICollectionViewFlowLayout {
    
    // MARK: - Collection View Flow Layout Methods
    var priorOffsetY: CGFloat? = nil
    var priorHeaderPosition: CGFloat? = nil
    var initContentYOffset: CGFloat? = nil
    
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

        
        var headerOffset = frameForSupplementaryView.origin.y
        
        if self.initContentYOffset == nil {
            // Init Offsets
            self.initContentYOffset = contentOffsetY
            self.priorHeaderPosition = frameForSupplementaryView.origin.y
            self.priorOffsetY = contentOffsetY
        }
        
        let headerfloor = max(0,contentOffsetY - self.initContentYOffset! - frameForSupplementaryView.height)
        let headerceiling = max(0,contentOffsetY - self.initContentYOffset!)
        
        // Basically if scrolls down, lets the header dissapear, and then resets filter when scrolling up and cap
        
        if contentOffsetY < priorOffsetY! &&  self.priorHeaderPosition! < headerfloor{
//            print("Scroll up reset header")
            headerOffset = headerfloor
        } else if contentOffsetY < priorOffsetY! && self.priorHeaderPosition! > headerceiling{
//            print("Scroll up capping header")
            headerOffset = headerceiling
        } else {
            headerOffset = self.priorHeaderPosition!
        }
        
        frameForSupplementaryView.origin.y = headerOffset
        layoutAttributes.frame = frameForSupplementaryView
        
        
//        print("Offsety : ", contentOffsetY, "Prior Offset: ", self.priorOffsetY, "Header Postion ", headerOffset, "floor: ", headerfloor, "ceiling: ", headerceiling)
        
        self.priorOffsetY = contentOffsetY
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

