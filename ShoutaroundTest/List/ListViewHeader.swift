//
//  ListViewHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/7/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Firebase

protocol ListViewHeaderDelegate {
    func didChangeToListView()
    func didChangeToPostView()
    func activateFilter()
    func headerSortSelected(sort: String)
}


class ListViewHeader: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    var delegate: ListViewHeaderDelegate?

    var headerSortSegment = UISegmentedControl()
    var selectedSort: String = defaultSort

// Grid/List View Button
    var isListView = true {
        didSet{
            formatButton.setImage(self.isListView ? #imageLiteral(resourceName: "postview") :#imageLiteral(resourceName: "list"), for: .normal)
        }
    }
    
    lazy var formatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(self.isListView ? #imageLiteral(resourceName: "postview") :#imageLiteral(resourceName: "list"), for: .normal)
        button.addTarget(self, action: #selector(changeView), for: .touchUpInside)
        return button
    }()
    
    func changeView(){
        if isListView{
            self.isListView = false
            delegate?.didChangeToPostView()
        } else {
            self.isListView = true
            delegate?.didChangeToListView()
        }
    }
    

// Filter Button
    
    var isFiltering: Bool = false {
        didSet{
            filterButton.backgroundColor = isFiltering ? UIColor.mainBlue() : UIColor.clear
        }
    }
    
    lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activateFilter), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.clipsToBounds = true
        return button
    }()
    
    func activateFilter(){
        self.delegate?.activateFilter()
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(filterButton)
        filterButton.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 1, paddingRight: 3, width: 0, height: 0)
        filterButton.widthAnchor.constraint(equalTo: filterButton.heightAnchor, multiplier: 1).isActive = true
//        filterButton.layer.cornerRadius = filterButton.frame.width/2
        filterButton.layer.masksToBounds = true
        
        addSubview(formatButton)
        formatButton.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: filterButton.leftAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 1, paddingRight: 3, width: 0, height: 0)
        formatButton.widthAnchor.constraint(equalTo: formatButton.heightAnchor, multiplier: 1).isActive = true
//        formatButton.layer.cornerRadius = formatButton.frame.width/2
        formatButton.layer.masksToBounds = true
        
        headerSortSegment = UISegmentedControl(items: HeaderSortOptions)
        headerSortSegment.selectedSegmentIndex = HeaderSortOptions.index(of: self.selectedSort)!
        headerSortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        
        addSubview(headerSortSegment)
        headerSortSegment.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: formatButton.leftAnchor, paddingTop: 5, paddingLeft: 3, paddingBottom: 5, paddingRight: 1, width: 0, height: 0)
        
    }
    
    func selectSort(sender: UISegmentedControl) {
        self.selectedSort = HeaderSortOptions[sender.selectedSegmentIndex]
        delegate?.headerSortSelected(sort: self.selectedSort)
        print("Selected Sort is ",self.selectedSort)
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}
