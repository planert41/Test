//
//  RankViewHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/19/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

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

protocol RankViewHeaderDelegate {
    func didChangeToListView()
    func didChangeToPostView()
    func openFilter()
    func headerRankSelected(rank: String)
}


class RankViewHeader: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    var delegate: RankViewHeaderDelegate?
    
    // Ranking Variables
    var rankView = UIView()
    
    var rankSortOptions: [String] = defaultRankOptions
    var rankSegmentView: SMSegmentView!
    var rankSegmentControl = UISegmentedControl()
    var headerSortSegment = UISegmentedControl()
    var selectedRank: String = defaultRank {
        didSet{
            headerSortSegment.selectedSegmentIndex = rankSortOptions.index(of: selectedRank)!
        }
    }
    
    var isGlobal: Bool = true {
        didSet{
            rankButton.setImage(self.isGlobal ? #imageLiteral(resourceName: "Globe") :#imageLiteral(resourceName: "GeoFence"), for: .normal)
        }
    }
    
    lazy var rankButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(self.isGlobal ? #imageLiteral(resourceName: "Globe").withRenderingMode(.alwaysOriginal) :#imageLiteral(resourceName: "GeoFence").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(changeScope), for: .touchUpInside)
        return button
    }()
    
    func changeScope(){
        
    }
    
    lazy var rankLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Rank By"
        ul.isUserInteractionEnabled = true
        ul.font = UIFont.boldSystemFont(ofSize: 14)
        return ul
    }()
    
    // Filter/Search Bar
    var filterView = UIView()
    
    var defaultSearchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.searchBarStyle = .prominent
        sb.barTintColor = UIColor.white
        sb.backgroundImage = UIImage()
        sb.layer.borderWidth = 0
        sb.searchBarStyle = .minimal
        //        sb.layer.borderColor = UIColor.lightGray.cgColor
        return sb
    }()
    
    
    // Grid/List View Button
    var isGridView = true {
        didSet{
            formatButton.setImage(self.isGridView ? #imageLiteral(resourceName: "grid") :#imageLiteral(resourceName: "list"), for: .normal)
        }
    }
    
    lazy var formatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(self.isGridView ? #imageLiteral(resourceName: "postview") :#imageLiteral(resourceName: "list"), for: .normal)
        button.addTarget(self, action: #selector(changeView), for: .touchUpInside)
        button.tintColor = UIColor.legitColor()
        return button
    }()
    
    func changeView(){
        if isGridView{
            self.isGridView = false
            delegate?.didChangeToPostView()
        } else {
            self.isGridView = true
            delegate?.didChangeToListView()
        }
    }
    
    
    // Filter Button
    
    var isFiltering: Bool = false {
        didSet{
            filterButton.backgroundColor = isFiltering ? UIColor.legitColor() : UIColor.clear
        }
    }
    
    lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "filter").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(openFilter), for: .touchUpInside)
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.clipsToBounds = true
        return button
    }()
    
    func openFilter(){
        self.delegate?.openFilter()
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
    // Setup Filter View
        
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
        
        setupRankSegmentControl()
        
        headerSortSegment = UISegmentedControl(items: rankSortOptions)
        headerSortSegment.selectedSegmentIndex = rankSortOptions.index(of: self.selectedRank)!
        headerSortSegment.addTarget(self, action: #selector(selectSort), for: .valueChanged)
        headerSortSegment.tintColor = UIColor(hexColor: "107896")
        headerSortSegment.isUserInteractionEnabled = true
        
        
        addSubview(headerSortSegment)
        headerSortSegment.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: formatButton.leftAnchor, paddingTop: 5, paddingLeft: 3, paddingBottom: 5, paddingRight: 5, width: self.frame.width/2, height: 0)
        
//        addSubview(rankButton)
//        rankButton.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 3, paddingBottom: 1, paddingRight: 1, width: 0, height: 0)
//        rankButton.widthAnchor.constraint(equalTo: rankButton.heightAnchor, multiplier: 1).isActive = true
//        //        formatButton.layer.cornerRadius = formatButton.frame.width/2
//        rankButton.layer.masksToBounds = true
        
        addSubview(rankLabel)
        rankLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: headerSortSegment.leftAnchor, paddingTop: 1, paddingLeft: 10, paddingBottom: 1, paddingRight: 1, width: 0, height: 0)
        rankLabel.layer.masksToBounds = true
        
        
        

    }
    
    func selectSort(sender: UISegmentedControl) {
        
        self.selectedRank = rankSortOptions[sender.selectedSegmentIndex]
//        delegate?.headerSortSelected(sort: self.selectedSort)
        print("Selected Sort is ",self.selectedRank)
    }
    
    func setupRankSegmentControl(){
        self.rankSegmentControl = UISegmentedControl(items: rankSortOptions)
        
        self.rankSegmentControl.setImage(#imageLiteral(resourceName: "cred_unfilled").withRenderingMode(.alwaysOriginal), forSegmentAt: 0)
        self.rankSegmentControl.setImage(#imageLiteral(resourceName: "bookmark_unfilled").withRenderingMode(.alwaysOriginal), forSegmentAt: 1)
        self.rankSegmentControl.setImage(#imageLiteral(resourceName: "send2").withRenderingMode(.alwaysOriginal), forSegmentAt: 2)
        self.rankSegmentControl.addTarget(self, action: #selector(selectRank), for: .valueChanged)
        self.rankSegmentControl.tintColor = UIColor.legitColor()
        self.rankSegmentControl.selectedSegmentIndex = 0
        
    }
    
    func selectRank(sender: UISegmentedControl) {
        self.selectedRank = rankSortOptions[sender.selectedSegmentIndex]
        print("Selected Rank is ",self.selectedRank)
        
        rankSegmentControl.setImage(#imageLiteral(resourceName: "cred_unfilled").withRenderingMode(.alwaysOriginal), forSegmentAt: 0)
        rankSegmentControl.setImage(#imageLiteral(resourceName: "bookmark_unfilled").withRenderingMode(.alwaysOriginal), forSegmentAt: 1)
        rankSegmentControl.setImage(#imageLiteral(resourceName: "send2").withRenderingMode(.alwaysOriginal), forSegmentAt: 2)
        
        if sender.selectedSegmentIndex == 0 {
            rankSegmentControl.setImage(#imageLiteral(resourceName: "cred_filled").withRenderingMode(.alwaysOriginal), forSegmentAt: 0)
        }  else if sender.selectedSegmentIndex == 1 {
            rankSegmentControl.setImage(#imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal), forSegmentAt: 1)
        } else if sender.selectedSegmentIndex == 1 {
            rankSegmentControl.setImage(#imageLiteral(resourceName: "send_filled").withRenderingMode(.alwaysOriginal), forSegmentAt: 1)
        }
        
        delegate?.headerRankSelected(rank: self.selectedRank)
    }
    func setupRankSortSegment() {
        let appearance = SMSegmentAppearance()
        appearance.segmentOnSelectionColour = UIColor.legitColor()
        appearance.segmentOffSelectionColour = UIColor.white
        appearance.titleOnSelectionFont = UIFont.systemFont(ofSize: 12.0)
        appearance.titleOffSelectionFont = UIFont.systemFont(ofSize: 12.0)
        appearance.contentVerticalMargin = 10.0
        
        
        let segmentFrame = CGRect(x: 0, y: 0, width: (self.frame.size.width/3), height: self.frame.size.height)
        self.rankSegmentView = SMSegmentView(frame: segmentFrame, dividerColour: UIColor(white: 0.95, alpha: 0.3), dividerWidth: 1.0, segmentAppearance: appearance)
        self.rankSegmentView.backgroundColor = UIColor.clear
        
        self.rankSegmentView.layer.cornerRadius = 5.0
        self.rankSegmentView.layer.borderColor = UIColor.black.cgColor
        self.rankSegmentView.layer.borderWidth = 1.0
        
        self.rankSegmentView.addSegmentWithTitle("", onSelectionImage: #imageLiteral(resourceName: "cred_filled"), offSelectionImage: #imageLiteral(resourceName: "cred_unfilled"))
        self.rankSegmentView.addSegmentWithTitle("", onSelectionImage: #imageLiteral(resourceName: "bookmark_filled"), offSelectionImage: #imageLiteral(resourceName: "bookmark_unfilled"))
        self.rankSegmentView.addSegmentWithTitle("", onSelectionImage: #imageLiteral(resourceName: "send_filled"), offSelectionImage: #imageLiteral(resourceName: "send2"))
        
        self.rankSegmentView.addTarget(self, action: #selector(selectSegmentInSegmentView(segmentView:)), for: .valueChanged)
        
        
        // Set segment with index 0 as selected by default
        self.rankSegmentView.selectedSegmentIndex = rankSortOptions.index(of: defaultRank)!
        
    }
    
    func selectSegmentInSegmentView(segmentView: SMSegmentView) {
        
        if selectedRank != rankSortOptions[segmentView.selectedSegmentIndex] {
            selectedRank = rankSortOptions[segmentView.selectedSegmentIndex]
            print("Selected Rank By \(selectedRank)")
            
            // Refreshs Post without clearing filters
//            self.refreshPosts()
        }
    }
//
//    func selectSort(sender: UISegmentedControl) {
//        self.selectedSort = HeaderSortOptions[sender.selectedSegmentIndex]
//        delegate?.headerSortSelected(sort: self.selectedSort)
//        print("Selected Sort is ",self.selectedSort)
//    }
//
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}

