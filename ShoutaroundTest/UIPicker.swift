//

//  UIPicker.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

//
//static func checkPostForLikes(post: Post, completion: @escaping (Post) -> ()){
//    
//    guard let uid = Auth.auth().currentUser?.uid else {return}
//    var tempPost = post
//    
//    Database.database().reference().child("likes").child(post.id!).observeSingleEvent(of: .value, with: { (snapshot) in
//        
//        let post = snapshot.value as? [String: Any] ?? [:]
//        var likes: Dictionary<String, Int>
//        likes = post["likes"] as? [String : Int] ?? [:]
//        var likeCount = post["likeCount"] as? Int ?? 0
//        
//        
//        if likes[uid] == 1 {
//            tempPost.hasLiked = true
//        } else {
//            tempPost.hasLiked = false
//        }
//        
//        if tempPost.likeCount != likeCount {
//            // Calculated Bookmark Count Different from Database
//            tempPost.likeCount = likeCount
//            updateSocialCountsForPost(postId: tempPost.id, socialVariable: "likeCount", newCount: likeCount)
//        }
//        
//        
//        completion(tempPost)
//    }, withCancel: { (err) in
//        print("Failed to fetch bookmark info for post:", err)
//    })
//}

// OLD FILTERING
//        self.filterFetchedPosts {
//            self.sortFetchedPosts {
//                print("Finish Filter and Sorting Post")
//                NotificationCenter.default.post(name: HomeController.finishSortingFetchedPostsNotificationName, object: nil)
//            }
//        }
//func filterFetchedPosts(completion: @escaping () ->()){
//    // Filter Caption
//    if self.filterCaption != nil && self.filterCaption != "" {
//        guard let searchedText = self.filterCaption else {return}
//        self.fetchedPosts = self.fetchedPosts.filter { (post) -> Bool in
//            
//            let searchedEmoji = ReverseEmojiDictionary[searchedText.lowercased()] ?? ""
//            
//            return post.caption.lowercased().contains(searchedText.lowercased()) || post.emoji.contains(searchedText.lowercased()) || post.nonRatingEmojiTags.joined(separator: " ").lowercased().contains(searchedText.lowercased()) || post.nonRatingEmojiTags.joined(separator: " ").lowercased().contains(searchedEmoji) || post.locationName.lowercased().contains(searchedText.lowercased()) || post.locationAdress.lowercased().contains(searchedText.lowercased())
//        }
//        print("Filtered Post By Caption: \(searchedText): \(self.fetchedPosts.count)")
//        
//    }
//    
//    // Distances are updated in fetchallposts as they are filtered by distance
//    
//    // Filter Range
//    if self.filterLocation != nil && self.filterRange != nil {
//        self.fetchedPosts = self.fetchedPosts.filter { (post) -> Bool in
//            var filterDistance:Double = 99999999
//            if post.distance != nil {
//                filterDistance = post.distance!
//            }
//            return filterDistance <= (Double(self.filterRange!)! * 1000)
//        }
//        print("Filtered Post By Range: \(self.filterRange) AT \(self.filterLocation): \(self.fetchedPosts.count)")
//    }
//    
//    // Filter Rating
//    if self.filterMinRating != 0 {
//        self.fetchedPosts = self.fetchedPosts.filter { (post) -> Bool in
//            var filterRating:Double = 0
//            if post.rating != nil {
//                filterRating = post.rating!
//            }
//            return filterRating >= self.filterMinRating
//        }
//        print("Filtered Post By Min Rating: \(self.filterMinRating): \(self.fetchedPosts.count)")
//    }
//    
//    // Filter Type
//    if self.filterType != nil {
//        self.fetchedPosts = self.fetchedPosts.filter { (post) -> Bool in
//            return post.type == self.filterType
//        }
//        print("Filtered Post By Post Type: \(self.filterType): \(self.fetchedPosts.count)")
//    }
//    
//    // Filter Max Price
//    if self.filterMaxPrice != nil {
//        let maxPriceIndex = UploadPostPriceDefault.index(of: self.filterMaxPrice!)
//        let filterMaxPrice = UploadPostPriceDefault[0...maxPriceIndex!]
//        
//        self.fetchedPosts = self.fetchedPosts.filter { (post) -> Bool in
//            var filterPrice:String = "0"
//            if post.price != nil {
//                filterPrice = post.price!
//            }
//            return filterMaxPrice.contains(filterPrice)
//        }
//        print("Filtered Post By Max Price: \(self.filterMaxPrice): \(self.fetchedPosts.count)")
//    }
//    
//    completion()
//}
//
//
//
//func sortFetchedPosts(completion: @escaping () ->()){
//    print("Sort Posts: \(self.selectedHeaderSort)")
//    
//    // Recent
//    if self.selectedHeaderSort == HeaderSortOptions[0] {
//        self.fetchedPosts.sort(by: { (p1, p2) -> Bool in
//            return p1.creationDate.compare(p2.creationDate) == .orderedDescending
//        })
//        completion()
//    }
//        
//        // Nearest
//    else if self.selectedHeaderSort == HeaderSortOptions[1] {
//        // Check for current filter location
//        if self.filterLocation == nil {
//            print("Header Sort: Nearest, No Location, Finding Current Location")
//            LocationSingleton.sharedInstance.determineCurrentLocation()
//            
//            // Posts are refreshed with distances when filter location is updated
//            let when = DispatchTime.now() + 1 // change 2 to desired number of seconds
//            DispatchQueue.main.asyncAfter(deadline: when) {
//                self.fetchedPosts.sort(by: { (p1, p2) -> Bool in
//                    return (p1.distance! < p2.distance!)
//                })
//                completion()
//            }
//        } else {
//            // Distances are updated in fetchallposts as they are filtered by distance
//            self.fetchedPosts.sort(by: { (p1, p2) -> Bool in
//                return (p1.distance! < p2.distance!)
//            })
//            completion()
//        }
//    }
//        
//        //Trending
//    else if self.selectedHeaderSort == HeaderSortOptions[2] {
//        self.fetchedPosts.sort(by: { (p1, p2) -> Bool in
//            return (p1.voteCount > p2.voteCount)
//        })
//        completion()
//    }
//        
//        // ERROR - Invalid Sort
//    else {
//        print("Fetched Post Sort: ERROR, Invalid Sort")
//        completion()
//    }
//}



