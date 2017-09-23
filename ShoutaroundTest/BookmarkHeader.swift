//
//  BookmarkHeader.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/22/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit


protocol BookmarkHeaderDelegate {
    func didChangeToListView()
    func didChangeToGridView()
    func filterPosts(searchText: String?, range: String?)
}


class BookmarkHeader: UICollectionViewCell, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    var delegate: BookmarkHeaderDelegate?
    let geoFilterRange = ["ALL","500", "1000", "2500", "5000"]
    let searchBarPlaceholderText = "Search for Caption or Emoji 😍🐮🍔🇺🇸🔥"

    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        setupFilterBar()
        setupGeoPicker()
        setupBottomToolbar()
        
    
    }
    
    lazy var filterBar: UIView = {
        let sb = UIView()
        sb.backgroundColor = UIColor.lightGray
        return sb
    }()

// Setup for Search Button
    
    lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = self.searchBarPlaceholderText
        sb.barTintColor = .white
        sb.backgroundColor = .white
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        
        sb.delegate = self
        return sb
    }()
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        delegate?.filterPosts(searchText: searchBar.text, range: geoFilterButton.titleLabel?.text)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {

    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        
    }
    
// Setup for Picker
    
    
    lazy var geoFilterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(self.geoFilterRange[0], for: .normal)
        button.addTarget(self, action: #selector(filterRange), for: .touchUpInside)
        button.backgroundColor = .white
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.black.cgColor
        return button
    }()
    
    func filterRange() {
        dummyTextView.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.1)
    }
    
    
    lazy var dummyTextView: UITextView = {
        let button = UITextView()
        button.text = "1000"
        button.backgroundColor = .blue
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.black.cgColor
        return button
    }()
    
    
    func setupGeoPicker() {
        var pickerView = UIPickerView()
        pickerView.backgroundColor = .white
        pickerView.showsSelectionIndicator = true
        pickerView.dataSource = self
        pickerView.delegate = self
        
        var toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.bordered, target: self, action: Selector("donePicker"))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.bordered, target: self, action: Selector("cancelPicker"))
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        self.dummyTextView.inputView = pickerView
        self.dummyTextView.inputAccessoryView = toolBar
    }
    
    func donePicker(){
        dummyTextView.resignFirstResponder()
        delegate?.filterPosts(searchText: searchBar.text, range: geoFilterButton.titleLabel?.text)

    }
    
    func cancelPicker(){
        dummyTextView.resignFirstResponder()
    }

    
    // UIPicker DataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
        
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return geoFilterRange.count
    }
    
    // UIPicker Delegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return geoFilterRange[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.geoFilterButton.setTitle(geoFilterRange[row], for: .normal)
    }
    
    
    fileprivate func setupFilterBar() {

        addSubview(filterBar)
        filterBar.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        filterBar.addSubview(geoFilterButton)
        filterBar.addSubview(searchBar)
        filterBar.addSubview(dummyTextView)
        
        geoFilterButton.anchor(top: filterBar.topAnchor, left: nil, bottom: filterBar.bottomAnchor, right: filterBar.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 100, height: 0)
        
        searchBar.anchor(top: filterBar.topAnchor, left: filterBar.leftAnchor, bottom: filterBar.bottomAnchor, right: geoFilterButton.leftAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, paddingRight: 8, width: 0, height: 0)

    }
    
// Setup Bottom Grid/List Buttons
    
    lazy var gridButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "grid"), for: .normal)
        button.addTarget(self, action: #selector(handleChangetoGridView), for: .touchUpInside)
        return button
    }()
    
    func handleChangetoGridView() {
        gridButton.tintColor = UIColor.mainBlue()
        listButton.tintColor = UIColor(white: 0, alpha: 0.2)
        delegate?.didChangeToGridView()
    }
    
    lazy var listButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "list"), for: .normal)
        button.tintColor = UIColor(white: 0, alpha: 0.2)
        button.addTarget(self, action: #selector(handleChangetoListView), for: .touchUpInside)
        return button
    }()
    
    func handleChangetoListView() {
        listButton.tintColor = UIColor.mainBlue()
        gridButton.tintColor = UIColor(white: 0, alpha: 0.2)
        delegate?.didChangeToListView()
    }
    
    
    
    fileprivate func setupBottomToolbar() {
        
        let topDividerView = UIView()
        topDividerView.backgroundColor = UIColor.lightGray
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor.lightGray
        
        let stackView = UIStackView(arrangedSubviews: [gridButton, listButton])
        
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        
        addSubview(stackView)
        addSubview(topDividerView)
        addSubview(bottomDividerView)
        
        stackView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        topDividerView.anchor(top: stackView.topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        bottomDividerView.anchor(top: stackView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
}
