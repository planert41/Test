//
//  HomeController.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import Firebase
import mailgun
import GeoFire
import CoreGraphics
import CoreLocation


class HomeController: UICollectionViewController, UICollectionViewDelegateFlowLayout, HomePostCellDelegate, UIPickerViewDelegate, UIPickerViewDataSource, CLLocationManagerDelegate, UISearchControllerDelegate, HomePostSearchDelegate  {
    
    let cellId = "cellId"
    var allPosts = [Post]()
    var filteredPosts = [Post](){
        didSet{
            if filteredPosts.count == 0 {
                self.noResultsLabel.isHidden = false
            } else {
                self.noResultsLabel.isHidden = true
            }
        }
    }
    
    let geoFilterRange = ["WorldWide", "0.5","1.0", "2.0", "5.0", "20.0"]
    let geoFilterImage:[UIImage] = [#imageLiteral(resourceName: "Globe"),#imageLiteral(resourceName: "0Distance"),#imageLiteral(resourceName: "1Distance"),#imageLiteral(resourceName: "2Distance"),#imageLiteral(resourceName: "5Distance"),#imageLiteral(resourceName: "20Distance")]
    
    var filterRange: Double?{
        didSet{
            print(filterRange)
            if filterRange == nil {
                navigationItem.leftBarButtonItem?.image = self.geoFilterImage[0].withRenderingMode(.alwaysOriginal)

            } else {
                print(String(format:"%.1f", self.filterRange!))
                let rangeIndex = self.geoFilterRange.index(of: String(format:"%.1f", self.filterRange!))
            navigationItem.leftBarButtonItem?.image = geoFilterImage[rangeIndex!].withRenderingMode(.alwaysOriginal)
            }
        }
    }
    
    var resultSearchController:UISearchController? = nil

    let locationManager = CLLocationManager()

    override func viewDidLayoutSubviews() {
        
//        let filterBarHeight = (self.filterBar.isHidden == false) ? self.filterBar.frame.height : 0
//        
//        let topinset = (self.navigationController?.navigationBar.frame.size.height)! + UIApplication.shared.statusBarFrame.height + filterBarHeight
//        collectionView?.frame = CGRect(x: 0, y: topinset, width: view.frame.width, height: view.frame.height - topinset - (self.tabBarController?.tabBar.frame.size.height)!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchCurrentUser()
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
        
//        self.automaticallyAdjustsScrollViewInsets = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: SharePhotoController.updateFeedNotificationName, object: nil)

        view.addSubview(noResultsLabel)
        noResultsLabel.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        view.addSubview(dummyTextView)
        collectionView?.backgroundColor = .white
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: cellId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        
// Search Controller
        setupSearchController()
        setupNavigationItems()
        fetchAllPosts()
        setupGeoPicker()
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }
        
    }
    
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    
// Setup for Geo Range Button, Dummy TextView and UIPicker
    
    lazy var dummyTextView: UITextView = {
        let tv = UITextView()
        return tv
    }()
    
    var noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = UIColor.black
        label.isHidden = true
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    func setupSearchController() {
        let homePostSearchResults = HomePostSearch()
        homePostSearchResults.delegate = self
        resultSearchController = UISearchController(searchResultsController: homePostSearchResults)
        resultSearchController?.searchResultsUpdater = homePostSearchResults
        resultSearchController?.delegate = self
        let searchBar = resultSearchController?.searchBar
        navigationItem.titleView = searchBar
        searchBar?.delegate = homePostSearchResults
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
    }
    
    func setupGeoPicker() {

        let pickerView = UIPickerView()
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
        filterPostByCaption(self.resultSearchController?.searchBar.text)
        filterPostByLocation()
        
    }
    
    func cancelPicker(){
        dummyTextView.resignFirstResponder()
    }
    
    func activateFilterRange() {
        dummyTextView.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.1)
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
        // If Select some number
        if row > 0 {
        filterRange = Double(geoFilterRange[row])
        } else {
        filterRange = nil
        }
    }