//
//import Foundation
// Add Tag Time
//        view.addSubview(timeIcon)
//        timeIcon.anchor(top: LocationContainerView.topAnchor, left: LocationContainerView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 30, height: 30)
//        view.addSubview(timeLabel)
//        timeLabel.anchor(top: LocationContainerView.topAnchor, left: timeIcon.rightAnchor, bottom: nil, right: LocationContainerView.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 40)
//        timeLabel.isUserInteractionEnabled = true
//        let TapGestureT = UITapGestureRecognizer(target: self, action: #selector(timeInput))
//        timeLabel.addGestureRecognizer(TapGestureT)
//        view.addSubview(timeCancelButton)
//        timeCancelButton.anchor(top: timeLabel.topAnchor, left: nil, bottom: timeLabel.bottomAnchor, right: timeLabel.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 20, height: 20)

//    let timeCancelButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setImage(#imageLiteral(resourceName: "cancel_shadow").withRenderingMode(.alwaysOriginal), for: .normal)
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.backgroundColor = UIColor.clear
//        button.layer.cornerRadius = 0.5 * button.bounds.size.width
//        button.layer.masksToBounds  = true
//        button.clipsToBounds = true
//        button.addTarget(self, action: #selector(cancelTime), for: .touchUpInside)
//        return button
//    } ()


//    func cancelTime(){
//        if selectTime != currentDateTime {
//            self.selectTime = currentDateTime
//            let formatter = DateFormatter()
//            formatter.dateFormat = "MMM d YYYY, h:mm a"
//            let attributedText = NSMutableAttributedString(string: formatter.string(from: currentDateTime), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor.mainBlue()])
//            self.timeLabel.attributedText = attributedText
//        } else {
//        selectTime = nil
//        }
//    }

