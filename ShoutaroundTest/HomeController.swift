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

class HomeController: UICollectionViewController, UICollectionViewDelegateFlowLayout, HomePostCellDelegate, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource  {
    
    let cellId = "cellId"
    var allPosts = [Post]()
    var filteredPosts = [Post]()
    
    // GeoPickerData 1st element should always be default ALL
    let geoFilterRange = ["ALL","500", "1000", "2500", "5000"]

    
    override func viewDidLayoutSubviews() {
        
        let filterBarHeight = (self.filterBar.isHidden == false) ? self.filterBar.frame.height : 0
        let topinset = (self.navigationController?.navigationBar.frame.size.height)! + UIApplication.shared.statusBarFrame.height + filterBarHeight
        collectionView?.frame = CGRect(x: 0, y: topinset, width: view.frame.width, height: view.frame.height)
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: SharePhotoController.updateFeedNotificationName, object: nil)

        view.addSubview(filterBar)
        filterBar.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        filterBar.addSubview(geoFilterButton)
        filterBar.addSubview(searchBar)
        filterBar.isHidden = true
        filterBar.addSubview(dummyTextView)

        geoFilterButton.anchor(top: filterBar.topAnchor, left: nil, bottom: filterBar.bottomAnchor, right: filterBar.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 10, width: 100, height: 0)
        
        searchBar.anchor(top: filterBar.topAnchor, left: filterBar.leftAnchor, bottom: filterBar.bottomAnchor, right: geoFilterButton.leftAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, paddingRight: 8, width: 0, height: 0)
        
        collectionView?.backgroundColor = .white
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: cellId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        
        setupNavigationItems()
        fetchAllPosts()
        setupGeoPicker()
    }
    

    
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    
// Handle Filter Bar
    
    lazy var filterBar: UIView = {
        let sb = UIView()
        sb.backgroundColor = UIColor.lightGray
        return sb
    }()
    
    func hideHeader(){
        
        self.filterBar.isHidden = (self.filterBar.isHidden == true) ? false : true
        self.collectionView?.reloadData()
        
    }
    
    
// Setup for Geo Range Button, Dummy TextView and UIPicker
    
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
        filterPostByCaption(self.searchBar.text)
        filterNearbyPost()
    }
    
    func cancelPicker(){
        dummyTextView.resignFirstResponder()
    }
    
    func filterRange() {
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
        self.geoFilterButton.setTitle(geoFilterRange[row], for: .normal)
    }


    
// Setup for Search Button
    
    lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search for Caption or Emoji 😍🐮🍔🇺🇸🔥"
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
        filterPostByCaption(searchBar.text)
        filterNearbyPost()
        self.collectionView?.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        filteredPosts = allPosts
        self.collectionView?.reloadData()
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        

    }
    
    func filterPostByCaption(_ string: String?) {
        
        guard let searchedText = string else {
            filteredPosts = allPosts
            self.collectionView?.reloadData()
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
        self.searchBar.text = ""
        self.geoFilterButton.titleLabel?.text = geoFilterRange[0]
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
        
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "logo2"))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "camera3").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleCamera))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "home_selected").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(hideHeader))
        
    }
    
    func nearbyPostTest(){
        
        filterNearbyPost()
        
    }
    

    
    
    func filterNearbyPost(){
        
        let ref = Database.database().reference().child("postlocations")
        let geoFire = GeoFire(firebaseRef: ref)
        let currentLocation = CLLocation(latitude: 41.973735, longitude: -87.667751)
        
        var geoFilteredPosts = [Post]()
        
        guard let geoDistance = Double((geoFilterButton.titleLabel?.text)!) else {
            print("No Distance Number")
            return}
        
        let circleQuery = geoFire?.query(at: currentLocation, withRadius: geoDistance)
        circleQuery?.observe(.keyEntered, with: { (key, location) in
            print(key)
            let geoFilteredPost = self.filteredPosts.filter { (post) -> Bool in
                return post.id == key
            }
            print(geoFilteredPost)
            geoFilteredPosts += geoFilteredPost
            
        })
        
        circleQuery?.observeReady({ 
            self.filteredPosts = geoFilteredPosts
            self.collectionView?.reloadData()
        })
        
    }
    
    
    func handleCamera() {
        let cameraController = CameraController()
        present(cameraController, animated: true, completion: nil)
        
    }
    
    fileprivate func fetchPosts() {
        
        guard let uid = Auth.auth().currentUser?.uid  else {return}
        
        Database.fetchUserWithUID(uid: uid) { (user) in
            self.fetchPostsWithUser(user: user)
        }

    }
    
    
    fileprivate func fetchPostsWithUser(user: User){
        
//        guard let uid = Auth.auth().currentUser?.uid  else {return}
        
        let ref = Database.database().reference().child("posts").child(user.uid)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            //print(snapshot.value)
            
            
            guard let dictionaries = snapshot.value as? [String: Any] else {return}
            
            dictionaries.forEach({ (key,value) in
                //print("Key \(key), Value: \(value)")
                
                guard let dictionary = value as? [String: Any] else {return}
                
                //let imageUrl = dictionary["imageUrl"] as? String
                //print("imageUrl: \(imageUrl)")
                var post = Post(user: user, dictionary: dictionary)
                post.id = key
                post.creatorUID = user.uid
                
                
                guard let uid = Auth.auth().currentUser?.uid else {return}
                
                Database.database().reference().child("likes").child(uid).child(key).observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    if let value = snapshot.value as? Int, value == 1 {
                        post.hasLiked = true
                    } else {
                        post.hasLiked = false
                    }
                    
                    Database.database().reference().child("bookmarks").child(uid).child(key).observeSingleEvent(of: .value, with: { (snapshot) in

                        let dictionaries = snapshot.value as? [String: Any]
                        
                        if let value = dictionaries?["bookmarked"] as? Int, value == 1 {
                            post.hasBookmarked = true
                        } else {
                            post.hasBookmarked = false
                        }
                    
                    
                    self.allPosts.append(post)
                    
                    self.allPosts.sort(by: { (p1, p2) -> Bool in
                        return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                        })
                    
                    self.filteredPosts = self.allPosts
                    self.collectionView?.reloadData()
                    
                    }, withCancel: { (err) in
                        print("Failed to fetch bookmark info for post:", err)
                    })
                    
                        
                }, withCancel: { (err) in
                    print("Failed to fetch like info for post:", err)
                })
            })
            
        }) { (err) in print("Failed to fetchposts:", err) }
        
        
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
    
    func refreshPost(post: Post) {
        let index = filteredPosts.index { (filteredpost) -> Bool in
            filteredpost.id  == post.id
        }
        print(index)
        let filteredindexpath = IndexPath(row:index!, section: 0)
        self.filteredPosts[index!] = post
//        self.collectionView?.reloadItems(at: [filteredindexpath])
    }
}

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





