//
//  BookmarkController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/22/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import CoreGraphics
import GeoFire

class BookMarkController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    let bookmarkCellId = "bookmarkCellId"
    let homePostCellId = "homePostCellId"
    
    let geoFilterRange = ["ALL","500", "1000", "2500", "5000"]
    let searchBarPlaceholderText = "Search for Caption or Emoji 😍🐮🍔🇺🇸🔥"
    let currentLocation: CLLocation? = CLLocation(latitude: 41.973735, longitude: -87.667751)
    
    
    var userId:String?
    var allPosts = [Post]()
    var filteredPosts = [Post]()
    
    var isGridView = true
    
    
    lazy var filterBar: UIView = {
        let sb = UIView()
        sb.backgroundColor = UIColor.lightGray
        return sb
    }()

    lazy var layoutBar: UIView = {
        let sv = UIView()

        return sv
    }()
    
    
    lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .yellow
        return cv
    }()
    
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
        isGridView = true
        collectionView.reloadData()
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
        isGridView = false
        collectionView.reloadData()
    }
    


    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        view.backgroundColor = .white
        collectionView.backgroundColor = .white
        
        //collectionView.register(BookmarkHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "bookmarkHeaderId")
        
        collectionView.register(BookmarkPhotoCell.self, forCellWithReuseIdentifier: bookmarkCellId)
        collectionView.register(HomePostCell.self, forCellWithReuseIdentifier: homePostCellId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
        
        self.navigationItem.title = "Bookmarks"

        view.addSubview(filterBar)
        filterBar.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        setupFilterBar()
        setupGeoPicker()

        view.addSubview(layoutBar)
        layoutBar.anchor(top: filterBar.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        layoutBar.backgroundColor = .white

        setupBottomToolbar()
        
        view.addSubview(collectionView)
        collectionView.anchor(top: layoutBar.bottomAnchor , left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        fetchBookmarkPosts()
        
    }
    
    
    fileprivate func setupFilterBar() {
        

        filterBar.addSubview(geoFilterButton)
        filterBar.addSubview(searchBar)
        filterBar.addSubview(dummyTextView)
        
        geoFilterButton.anchor(top: filterBar.topAnchor, left: nil, bottom: filterBar.bottomAnchor, right: filterBar.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 100, height: 0)
        
        searchBar.anchor(top: filterBar.topAnchor, left: filterBar.leftAnchor, bottom: filterBar.bottomAnchor, right: geoFilterButton.leftAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, paddingRight: 8, width: 0, height: 0)
        
    }
    
    
    
    
    fileprivate func setupBottomToolbar() {
        

        let stackView = UIStackView(arrangedSubviews: [gridButton, listButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        
        
        
        let topDividerView = UIView()
        topDividerView.backgroundColor = UIColor.lightGray
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor.lightGray
        
        view.addSubview(stackView)
        view.addSubview(topDividerView)
        view.addSubview(bottomDividerView)

        stackView.anchor(top: layoutBar.topAnchor, left: layoutBar.leftAnchor, bottom: layoutBar.bottomAnchor, right: layoutBar.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        topDividerView.anchor(top: stackView.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        bottomDividerView.anchor(top: stackView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
    }
    
    
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
        
        filterPosts(searchText: searchBar.text!, range: (geoFilterButton.titleLabel?.text)!)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        
    }
    
    func filterPosts(searchText: String?, range: String?) {
     
        filterPostByCaption(searchText)
        filterNearbyPost(range)
        
    }
    
    func filterPostByCaption(_ string: String?) {
        
        guard let searchedText = string else {
            filteredPosts = allPosts
            self.collectionView.reloadData()
            return
        }
        print(searchedText)
        
        if searchedText.isEmpty {
            filteredPosts = allPosts
        } else {
            
            //Makes everything case insensitive
            filteredPosts = self.allPosts.filter { (post) -> Bool in
                return post.caption.lowercased().contains(searchedText.lowercased()) || post.emoji.contains(searchedText.lowercased())
            }
            self.collectionView.reloadData()
        }
    }
    
    func filterNearbyPost(_ string: String?){
        
        let ref = Database.database().reference().child("postlocations")
        let geoFire = GeoFire(firebaseRef: ref)
//        let currentLocation = CLLocation(latitude: 41.973735, longitude: -87.667751)
        
    
        
        var geoFilteredPosts = [Post]()
        
        guard let filterDistance = Double(string!) else {
            print("No Distance Number")
            return}
        
        let circleQuery = geoFire?.query(at: UserLocation.currentLocation, withRadius: filterDistance)
        circleQuery?.observe(.keyEntered, with: { (key, location) in
            print(key)
            var geoFilteredPost = self.filteredPosts.filter { (post) -> Bool in
                return post.id == key
            }
            
            if geoFilteredPost != nil && geoFilteredPost.count > 0 {
                geoFilteredPost[0].locationGPS = location
                geoFilteredPost[0].distance = Double((location?.distance(from: UserLocation.currentLocation))!)
                
            }
            
            print(geoFilteredPost)
            geoFilteredPosts += geoFilteredPost
            
        })
        
        circleQuery?.observeReady({
            self.filteredPosts = geoFilteredPosts.sorted(by: { (p1, p2) -> Bool in
                p1.distance!.isLess(than: p2.distance!)
            })
            self.collectionView.reloadData()
        })
        
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
        filterPosts(searchText: searchBar.text!, range: (geoFilterButton.titleLabel?.text)!)
        
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
    

    

    
    func fetchBookmarkPosts() {
        
        guard let uid = Auth.auth().currentUser?.uid  else {return}
        let ref = Database.database().reference().child("bookmarks").child(uid)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            //print(snapshot.value)
            
            
            guard let dictionaries = snapshot.value as? [String: Any] else {return}
            
            dictionaries.forEach({ (key,value) in
            
                guard let dictionary = value as? [String: Any] else {return}
                if let value = dictionary["bookmarked"] as? Int, value == 1 {
                
                    if let creatorUID = dictionary["creatorUID"] as? String {
                        
                        Database.fetchPostWithUIDAndPostID(creatoruid: creatorUID, postId: key, completion: { (post) in
                            self.allPosts.append(post)
                            self.filteredPosts = self.allPosts
                            self.collectionView.reloadData()
                            
                        })
                    }
                }
            })
        })
    }
    
    func handleRefresh() {
        
        allPosts.removeAll()
        filteredPosts.removeAll()
        self.searchBar.text = ""
        self.geoFilterButton.setTitle(geoFilterRange[0], for: .normal)
        fetchBookmarkPosts()
        self.collectionView.refreshControl?.endRefreshing()
        print("Refresh Home Feed")
    }
    
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredPosts.count
    }
    
     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if isGridView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: bookmarkCellId, for: indexPath) as! BookmarkPhotoCell
            cell.post = filteredPosts[indexPath.item]

            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: homePostCellId, for: indexPath) as! HomePostCell
            cell.post = filteredPosts[indexPath.item]
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if isGridView {

            return CGSize(width: view.frame.width, height: 150)
        } else {
            var height: CGFloat = 40 + 8 + 8 //username userprofileimageview
            height += view.frame.width
            height += 50
            height += 60
            
            return CGSize(width: view.frame.width, height: height)
        }
        
    }
    
//     func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "bookmarkHeaderId", for: indexPath) as! BookmarkHeader
//        
//        header.delegate = self
//        
//        return header
//        
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: view.frame.width, height: 100)
//    }
    
}