//var toolBar: UIToolbar = {
//    let toolBar = UIToolbar()
//    toolBar.barStyle = .default
//    toolBar.isTranslucent = true
//    toolBar.tintColor = UIColor(red: 92/255, green: 216/255, blue: 255/255, alpha: 1)
//    toolBar.sizeToFit()
//    return toolBar
//}()
//
//func timeInput(){
//    
//    print("Time Input is activated")
//    self.datePicker.isHidden = false
//    self.toolBar.isHidden = false
//    
//    // Set some of UIDatePicker properties
//    datePicker.timeZone = NSTimeZone.local
//    datePicker.backgroundColor = UIColor.white
//    
//    // Adding Button ToolBar
//    let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneClick))
//    let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
//    let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelClick))
//    toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
//    toolBar.isUserInteractionEnabled = true
//    
//    // Add an event to call onDidChangeDate function when value is changed.
//    datePicker.addTarget(self, action: #selector(self.datePickerValueChanged(_:)), for: .valueChanged)
//    
//    // Add DataPicker to the view
//    self.view.addSubview(datePicker)
//    datePicker.anchor(top: nil, left: self.view.leftAnchor, bottom: self.view.bottomAnchor, right: self.view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 200)
//    self.view.addSubview(toolBar)
//    toolBar.anchor(top: nil, left: self.view.leftAnchor, bottom: datePicker.topAnchor, right: self.view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
//}
//
//
//func doneClick() {
//    let dateFormatter1 = DateFormatter()
//    self.selectTime = datePicker.date
//    self.toolBar.isHidden = true
//    self.datePicker.isHidden = true
//}
//func cancelClick() {
//    self.toolBar.isHidden = true
//    self.datePicker.isHidden = true
//}
//
//
//func datePickerValueChanged(_ sender: UIDatePicker){
//}


//
//
//let timeLabel: UILabel = {
//    let tv = LocationLabel()
//    tv.font = UIFont.systemFont(ofSize: 14)
//    tv.backgroundColor = UIColor(white: 0, alpha: 0.03)
//    tv.layer.borderWidth = 0.5
//    tv.layer.cornerRadius = 5
//    tv.isUserInteractionEnabled = true
//    let TapGesturet = UITapGestureRecognizer(target: self, action: #selector(timeInput))
//    tv.addGestureRecognizer(TapGesturet)
//    return tv
//}()
//
//
//let timeIcon: UIButton = {
//    let button = UIButton()
//    button.setImage(#imageLiteral(resourceName: "hours").withRenderingMode(.alwaysOriginal), for: .normal)
//    button.addTarget(self, action: #selector(timeIconPushed), for: .touchUpInside)
//    return button
//}()
//
//func timeIconPushed(){
//    self.selectTime = currentDateTime
//    let formatter = DateFormatter()
//    formatter.dateFormat = "MMM d YYYY, h:mm a"
//    let attributedText = NSMutableAttributedString(string: formatter.string(from: currentDateTime), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor.mainBlue()])
//    self.timeLabel.attributedText = attributedText
//}
//
//var datePicker: UIDatePicker = UIDatePicker()

//    func fetchBookmarkPosts(){
//
//        guard let uid = Auth.auth().currentUser?.uid  else {return}
//
//        Database.fetchAllBookmarkIdsForUID(uid: uid) { (bookmarkIds) in
//
//            for bookmarkId in bookmarkIds{
//                Database.fetchPostWithPostID(postId: bookmarkId.postId, completion: { (post, error) in
//                    if let error = error {
//                        print("Failed to fetch post for bookmarks: ",bookmarkId.postId , error)
//                        return
//                    }
//
//                    guard let post = post else {
//                        print("No Result for PostId: ", bookmarkId.postId)
//                        //Delete Bookmark since post is unavailable, Present Delete Alert
//
//                        let deleteAlert = UIAlertController(title: "Delete Bookmark", message: "Post Bookmarked on \(bookmarkId.bookmarkDate) Was Deleted", preferredStyle: UIAlertControllerStyle.alert)
//
//                        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
//                            // Delete Bookmark in Database
//                                Database.handleBookmark(postId: bookmarkId.postId, completion: {
//                                })
//                        }))
//
//                        self.present(deleteAlert, animated: true, completion: nil)
//                        return}
//
//
//                    let tempBookmark = Bookmark.init(bookmarkDate: bookmarkId.bookmarkDate, post: post)
//                    self.fetchedBookmarks.append(tempBookmark)
//                    self.fetchedBookmarks.sort(by: { (p1, p2) -> Bool in
//                        return p1.bookmarkDate.compare(p2.bookmarkDate) == .orderedDescending
//                    })
//                    self.displayedBookmarks = self.fetchedBookmarks
//                    self.collectionView.reloadData()
//
//                })
//            }
//        }
//
//
//
//    }
//


