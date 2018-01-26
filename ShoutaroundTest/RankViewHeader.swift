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
import CoreLocation

protocol RankViewHeaderDelegate {
    func didChangeToListView()
    func didChangeToGridView()
    func headerRankSelected(rank: String)
    func rangeSelected(range: String)
}


class RankViewHeader: UICollectionViewCell, UIGestureRecognizerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
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
            rankLabel.text = "Top By \(self.selectedRank)"
            rankLabel.adjustsFontSizeToFitWidth = true
        }
    }
    
    
// Rank Range
    var selectedRangeOptions = rankRangeDefaultOptions
    var selectedLocation: CLLocation? = nil {
        didSet{
            rangeButton.setImage((self.selectedLocation == nil) ? #imageLiteral(resourceName: "ranking").withRenderingMode(.alwaysOriginal) :#imageLiteral(resourceName: "GeoFence").withRenderingMode(.alwaysOriginal), for: .normal)
        }
    }
    
    var selectedRange: String? = globalRangeDefault {
        didSet{
            if selectedRange == nil {
                selectedRange = globalRangeDefault
            }
            rangeButton.setImage((self.selectedRange == globalRangeDefault) ? #imageLiteral(resourceName: "ranking").withRenderingMode(.alwaysOriginal) :#imageLiteral(resourceName: "GeoFence").withRenderingMode(.alwaysOriginal), for: .normal)
        }
    }
    
    lazy var rangeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage((self.selectedRange == globalRangeDefault) ? #imageLiteral(resourceName: "ranking").withRenderingMode(.alwaysOriginal) :#imageLiteral(resourceName: "GeoFence").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(activateRange), for: .touchUpInside)
        return button
    }()
    
    lazy var rankLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Top 250"
        ul.isUserInteractionEnabled = true
        ul.font = UIFont.boldSystemFont(ofSize: 12)
        ul.numberOfLines = 0
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
    var isListView = false {
        didSet{
            formatButton.setImage(self.isListView ? #imageLiteral(resourceName: "list"):#imageLiteral(resourceName: "grid"), for: .normal)
        }
    }
    
    lazy var formatButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(changeView), for: .touchUpInside)
        button.tintColor = UIColor.legitColor()
        return button
    }()

    
    func changeView(){
        if isListView{
            self.isListView = false
            delegate?.didChangeToGridView()
        } else {
            self.isListView = true
            delegate?.didChangeToListView()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
    // Setup Filter View
        
        addSubview(formatButton)
        formatButton.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 1, paddingRight: 3, width: 0, height: 0)
        formatButton.widthAnchor.constraint(equalTo: formatButton.heightAnchor, multiplier: 1).isActive = true
        //        formatButton.layer.cornerRadius = formatButton.frame.width/2
        formatButton.layer.masksToBounds = true
        
        setupRangePicker()
        addSubview(rangeButton)
        rangeButton.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 1, paddingBottom: 1, paddingRight: 1, width: 0, height: 0)
        rangeButton.widthAnchor.constraint(equalTo: rangeButton.heightAnchor, multiplier: 1).isActive = true
        //        formatButton.layer.cornerRadius = formatButton.frame.width/2
        rangeButton.layer.masksToBounds = true

        

        
        setupRankSegmentControl()
        addSubview(rankSegmentControl)
        rankSegmentControl.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: formatButton.leftAnchor, paddingTop: 5, paddingLeft: 3, paddingBottom: 5, paddingRight: 5, width: self.frame.width/2, height: 0)
        
        addSubview(rankLabel)
        rankLabel.anchor(top: topAnchor, left: rangeButton.rightAnchor, bottom: bottomAnchor, right: rankSegmentControl.leftAnchor, paddingTop: 1, paddingLeft: 1, paddingBottom: 1, paddingRight: 1, width: 0, height: 0)
        rankLabel.layer.masksToBounds = true

    }
    
    func setupRankSegmentControl(){
        self.rankSegmentControl = UISegmentedControl(items: rankSortOptions)
        
        self.rankSegmentControl.setImage(#imageLiteral(resourceName: "cred_unfilled").withRenderingMode(.alwaysOriginal), forSegmentAt: 0)
        self.rankSegmentControl.setImage(#imageLiteral(resourceName: "bookmark_unfilled").withRenderingMode(.alwaysOriginal), forSegmentAt: 1)
        self.rankSegmentControl.setImage(#imageLiteral(resourceName: "send2").withRenderingMode(.alwaysOriginal), forSegmentAt: 2)
        self.rankSegmentControl.addTarget(self, action: #selector(selectRank), for: .valueChanged)
        self.rankSegmentControl.tintColor = UIColor.legitColor()
        self.rankSegmentControl.selectedSegmentIndex = 0
        self.selectRank(sender: self.rankSegmentControl)
        
    }
    
    func selectRank(sender: UISegmentedControl) {
        self.selectedRank = rankSortOptions[sender.selectedSegmentIndex]
        print("Selected Rank is \(self.selectedRank)")
        
        rankSegmentControl.setImage(#imageLiteral(resourceName: "cred_unfilled").withRenderingMode(.alwaysOriginal), forSegmentAt: 0)
        rankSegmentControl.setImage(#imageLiteral(resourceName: "bookmark_unfilled").withRenderingMode(.alwaysOriginal), forSegmentAt: 1)
        rankSegmentControl.setImage(#imageLiteral(resourceName: "send2").withRenderingMode(.alwaysOriginal), forSegmentAt: 2)
        
        if sender.selectedSegmentIndex == 0 {
            rankSegmentControl.setImage(#imageLiteral(resourceName: "cred_filled").withRenderingMode(.alwaysOriginal), forSegmentAt: 0)
        }  else if sender.selectedSegmentIndex == 1 {
            rankSegmentControl.setImage(#imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal), forSegmentAt: 1)
        } else if sender.selectedSegmentIndex == 2 {
            rankSegmentControl.setImage(#imageLiteral(resourceName: "send_filled").withRenderingMode(.alwaysOriginal), forSegmentAt: 2)
        }
        
        delegate?.headerRankSelected(rank: self.selectedRank)
    }
    
    // Set Up Range Picker for Distance Filtering
    
    lazy var dummyTextView: UITextView = {
        let tv = UITextView()
        return tv
    }()
    
    var pickerView: UIPickerView = {
        let pv = UIPickerView()
        pv.backgroundColor = .white
        pv.showsSelectionIndicator = true
        return pv
    }()
    
    func setupRangePicker() {
        var toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.bordered, target: self, action: Selector("donePicker"))
        doneButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.legitColor()], for: .normal)
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.bordered, target: self, action: Selector("cancelPicker"))
        cancelButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.red], for: .normal)

        var toolbarTitle = UILabel()
        toolbarTitle.text = "Select Range"
        toolbarTitle.textAlignment = NSTextAlignment.center
        let toolbarTitleButton = UIBarButtonItem(customView: toolbarTitle)
        
        let space1Button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let space2Button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([cancelButton,space1Button, toolbarTitleButton,space2Button, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        
        pickerView.delegate = self
        pickerView.dataSource = self
        self.dummyTextView.inputView = pickerView
        self.dummyTextView.inputAccessoryView = toolBar
        self.addSubview(dummyTextView)
    }
    
    // UIPicker Delegate Functions
    
    func activateRange() {
        let rangeIndex = selectedRangeOptions.index(of: self.selectedRange!)
        pickerView.selectRow(rangeIndex!, inComponent: 0, animated: false)
        dummyTextView.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.1)
    }
    
    func donePicker(){
        self.selectedRange = selectedRangeOptions[pickerView.selectedRow(inComponent: 0)]
        print("Filter Range Selected: \(self.selectedRange)")
        dummyTextView.resignFirstResponder()
        delegate?.rangeSelected(range: self.selectedRange!)
    }
    
    func cancelPicker(){
        dummyTextView.resignFirstResponder()
    }
    
    
    // UIPicker DataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
        
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return selectedRangeOptions.count
    }
    
    // UIPicker Delegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        var options = selectedRangeOptions[row]
        if options != globalRangeDefault {
            // Add Miles to end if not Global
            options = options + " mi"
        }
        
        return options
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // If Select some number
//        self.selectedRange = selectedRangeOptions[row]
    }

    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}

