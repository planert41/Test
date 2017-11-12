//

//  UIPicker.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//
//
//import Foundation




//                Only Delete Last Emoji
//                let emojiChars = captionTextView.text.indicesOf(string: pressedEmoji)
//                let lastEmojiChar = emojiChars[emojiChars.count - 1]
//                var temp =  captionTextView.text
//                let index = temp?.index((temp?.startIndex)!, offsetBy: lastEmojiChar)
//                captionTextView.text.remove(at: index!)

// cell.contentView.backgroundColor = UIColor.blue
//
//            if let emojiChar = self.captionTextView.text.range(of: pressedEmoji) {
//                cell.backgroundColor  = UIColor.rgb(red: 149, green: 204, blue: 244)
//            }   else {
//                cell.backgroundColor = UIColor.white
//            }

//        if emojiViews!.contains(collectionView) {
//
//            let cell = collectionView.cellForItem(at: indexPath) as! UploadEmojiCell
//           // cell.contentView.backgroundColor = UIColor.blue
//            self.emojiCheck(cell.uploadEmojis.text)
//
//        }


// Detect Emojis in textview

//    func textFieldDidChange(_ textField: UITextField) {
//
//        let strLast5 =  textView.text.characters.substring(from: min(0,textView.text.characters.count - 5))
//
//        textView.text.substring(from: 5)
//
//        print(strLast5)
//
//
//    }


//        view.addSubview(Emoji1CollectionView)
//        view.addSubview(Emoji2CollectionView)
//        view.addSubview(Emoji3CollectionView)
//        view.addSubview(Emoji4CollectionView)
//
//
//        emojiViews = [Emoji1CollectionView, Emoji2CollectionView, Emoji3CollectionView, Emoji4CollectionView]
//
//        for (index,views) in emojiViews!.enumerated() {
//
//            if index == 0 {
//                views.anchor(top: EmojiContainerView.topAnchor, left: EmojiContainerView.leftAnchor, bottom: nil, right: EmojiContainerView.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: EmojiSize.width+2)
//            } else {
//                views.anchor(top: emojiViews![index-1].bottomAnchor, left: EmojiContainerView.leftAnchor, bottom: nil, right: EmojiContainerView.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: EmojiSize.width+2)
//            }
//            views.backgroundColor = UIColor.white
//            views.register(UploadEmojiCell.self, forCellWithReuseIdentifier: emojiCellID)
//            views.delegate = self
//            views.dataSource = self
//            views.allowsMultipleSelection = true
//
//        }






//    func handleMessage(){
//        guard let post = self.post else {return}
//
//        print("emailtest")
//        let mailgun = Mailgun.client(withDomain: "sandbox036bf1de5ba44e7e8ad4f19b9cc5b7d8.mailgun.org", apiKey: "key-2562988360d4f7f8a1fcc6f3647b446a")
//
//        let message = MGMessage(from:"Excited User <someone@sample.org>",
//                                to:"Jay Baird <planert41@gmail.com>",
//                                subject:"Mailgun is awesome!",
//                                body:("<html>Inline image here: <img src=cid:image01.jpg></html>"))!
//
//
//
//        let postImage = CustomImageView()
//        postImage.loadImage(urlString: post.imageUrl)
//
//        //        message.add(postImage.image, withName: "image01", type: .JPEGFileType, inline: true)
//        message.html = "<html>Inline image here: <img src="+post.imageUrl+" width = \"25%\" height = \"25%\"/></html>"
//
//
//        // someImage: UIImage
//        // type can be either .JPEGFileType or .PNGFileType
//        // message.add(postImage.image, withName: "image01", type:.PNGFileType)
//
//
//        mailgun?.send(message, success: { (success) in
//            print("success sending email")
//        }, failure: { (error) in
//            print(error)
//        })
//    }