//        func fetchBookmarkPosts() {
//
//            guard let uid = Auth.auth().currentUser?.uid  else {return}
//            let ref = Database.database().reference().child("bookmarks").child(uid)
//
//            ref.observeSingleEvent(of: .value, with: {(snapshot) in
//                //print(snapshot.value)
//
//                guard let dictionaries = snapshot.value as? [String: Any] else {return}
//
//                dictionaries.forEach({ (key,value) in
//
//                    guard let dictionary = value as? [String: Any] else {return}
//                    if let value = dictionary["bookmarked"] as? Int, value == 1 {
//
//                        let bookmarkTime = dictionary["bookmarkDate"] as? Double ?? 0
//                        if let creatorUID = dictionary["creatorUID"] as? String {
//
//                        Database.fetchPostWithPostID(postId: key, completion: { (post, error) in
//
//                            if let error = error {
//                                print("Failed to fetch post for bookmarks: ",key , error)
//                                return
//                            }
//
//                            guard let post = post else {
//                                print("No Result for PostId: ", key)
//                                //Delete Bookmark since post is unavailable
//
//                                Database.fetchUserWithUID(uid: creatorUID, completion: { (user) in
//
//                                    let bookmarkDate = Date(timeIntervalSince1970: bookmarkTime)
//
//
//                                    let deleteAlert = UIAlertController(title: "Delete Bookmark", message: "Post Created By \(user.username) and Bookmarked on \(bookmarkDate) Was Deleted", preferredStyle: UIAlertControllerStyle.alert)
//
//                                    deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
//
//                                        Database.database().reference().child("bookmarks").child(uid).child(key).removeValue()
//
//                                    }))
//
//                                    self.present(deleteAlert, animated: true, completion: nil)
//                                })
//                                return}
//
//                        let tempBookmark = Bookmark.init(bookmarkCreatorUid: creatorUID, fetchedDate: bookmarkTime, post: post)
//                        self.fetchedBookmarks.append(tempBookmark)
//                        self.fetchedBookmarks.sort(by: { (p1, p2) -> Bool in
//                        return p1.bookmarkDate.compare(p2.bookmarkDate) == .orderedDescending
//                          })
//                        self.displayedBookmarks = self.fetchedBookmarks
//                        self.collectionView.reloadData()
//                                })
//                            }
//                        }
//                    })
//                })
//            }



