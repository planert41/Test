//
//  UIPicker.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation

//
//
//
//fileprivate func fetchFollowingUserIds() {
//    
//    guard let uid = Auth.auth().currentUser?.uid else {return}
//    
//    Database.database().reference().child("following").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
//        
//        var followingUsers: [String] = []
//        
//        guard let userIdsDictionary = snapshot.value as? [String: Any] else {return}
//        userIdsDictionary.forEach({ (key,value) in
//            
//            followingUsers.append(key)
//            Database.fetchUserWithUID(uid: key, completion: { (user) in
//                self.fetchPostsWithUser(user: user)
//            })
//        })
//        
//        CurrentUser.followingUids = followingUsers
//        
//    }) { (err) in
//        print("Failed to fetch following user ids:", err)
//    }
//}



// Filter Functions
//
//func finalFilterPost(filterString: String?, filterLocation: CLLocation?, filterRange: String?, filterGroup: String?){
//    
//    self.resultSearchController?.searchBar.text = filterString
//    
//    self.filterPostByCaption(filterString?.removeDuplicates){
//        
//        self.filterPostByLocation(filterLocation: filterLocation, filterRange: filterRange){
//            self.filterPostByGroup(filterGroup: self.filterGroup!){
//                self.collectionView?.reloadData()
//            }
//        }
//    }
//    
//    if self.collectionView?.numberOfItems(inSection: 0) != 0 {
//        let indexPath = IndexPath(item: 0, section: 0)
//        self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
//        self.noResultsLabel.text = "Loading"
//        
//    } else {
//        self.noResultsLabel.text = "No Results"
//    }
//}
//
//func filterPostByCaption(_ string: String?, completion: () -> ()) {
//    
//    guard let searchedText = string else {
//        displayedPosts = fetchedPosts
//        print("No Search Term")
//        completion()
//        return
//    }
//    
//    if searchedText.isEmpty || searchedText == "" {
//        displayedPosts = fetchedPosts
//        print("No Search Term")
//        completion()
//        return
//    } else {
//        
//        print("Search Term Was", searchedText)
//        //Makes everything case insensitive
//        displayedPosts = self.fetchedPosts.filter { (post) -> Bool in
//            return post.caption.lowercased().contains(searchedText.lowercased()) || post.emoji.contains(searchedText.lowercased()) || post.locationName.contains(searchedText.lowercased()) || post.locationAdress.contains(searchedText.lowercased())
//        }
//        completion()
//        //            collectionView?.reloadData()
//    }
//}
//
//func filterPostByLocation(filterLocation: CLLocation?, filterRange: String?, completion: @escaping () -> ()){
//    
//    let ref = Database.database().reference().child("postlocations")
//    let geoFire = GeoFire(firebaseRef: ref)
//    
//    var geoFilteredPosts = [Post]()
//    
//    let filterRangeCheck = Double(filterRange!)
//    guard let filterDistance = filterRangeCheck else {
//        print("Invalid Distance Number or Non Distance")
//        return
//    }
//    
//    //        let when = DispatchTime.now() + 0.5 // change 2 to desired number of seconds
//    //        DispatchQueue.main.asyncAfter(deadline: when) {
//    
//    print("Current User Location Used for Post Filtering", filterLocation)
//    let circleQuery = geoFire?.query(at: filterLocation, withRadius: filterDistance)
//    circleQuery?.observe(.keyEntered, with: { (key, location) in
//        var geoFilteredPost: [Post] = self.displayedPosts.filter { (post) -> Bool in
//            return post.id == key
//        }
//        
//        if geoFilteredPost != nil && geoFilteredPost.count > 0 && geoFilteredPost[0].locationGPS != nil {
//            geoFilteredPost[0].locationGPS = location
//            geoFilteredPost[0].distance = Double((location?.distance(from: CurrentUser.currentLocation!))!)
//            geoFilteredPost[0].id = key
//        }
//        geoFilteredPosts += geoFilteredPost
//    })
//    
//    circleQuery?.observeReady({
//        self.displayedPosts = geoFilteredPosts.sorted(by: { (p1, p2) -> Bool in
//            p1.distance!.isLess(than: p2.distance!)
//        })
//        completion()
//    })
//    //        }
//}
//
//
//func filterPostByGroup(filterGroup: String, completion: () -> ()) {
//    
//    if filterGroup != self.defaultGroup {
//        var groupFilteredPost: [Post] = []
//        for userUid in self.groupUsersUids{
//            groupFilteredPost = self.displayedPosts.filter { (post) -> Bool in
//                return post.creatorUID == userUid
//            }
//            groupFilteredPost += groupFilteredPost
//        }
//        self.displayedPosts = groupFilteredPost
//    }
//    
//    completion()
//}
//
//



