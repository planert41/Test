//
//  SortFilterHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/28/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

protocol SortFilterHeaderDelegate {
//    func didChangeToListView()
//    func didChangeToGridView()
//    func didSignOut()
//    func activateSearchBar()
    func openFilter()
    func headerSortSelected(sort: String)
}

class SortFilterHeader: UICollectionViewCell {
    
    var delegate: SortFilterHeaderDelegate?

    // 0 For Default Header Sort Options, 1 for Location Sort Options
    var sortOptionsInd: Int = 0 {
        didSet{
            if sortOptionsInd == 0 {
                sortOptions = HeaderSortOptions
            } else if sortOptionsInd == 1 {
                sortOptions = LocationSortOptions
            } else {
                sortOptions = HeaderSortOptions
            }
        }
    }
    
    var sortOptions: [String] = HeaderSortOptions
    
    
    var headerSortSegment = UISegmentedControl()
    var selectedSort: String = defaultSort {
        didSet{
            if sortOptions[headerSortSegment.selectedSegmentIndex] != selectedSort {
                headerSortSegment.selectedSegmentIndex = sortOptions.index(of: selectedSort)!
            }
        }
    }
    var isFiltering: Bool = false {
        didSet{
            filterButton.backgroundColor = isFiltering ? UIColor.mainBlue() : UIColor.clear
        }
    }
    
    lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "search_blank").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activateFilter), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.clipsToBounds = true
        return button
    }()
    
    func activateFilter(){
        self.delegate?.openFilter()
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
     
        backgroundColor = UIColor.white
        headerSortSegment = UISegmentedControl(items: sortOptions)
        headerSortSegment.selectedSegmentIndex = sortOptions.index(of: self.selectedSort)!
        headerSortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        headerSortSegment.tintColor = UIColor(hexColor: "107896")
        
        addSubview(filterButton)
        filterButton.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 2, paddingLeft: 1, paddingBottom: 3, paddingRight: 3, width: 0, height: 0)
        filterButton.widthAnchor.constraint(equalTo: filterButton.heightAnchor, multiplier: 1).isActive = true
        filterButton.layer.cornerRadius = filterButton.frame.width/2
        filterButton.backgroundColor = UIColor.mainBlue()
        filterButton.layer.masksToBounds = true
        
        addSubview(headerSortSegment)
        headerSortSegment.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: filterButton.leftAnchor, paddingTop: 2, paddingLeft: 3, paddingBottom: 4, paddingRight: 1, width: 0, height: 0)
        
    }
    
    func selectSort(sender: UISegmentedControl) {
        
        self.selectedSort = sortOptions[sender.selectedSegmentIndex]
        delegate?.headerSortSelected(sort: self.selectedSort)
        print("Selected Sort is ",self.selectedSort)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}