//    fileprivate func paginatePosts(){
//
//        guard let uid = self.user?.uid else {return}
//        let ref = Database.database().reference().child("userposts").child(uid)
//        //var query = ref.queryOrderedByKey()
//        var query = ref.queryOrdered(byChild: "creationDate")
//
//        print(allPosts.count)
//        if allPosts.count > 0 {
//            let value = allPosts.last?.creationDate.timeIntervalSince1970
//            let queryEnd = allPosts.last?.id
//            print("Query Ending", allPosts.last?.id)
//            query = query.queryEnding(atValue: value)
//        }
//
//        let thisGroup = DispatchGroup()
//
//        query.queryLimited(toLast: 6).observeSingleEvent(of: .value, with: { (snapshot) in
//
//            guard var allPostIds = snapshot.value as? [String: Any] else {return}
//
//            if allPostIds.count < 4 {
//                self.isFinishedPaging = true
//            }
//
////            allPostIds.sorted(by: { $0["creationDate"] > $1["creationDate] })
//            print("allpostIds Queried",allPostIds)
//
//                let intIndex = allPostIds.count // where intIndex < myDictionary.count
//                let index = allPostIds.index(allPostIds.startIndex, offsetBy: intIndex - 1)
//                let testindex = allPostIds.index(allPostIds.startIndex, offsetBy: 1)
// //               let deleteindex = allPostIds.index(forKey: (self.allPosts.last?.id)!)
//
// //               print("DeletedUID ",allPostIds[deleteindex!])
//
//            if self.allPosts.count > 0 {
//                print("before delete", allPostIds.count)
//
////                let allPostCount = max(0,self.allPosts.count - 5)
//
//                let lastSixPost =  self.allPosts.suffix(6)
//  //              let lastSixPost = self.allPosts[(allPostCount-1)..<self.allPosts.count-1]
//
//                var lastSixPostIds: [String] = []
//
//                for post in lastSixPost{
//                    lastSixPostIds.append(post.id!)
//            }
//
//                print("Last Six Post Ids: ",lastSixPostIds)
//
//                for post in allPostIds {
//                    print("Post Key :", post.key)
//                    if lastSixPostIds.contains(post.key){
//                    print("Deleting ", post.key)
//                    allPostIds.removeValue(forKey: post.key)
//
//                    }
//                }
//
//                print("after delete", allPostIds.count)
//            }
//
//            guard let user = self.user else {return}
//
//            allPostIds.forEach({ (key,value) in
//
//                thisGroup.enter()
//
//                Database.fetchPostWithUIDAndPostID(creatoruid: user.uid, postId: key, completion: { (fetchedPost) in
//
//                self.allPosts.append(fetchedPost)
//                    print(self.allPosts.count, fetchedPost.id)
//                thisGroup.leave()
//
//                })
//            })
//
//            thisGroup.notify(queue: .main) {
//                print(self.allPosts.count)
//                self.allPosts.sort(by: { (p1, p2) -> Bool in
//                    return p1.creationDate.compare(p2.creationDate) == .orderedDescending })
//
//                self.collectionView?.reloadData()
//            }
//
//            self.allPosts.forEach({ (post) in
//                print(post.id ?? "")
//
//            })
//
//        }) { (err) in
//            print("Failed to Paginate for Posts:", err)
//        }
//
//
//    }




// FUNCTION TO UPDATE GPS LOCATIONS FOR EACH POST
//
//func updateGPSForPosts() {
//
//    for post in allPosts {
//
//        let postID = post.id
//
//        let ref = Database.database().reference().child("postlocations")
//        let geoFire = GeoFire(firebaseRef: ref)
//
//        geoFire?.getLocationForKey(postID, withCallback: { (location, error) in
//            if (error != nil) {
//                print("An error occurred getting the location for \"firebase-hq\": \(error?.localizedDescription)")
//            } else if (location != nil) {
//
//                let uploadedLocationGPSLatitude = String(format: "%f", (location?.coordinate.latitude)!)
//                let uploadedlocationGPSLongitude = String(format: "%f", (location?.coordinate.longitude)!)
//                let uploadedLocationGPS = uploadedLocationGPSLatitude + "," + uploadedlocationGPSLongitude
//
//                Database.database().reference().child("posts").child(post.creatorUID!).child(postID!).updateChildValues(["postLocationGPS": uploadedLocationGPS])
//
//
//                print("Location for \"firebase-hq\" is [\(location?.coordinate.latitude), \(location?.coordinate.longitude)]")
//            } else {
//                Database.database().reference().child("posts").child(post.creatorUID!).child(postID!).updateChildValues(["postLocationGPS": ""])
//                print("GeoFire does not contain a location for \"firebase-hq\"")
//            }
//        })
//        print("Updated ", post.creatorUID, "", post.id )
//    }
//
//}

// OLD HOMEPOST CELL DELEGATE FUNCTIONS