//                Old Code to allow refresh with filters on
//                if self.groupUsersFilter.count > 0 && self.isGroupUserFiltering {
//                    print(self.groupUsersFilter)
//                    print(key,value)
//                    if self.groupUsersFilter.contains(key){
//                        Database.fetchUserWithUID(uid: key, completion: { (user) in
//                            self.fetchPostsWithUser(user: user)
//                        })
//                    }
//                }
//                else {
//
//                    Database.fetchUserWithUID(uid: key, completion: { (user) in
//                    self.fetchPostsWithUser(user: user)
//                    })
//                }


//lazy var longPressGesture: UILongPressGestureRecognizer = {
//    
//    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(activateFilterRange))
//    longPressGesture.minimumPressDuration = 0.5 // 1 second press
//    longPressGesture.delegate = self
//    return longPressGesture
//}()


//lazy var dummyTextView: UITextView = {
//    let tv = UITextView()
//    return tv
//}()
//
//var pickerView: UIPickerView = {
//    let pv = UIPickerView()
//    pv.backgroundColor = .white
//    pv.showsSelectionIndicator = true
//    
//    return pv
//}()
//
//func setupGeoPicker() {
//    
//    
//    var toolBar = UIToolbar()
//    toolBar.barStyle = UIBarStyle.default
//    toolBar.isTranslucent = true
//    
//    toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
//    toolBar.sizeToFit()
//    
//    
//    let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.bordered, target: self, action: Selector("donePicker"))
//    let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
//    spaceButton.title = "Filter Range"
//    let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.bordered, target: self, action: Selector("cancelPicker"))
//    
//    toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
//    toolBar.isUserInteractionEnabled = true
//    
//    pickerView.delegate = self
//    pickerView.dataSource = self
//    self.dummyTextView.inputView = pickerView
//    self.dummyTextView.inputAccessoryView = toolBar
//}
//
//
//func donePicker(){
//    dummyTextView.resignFirstResponder()
//    filterPostByCaption(self.resultSearchController?.searchBar.text)
//    filterPostByLocation()
//    
//}
//
//func cancelPicker(){
//    dummyTextView.resignFirstResponder()
//}
//
//func activateFilterRange() {
//    
//    if self.filterRange != nil {
//        let rangeIndex = self.geoFilterRange.index(of: String(format:"%.1f", self.filterRange!))
//        pickerView.selectRow(rangeIndex!, inComponent: 0, animated: false)
//    }
//    dummyTextView.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.1)
//}
//
//// UIPicker DataSource
//func numberOfComponents(in pickerView: UIPickerView) -> Int {
//    
//    return 1
//    
//}
//func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//    return geoFilterRange.count
//}
//
//// UIPicker Delegate
//
//func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//    
//    if self.filterRange == Double(geoFilterRange[row]) {
//        
//        let rangeIndex = self.geoFilterRange.index(of: String(format:"%.1f", self.filterRange!))
//        pickerView.selectRow(rangeIndex!, inComponent: 0, animated: false)
//    }
//    
//    return geoFilterRange[row]
//}
//
//func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//    // If Select some number
//    if row > 0 {
//        filterRange = Double(geoFilterRange[row])
//    } else {
//        filterRange = nil
//    }
//    
//}