// Search Delegate And Methods
    
    func filterPost(caption: String?) {
        self.resultSearchController?.searchBar.text = caption
        filterPostByCaption(self.resultSearchController?.searchBar.text)
        filterPostByLocation()
        self.collectionView?.reloadData()
    }
    
    func filterHere(){
        
        self.filterRange = Double(geoFilterRange[5])
        self.filterPostByLocation()
        let indexPath = IndexPath(item: 0, section: 0)
        self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
        
    }

    func filterPostByCaption(_ string: String?) {
        
        guard let searchedText = string else {
            print("No Search Term")
            filteredPosts = allPosts
            self.collectionView?.reloadData()
            return
        }
        
        if searchedText.isEmpty || searchedText == "" {
            filteredPosts = allPosts
            print("No Search Term")
        } else {
            
            print("Search Term Was", searchedText)
            //Makes everything case insensitive
            filteredPosts = self.allPosts.filter { (post) -> Bool in
                return post.caption.lowercased().contains(searchedText.lowercased()) || post.emoji.contains(searchedText.lowercased()) || post.locationName.contains(searchedText.lowercased()) || post.locationAdress.contains(searchedText.lowercased())
            }
            collectionView?.reloadData()
        }
    }
    
    func filterPostByLocation(){
        
        let ref = Database.database().reference().child("postlocations")
        let geoFire = GeoFire(firebaseRef: ref)
        //     let currentLocation = CLLocation(latitude: 41.973735, longitude: -87.667751)
        
        var geoFilteredPosts = [Post]()
        
        guard let filterDistance = self.filterRange else {
            collectionView?.reloadData()
            print("No Distance Number")
            return}
        
        self.determineCurrentLocation()
        
        let when = DispatchTime.now() + 0.5 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            
            print("Current User Location Used for Post Filtering", CurrentUser.currentLocation)
            let circleQuery = geoFire?.query(at: CurrentUser.currentLocation, withRadius: filterDistance)
            circleQuery?.observe(.keyEntered, with: { (key, location) in
                var geoFilteredPost: [Post] = self.filteredPosts.filter { (post) -> Bool in
                    return post.id == key
                }
                
                if geoFilteredPost != nil && geoFilteredPost.count > 0 && geoFilteredPost[0].locationGPS != nil {
                    geoFilteredPost[0].locationGPS = location
                    geoFilteredPost[0].distance = Double((location?.distance(from: CurrentUser.currentLocation!))!)
                }
                geoFilteredPosts += geoFilteredPost
            })
            
            circleQuery?.observeReady({
                self.filteredPosts = geoFilteredPosts.sorted(by: { (p1, p2) -> Bool in
                    p1.distance!.isLess(than: p2.distance!)
                })
                
                if self.collectionView?.numberOfItems(inSection: 0) != 0 {
                    let indexPath = IndexPath(item: 0, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
                self.collectionView?.reloadData()
            })
        }
    }
    
    
    
// Handle Update
    
    func handleUpdateFeed() {
        handleRefresh()
    }
    
    // IOS9 - let refreshControl = UIRefreshControl()
    
    func handleRefresh() {

        // RemoveAll so that when user follow/unfollows it updates
        
        allPosts.removeAll()
        filteredPosts.removeAll()
        fetchAllPosts()
        
        self.resultSearchController?.searchBar.text = ""
        self.filterRange = nil
        
        self.collectionView?.refreshControl?.endRefreshing()
        print("Refresh Home Feed")
    }
    
    fileprivate func fetchAllPosts() {

        fetchPosts()
        fetchFollowingUserIds()
        filteredPosts = allPosts
        collectionView?.reloadData()
    }
    
    
    fileprivate func fetchFollowingUserIds() {
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        Database.database().reference().child("following").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let userIdsDictionary = snapshot.value as? [String: Any] else {return}
            userIdsDictionary.forEach({ (key,value) in
                Database.fetchUserWithUID(uid: key, completion: { (user) in
                    self.fetchPostsWithUser(user: user)
                })
            })
            
        }) { (err) in
            print("Failed to fetch following user ids:", err)
        }

    }
    
    fileprivate func setupNavigationItems() {
        
      //  navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "logo2"))
        
//        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "camera3").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleCamera))
        
//        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Globe").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(activateFilterRange))
        
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Globe").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(openInbox))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "GeoFence").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(filterHere))
        
    }
    
    
    
    func handleCamera() {
        let cameraController = CameraController()
        present(cameraController, animated: true, completion: nil)
        
    }
    
    func openInbox() {
        
        let inboxController = InboxController(collectionViewLayout: UICollectionViewFlowLayout())
        navigationController?.pushViewController(inboxController, animated: true)
        
    }
    
    fileprivate func fetchPosts() {
        
        guard let uid = Auth.auth().currentUser?.uid  else {return}
        
        Database.fetchUserWithUID(uid: uid) { (user) in
            self.fetchPostsWithUser(user: user)
        }

    }
    

    fileprivate func fetchPostsWithUser(user: User){
    
        Database.fetchAllPostWithUID(creatoruid: user.uid) { (fetchedPosts) in
            self.allPosts = self.allPosts + fetchedPosts
            self.allPosts.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
             })
            
            print(fetchedPosts)
            self.filteredPosts = self.allPosts
            self.collectionView?.reloadData()
        }

    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 40 + 8 + 8 //username userprofileimageview
        height += view.frame.width
        height += 50
        height += 60
        
        return CGSize(width: view.frame.width, height: height)
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        

        return filteredPosts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! HomePostCell
        cell.post = filteredPosts[indexPath.item]
        cell.delegate = self
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(filteredPosts[indexPath.item])
    }
    
    
    
// HOME POST CELL DELEGATE METHODS
    
    func didTapComment(post: Post) {
    
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.post = post
    
        navigationController?.pushViewController(commentsController, animated: true)
    }
    
    func didTapUser(post: Post) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.userId = post.user.uid
    
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapLocation(post: Post) {
        let locationController = LocationController()
        locationController.selectedPost = post
        
        navigationController?.pushViewController(locationController, animated: true)
    }
    
    func refreshPost(post: Post) {
        let index = filteredPosts.index { (filteredpost) -> Bool in
            filteredpost.id  == post.id
        }
        print(index)
        let filteredindexpath = IndexPath(row:index!, section: 0)
        self.filteredPosts[index!] = post
//        self.collectionView?.reloadItems(at: [filteredindexpath])
    }
    
    func didTapMessage(post: Post) {
        
        let messageController = MessageController()
        messageController.post = post
        
        navigationController?.pushViewController(messageController, animated: true)
        
    }
    
    func deletePost(post:Post){
        
        let deleteAlert = UIAlertController(title: "Delete", message: "All data will be lost.", preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            
            
            Database.database().reference().child("posts").child(post.id!).removeValue()
            Database.database().reference().child("postlocations").child(post.id!).removeValue()
            Database.database().reference().child("userposts").child(post.creatorUID!).child(post.id!).removeValue()
        
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(deleteAlert, animated: true, completion: nil)
        
        
    }
    
    
// LOCATION MANAGER DELEGATE METHODS
    
    func determineCurrentLocation(){

        CurrentUser.currentLocation = nil
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        if userLocation != nil {
            print("Current User Location", userLocation)
            CurrentUser.currentLocation = userLocation
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("GPS Location Not Found")
    }
    
}

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