//func didBookmark(for cell: HomePostCell) {
//    print("Handling Like inside controller")
//
//    guard let indexPath = collectionView?.indexPath(for: cell) else {return}
//
//    var post = self.filteredPosts[indexPath.item]
//    print(post.caption)
//
//
//    guard let postId = post.id else {return}
//    guard let uid = Auth.auth().currentUser?.uid else {return}
//    let values = [uid: post.hasBookmarked == true ? 0 : 1]
//
//
//
//    Database.database().reference().child("bookmarks").child(postId).updateChildValues(values) { (err, ref) in
//        if let err = err {
//            print("Failed to bookmark post", err)
//            return
//        }
//        print("Succesfully Saved Bookmark")
//        post.hasBookmarked = !post.hasBookmarked
//
//        self.filteredPosts[indexPath.item] = post
//        self.collectionView?.reloadItems(at: [indexPath])
//
//    }
//
//
//}
//
//
//func didLike(for cell: HomePostCell) {
//    print("Handling Like inside controller")
//
//    guard let indexPath = collectionView?.indexPath(for: cell) else {return}
//
//    var post = self.filteredPosts[indexPath.item]
//    print(post.caption)
//
//
//    guard let postId = post.id else {return}
//    guard let uid = Auth.auth().currentUser?.uid else {return}
//    let values = [uid: post.hasLiked == true ? 0 : 1]
//
//
//
//    Database.database().reference().child("likes").child(postId).updateChildValues(values) { (err, ref) in
//        if let err = err {
//            print("Failed to like post", err)
//            return
//        }
//        print("Succesfully Saved Likes")
//        post.hasLiked = !post.hasLiked
//
//        self.filteredPosts[indexPath.item] = post
//        self.collectionView?.reloadItems(at: [indexPath])
//
//    }
//
//
//}


//
//
//func didTapUser(post: Post) {
//    let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
//    userProfileController.userId = post.user.uid
//
//    navigationController?.pushViewController(userProfileController, animated: true)
//}
//
//func didSendMessage(post:Post){
//
//    print("emailtest")
//    let mailgun = Mailgun.client(withDomain: "sandbox036bf1de5ba44e7e8ad4f19b9cc5b7d8.mailgun.org", apiKey: "key-2562988360d4f7f8a1fcc6f3647b446a")
//
//    let message = MGMessage(from:"Excited User <someone@sample.org>",
//                            to:"Jay Baird <planert41@gmail.com>",
//                            subject:"Mailgun is awesome!",
//                            body:("<html>Inline image here: <img src=cid:image01.jpg></html>"))!
//
//
//
//    let postImage = CustomImageView()
//    postImage.loadImage(urlString: post.imageUrl)
//
//    //        message.add(postImage.image, withName: "image01", type: .JPEGFileType, inline: true)
//    message.html = "<html>Inline image here: <img src="+post.imageUrl+" width = \"25%\" height = \"25%\"/></html>"
//
//
//    // someImage: UIImage
//    // type can be either .JPEGFileType or .PNGFileType
//    // message.add(postImage.image, withName: "image01", type:.PNGFileType)
//
//
//    mailgun?.send(message, success: { (success) in
//        print("success sending email")
//    }, failure: { (error) in
//        print(error)
//    })
//
//}