// Detect Backspace = isBackSpace == -92
// When hit backspace, compare new words to prev saved words. if deleted string matches an emoji, then we take emoji out
//
//            else if (isBackSpace == -92) {
//                deletedWords = textView.text!.components(separatedBy: " ")
//                let deletedWordArray = Array(Set(self.savedWords).subtracting(self.deletedWords))
//                //                print(savedWords)
//                //                print(newWords)
//
//                if deletedWordArray.count != 0 {
//                    self.deletedWord = deletedWordArray[0]
//                    print("Deleted Word",self.deletedWord)
//
//                }
//
//                var emojiLookup = EmojiDictionary.key(forValue: self.deletedWord.lowercased())
//                if emojiLookup != nil && self.selectedEmojis.contains(emojiLookup!) && textView.text!.contains(emojiLookup!) == false {
//                    self.deletedWord = ""
//                    self.emojiCheck(emojiLookup)
//                }
//            }
//
//func emojiCheck(_ emoji: String?){
//    
//    
//    // Check if selected Emojis already have emoji
//    
//    //        print(emoji, emoji.unicodeScalars, emoji.containsRatingEmoji)
//    
//    guard let emoji = emoji else {return}
//    
//    var selectedEmojis = self.selectedEmojis
//    
//    if selectedEmojis != nil {
//        
//        if (selectedEmojis?[0].containsRatingEmoji)! {
//            self.ratingEmoji = selectedEmojis?[0]
//            self.nonRatingEmoji = selectedEmojis
//            self.nonRatingEmoji?.remove(at: 0)
//        } else {
//            self.nonRatingEmoji = selectedEmojis
//        }
//    }
//    
//    
//    if emoji.containsOnlyEmoji == false {
//        return
//    }
//        
//    else if emoji.containsRatingEmoji {
//        if self.ratingEmoji == emoji {
//            // Remove Rating Emoji if its the same rating emoji
//            self.ratingEmoji = nil
//        } else {
//            // Replace Rating Emoji with New Rating Emoji
//            self.ratingEmoji = emoji
//            //    self.selectedEmojis = self.ratingEmoji! + self.nonratingEmoji!
//        }
//    }
//        
//    else if emoji.containsOnlyEmoji && !emoji.containsRatingEmoji && (self.nonRatingEmoji?.joined().characters.count)! < self.nonRatingEmojiLimit {
//        
//        if self.nonRatingEmoji?.contains(emoji){
//            self.nonRatingEmoji?.remove(at: self.nonRatingEmoji?.index(of: emoji))
//        }
//        
//        
//        if self.nonRatingEmoji == nil {
//            self.nonRatingEmoji = emoji
//        } else {
//            self.nonRatingEmoji = self.nonRatingEmoji! + emoji
//        }
//        // self.selectedEmojis = self.ratingEmoji! + self.nonratingEmoji!
//    }
//    
//    
//    print("selected emojis", self.selectedEmojis)
//    print("rating emoji", ratingEmoji)
//    print("nonrating emoji", nonRatingEmoji)
//    print("first emoji", firstEmoji, firstEmoji.containsRatingEmoji)
//    
//}
//
//
//    func fetchBookmarkPosts() {
//
//        guard let uid = Auth.auth().currentUser?.uid  else {return}
//        let ref = Database.database().reference().child("bookmarks").child(uid)
//
//        ref.observeSingleEvent(of: .value, with: {(snapshot) in
//            //print(snapshot.value)
//
//
//            guard let dictionaries = snapshot.value as? [String: Any] else {return}
//
//            dictionaries.forEach({ (key,value) in
//
//                guard let dictionary = value as? [String: Any] else {return}
//                if let value = dictionary["bookmarked"] as? Int, value == 1 {
//
//                    if let creatorUID = dictionary["creatorUID"] as? String {
//
//                        Database.fetchPostWithUIDAndPostID(creatoruid: creatorUID, postId: key, completion: { (post) in
//
//                            self.allBookmarks.append(post)
//                            self.displayedBookmarks = self.allBookmarks
//                            self.collectionView.reloadData()
//
//                        })
//                    }
//                }
//            })
//        })
//    }


//
//fileprivate func fetchUserPosts() {
//    
//    guard let uid = Auth.auth().currentUser?.uid  else {return}
//    
//    Database.fetchUserWithUID(uid: uid) { (user) in
//        self.fetchPostsWithUser(user: user)
//    }
//    
//}
//
//
//fileprivate func fetchPostsWithUser(user: User){
//    
//    Database.fetchAllPostWithUID(creatoruid: user.uid) { (fetchedPosts) in
//        self.fetchedPosts = self.fetchedPosts + fetchedPosts
//        self.fetchedPosts.sort(by: { (p1, p2) -> Bool in
//            return p1.creationDate.compare(p2.creationDate) == .orderedDescending
//        })
//        
//        self.displayedPosts = self.fetchedPosts
//        self.collectionView?.reloadData()
//    }
//    
//}


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