//    fileprivate func fetchPostsWithUser(user: User){
//
////        guard let uid = Auth.auth().currentUser?.uid  else {return}
//
//        let ref = Database.database().reference().child("posts").child(user.uid)
//
//        ref.observeSingleEvent(of: .value, with: {(snapshot) in
//            //print(snapshot.value)
//
//
//            guard let dictionaries = snapshot.value as? [String: Any] else {return}
//
//            dictionaries.forEach({ (key,value) in
//                //print("Key \(key), Value: \(value)")
//
//                guard let dictionary = value as? [String: Any] else {return}
//
//                //let imageUrl = dictionary["imageUrl"] as? String
//                //print("imageUrl: \(imageUrl)")
//                var post = Post(user: user, dictionary: dictionary)
//                post.id = key
//                post.creatorUID = user.uid
//
//
//                guard let uid = Auth.auth().currentUser?.uid else {return}
//
//                Database.database().reference().child("likes").child(uid).child(key).observeSingleEvent(of: .value, with: { (snapshot) in
//
//                    if let value = snapshot.value as? Int, value == 1 {
//                        post.hasLiked = true
//                    } else {
//                        post.hasLiked = false
//                    }
//
//                    Database.database().reference().child("bookmarks").child(uid).child(key).observeSingleEvent(of: .value, with: { (snapshot) in
//
//                        let dictionaries = snapshot.value as? [String: Any]
//
//                        if let value = dictionaries?["bookmarked"] as? Int, value == 1 {
//                            post.hasBookmarked = true
//                        } else {
//                            post.hasBookmarked = false
//                        }
//
//
//                    self.allPosts.append(post)
//
//                    self.allPosts.sort(by: { (p1, p2) -> Bool in
//                        return p1.creationDate.compare(p2.creationDate) == .orderedDescending
//                        })
//
//                    self.filteredPosts = self.allPosts
//                    self.collectionView?.reloadData()
//
//                    }, withCancel: { (err) in
//                        print("Failed to fetch bookmark info for post:", err)
//                    })
//
//
//                }, withCancel: { (err) in
//                    print("Failed to fetch like info for post:", err)
//                })
//            })
//
//        }) { (err) in print("Failed to fetchposts:", err) }
//
//
//    }



//    fileprivate func paginatePosts(){
//
//        guard let uid = self.user?.uid else {return}
//        let ref = Database.database().reference().child("posts").child(uid)
//        //var query = ref.queryOrderedByKey()
//        var query = ref.queryOrdered(byChild: "creationDate")
//
//        print(posts.count)
//        if posts.count > 0 {
//            let value = posts.last?.creationDate.timeIntervalSince1970
//            print(posts)
//            print(value)
//            query = query.queryEnding(atValue: value)
//        }
//
//        query.queryLimited(toLast: 6).observeSingleEvent(of: .value, with: { (snapshot) in
//
//            guard var allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
//            allObjects.reverse()
//
//            if allObjects.count < 4 {
//                self.isFinishedPaging = true
//            }
//
//            if self.posts.count > 0 && allObjects.count > 0 {
//                allObjects.removeFirst()
//            }
//
//            guard let user = self.user else {return}
//
//            allObjects.forEach({ (snapshot) in
//
//                guard let dictionary = snapshot.value as? [String: Any] else {return}
//
//
//                var post = Post(user: user, dictionary: dictionary)
//                post.id = snapshot.key
//                post.creatorUID = uid
//                guard let uid = Auth.auth().currentUser?.uid else {return}
//                guard let key = post.id else {return}
//
//                // Check for Likes and Bookmarks
//
//
//                Database.database().reference().child("likes").child(uid).child(key).observeSingleEvent(of: .value, with: { (snapshot) in
//
//                    if let value = snapshot.value as? Int, value == 1 {
//                        post.hasLiked = true
//                    } else {
//                        post.hasLiked = false
//                    }
//
//
//
//
//                    Database.database().reference().child("bookmarks").child(uid).child(key).observeSingleEvent(of: .value, with: { (snapshot) in
//
//                        if let value = snapshot.value as? Int, value == 1 {
//                            post.hasBookmarked = true
//                        } else {
//                            post.hasBookmarked = false
//                        }
//
//                        self.posts.append(post)
//
//
//                    }, withCancel: { (err) in
//                        print("Failed to fetch bookmark info for post:", err)
//                    })
//
//                }, withCancel: { (err) in
//                    print("Failed to fetch like info for post:", err)
//                })
//
//
//                // Have 1 second delay so that Firebase returns like/bookmark info with post before reloading collectionview
//                // The problem is that reloading data after every single new post gets added (after getting checked) calls paginate post again before
//                // the other posts are finished, so it creates duplicates posts
//
//
//                let when = DispatchTime.now() + 0.25 // change 2 to desired number of seconds
//                DispatchQueue.main.asyncAfter(deadline: when) {
//                    self.collectionView?.reloadData()
//                }
//
//
//            })
//
//
//            self.posts.forEach({ (post) in
//                print(post.id ?? "")
//
//            })
//
//        }) { (err) in
//            print("Failed to Paginate for Posts:", err)
//        }
//
//
//    }
//



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


