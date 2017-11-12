//
//  UserProfileController.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/26/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import IQKeyboardManagerSwift

class UserProfileController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UserProfileHeaderDelegate, HomePostCellDelegate,BookmarkPhotoCellDelegate, UserProfilePhotoCellDelegate {
    
    let cellId = "cellId"
    let homePostCellId = "homePostCellId"
    
    var allPosts = [Post]()
    var filteredPosts = [Post]()
    var isFinishedPaging = false
    
    var userId:String?
    var isGroup: Bool = false {
        didSet{
            if (userId != Auth.auth().currentUser?.uid) {
            if isGroup && (userId != Auth.auth().currentUser?.uid) {
                self.navigationItem.rightBarButtonItem?.image = #imageLiteral(resourceName: "redstar").withRenderingMode(.alwaysOriginal)
            } else {
                self.navigationItem.rightBarButtonItem?.image = #imageLiteral(resourceName: "starunfill").withRenderingMode(.alwaysOriginal)
            }
        }
        }
    }
    var user: User?
    
    var isGridView = true
    
    var groupSelections:[String] = ["Family","Friends","Foodie","Group1", "Group2"]
    var unGroupSelections:[String] = ["Delete"]
    
    
// UserProfileHeader Delegate Methods
    
    func didChangeToGridView() {
        isGridView = true
        collectionView?.reloadData()
    }
    
    func didChangeToListView() {
        isGridView = false
        collectionView?.reloadData()
    }

    func didSignOut(){
        self.handleLogOut()
    }
    
    func didTapPicture(post: Post){
        let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
        pictureController.selectedPost = post
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    func handlePictureTap(post: Post){
        let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
        pictureController.selectedPost = post
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    
    lazy var dummyTextView: UITextView = {
        let tv = UITextView()
        return tv
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupEmojiDetailLabel()
        
        collectionView?.backgroundColor = .white
        
        collectionView?.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerId")
        
        collectionView?.register(UserProfilePhotoCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: homePostCellId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        
        view.addSubview(dummyTextView)
        
        fetchUser()
        IQKeyboardManager.sharedManager().enable = false
        setupLogOutButton()
        
    }
    
    // Emoji description
    
    let emojiDetailLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 255, green: 242, blue: 230)
        label.layer.cornerRadius = 30/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.masksToBounds = true
        return label
        
    }()
    
    func setupEmojiDetailLabel(){
        view.addSubview(emojiDetailLabel)
        emojiDetailLabel.anchor(top: topLayoutGuide.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 150, height: 25)
        emojiDetailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        emojiDetailLabel.isHidden = true
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        emojiDetailLabel.isHidden = true
    }
    
    func handleGroupOrUngroup(){
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else {return}
        
        guard let userId = user?.uid else {return}
        
        if currentLoggedInUserId == userId {return}

        if isGroup {
            
            Database.database().reference().child("group").child(currentLoggedInUserId).child(userId).removeValue(completionBlock: { (err, ref) in
                if let err = err {
                    print("Failed to ungroup user:", err)
                    return
                }
                print("Successfully group user", self.user?.username ?? "")
                self.isGroup = false
            //    self.setupFollowStyle()
                
            })
            
        }   else {
            
            let ref = Database.database().reference().child("group").child(currentLoggedInUserId)
            
            let values = [userId: 1]
            
            ref.updateChildValues(values) { (err, ref) in
                if let err = err {
                    
                    print("Failed to Group User", err)
                    return
                }
                print("Successfully Group user: ", self.user?.username ?? "")
                self.isGroup = true
                
            }
        }

    }
    
    
    fileprivate func setupGroupButton() {
        guard let currentLoggedInUserID = Auth.auth().currentUser?.uid else {return}
        guard let userId = user?.uid else {return}
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "starunfill").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.handleGroupOrUngroup))
        
        if currentLoggedInUserID == userId {
            //                Edit Profile
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        }else {
            
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            
            
            // check if following
            
            Database.database().reference().child("group").child(currentLoggedInUserID).child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let isGroupVal = snapshot.value as? Int, isGroupVal == 1 {
                    self.isGroup = true
                    
                } else{
                    self.isGroup = false
                }
                
                if self.isGroup {
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "redstar").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.handleGroupOrUngroup))} else {
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "starunfill").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.handleGroupOrUngroup))
                }
                
            }, withCancel: { (err) in
                
                print("Failed to check if group", err)
                
            })
            
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        IQKeyboardManager.sharedManager().enable = true
    }
    
    // IOS9 - let refreshControl = UIRefreshControl()
    
    func handleRefresh() {
        
        // RemoveAll so that when user follow/unfollows it updates
        
        self.isFinishedPaging = false
        allPosts.removeAll()
        collectionView?.reloadData()
        fetchUser()
        self.collectionView?.refreshControl?.endRefreshing()
        print("Refresh Profile Page")
    }
    
// HomePost Cell Delegate Functions
    
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
        let index = allPosts.index { (filteredpost) -> Bool in
        filteredpost.id  == post.id
            
    }
        let filteredindexpath = IndexPath(row:index!, section: 0)
        self.allPosts[index!] = post
        //        self.collectionView?.reloadItems(at: [filteredindexpath])
        
    }
    
    func didTapMessage(post: Post) {
        
        let messageController = MessageController()
        messageController.post = post
        
        navigationController?.pushViewController(messageController, animated: true)
    }
    
    func userOptionPost(post:Post){
        
        let optionsAlert = UIAlertController(title: "User Options", message: "", preferredStyle: UIAlertControllerStyle.alert)
        
        optionsAlert.addAction(UIAlertAction(title: "Edit Post", style: .default, handler: { (action: UIAlertAction!) in
            // Allow Editing
            self.editPost(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Delete Post", style: .default, handler: { (action: UIAlertAction!) in
            self.deletePost(post: post)
        }))
        
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(optionsAlert, animated: true, completion: nil)
    }
    
    func editPost(post:Post){
        let editPost = SharePhotoController()
        
        // Post Edit Inputs
        editPost.editPost = true
        editPost.editPostImageUrl = post.imageUrl
        editPost.editPostId = post.id
        
        // Post Details
        editPost.selectedPostGooglePlaceID = post.locationGooglePlaceID
        editPost.selectedImageLocation = post.locationGPS
        editPost.selectedPostLocation = post.locationGPS
        editPost.selectedPostLocationName = post.locationName
        editPost.selectedPostLocationAdress = post.locationAdress
        editPost.selectedTime = post.tagTime
        editPost.ratingEmoji = post.ratingEmoji
        editPost.nonRatingEmoji = post.nonRatingEmoji
        editPost.nonRatingEmojiTags = post.nonRatingEmojiTags
        editPost.captionTextView.text = post.caption
        
        let navController = UINavigationController(rootViewController: editPost)
        self.present(navController, animated: false, completion: nil)
    }
    
    
    func deletePost(post:Post){
        
        let deleteAlert = UIAlertController(title: "Delete", message: "All data will be lost.", preferredStyle: UIAlertControllerStyle.alert)
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            
            // Remove from Current View
            let index = self.allPosts.index { (filteredpost) -> Bool in
                filteredpost.id  == post.id
            }
            
            let filteredindexpath = IndexPath(row:index!, section: 0)
            self.allPosts.remove(at: index!)
            self.collectionView?.deleteItems(at: [filteredindexpath])
            Database.deletePost(post: post)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func displaySelectedEmoji(emoji: String, emojitag: String) {
        
        emojiDetailLabel.text = emoji + " " + emojitag
        emojiDetailLabel.isHidden = false
        
    }
    
// Pagination
    
    
    fileprivate func paginatePosts(){
        
        guard let uid = self.user?.uid else {return}
        let ref = Database.database().reference().child("userposts").child(uid)
        //var query = ref.queryOrderedByKey()
        var query = ref.queryOrdered(byChild: "creationDate")
        
        print(allPosts.count)
        if allPosts.count > 0 {
            let value = allPosts.last?.creationDate.timeIntervalSince1970
            let queryEnd = allPosts.last?.id
            print("Query Ending", allPosts.last?.id)
            query = query.queryEnding(atValue: value)
        }
        
        let thisGroup = DispatchGroup()
        
        query.queryLimited(toLast: 6).observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard var allPostIds = snapshot.value as? [String: Any] else {return}
            
            if allPostIds.count < 4 {
                self.isFinishedPaging = true
            }
            
//            allPostIds.sorted(by: { $0["creationDate"] > $1["creationDate] })
            print("allpostIds Queried",allPostIds)
            
                let intIndex = allPostIds.count // where intIndex < myDictionary.count
                let index = allPostIds.index(allPostIds.startIndex, offsetBy: intIndex - 1)
                let testindex = allPostIds.index(allPostIds.startIndex, offsetBy: 1)
 //               let deleteindex = allPostIds.index(forKey: (self.allPosts.last?.id)!)
                
 //               print("DeletedUID ",allPostIds[deleteindex!])
                
            if self.allPosts.count > 0 {
                print("before delete", allPostIds.count)
                
//                let allPostCount = max(0,self.allPosts.count - 5)
                
                let lastSixPost =  self.allPosts.suffix(6)
  //              let lastSixPost = self.allPosts[(allPostCount-1)..<self.allPosts.count-1]
                
                var lastSixPostIds: [String] = []
                
                for post in lastSixPost{
                    lastSixPostIds.append(post.id!)
            }
                
                print("Last Six Post Ids: ",lastSixPostIds)

                for post in allPostIds {
                    print("Post Key :", post.key)
                    if lastSixPostIds.contains(post.key){
                    print("Deleting ", post.key)
                    allPostIds.removeValue(forKey: post.key)
                        
                    }
                }
                
                print("after delete", allPostIds.count)
            }
            
            guard let user = self.user else {return}
            
            allPostIds.forEach({ (key,value) in
                
                thisGroup.enter()
                
                Database.fetchPostWithUIDAndPostID(creatoruid: user.uid, postId: key, completion: { (fetchedPost) in

                self.allPosts.append(fetchedPost)
                    print(self.allPosts.count, fetchedPost.id)
                thisGroup.leave()
                    
                })
            })
            
            thisGroup.notify(queue: .main) {
                print(self.allPosts.count)
                self.allPosts.sort(by: { (p1, p2) -> Bool in
                    return p1.creationDate.compare(p2.creationDate) == .orderedDescending })
                
                self.collectionView?.reloadData()
            }
         
            self.allPosts.forEach({ (post) in
                print(post.id ?? "")

            })
            
        }) { (err) in
            print("Failed to Paginate for Posts:", err)
        }
        
        
    }
    
    
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
    
    
    fileprivate func fetchOrderedPosts() {
        
        guard let uid = self.user?.uid  else {return}
        
        let ref = Database.database().reference().child("posts").child(uid)
        
        // Might add pagination later
        ref.queryOrdered(byChild: "creationDate").observe(.childAdded, with: { (snapshot) in

            guard let dictionary = snapshot.value as? [String:Any] else {return}
            guard let user = self.user else {return}
            
            let post = Post(user: user, dictionary: dictionary)

//            Helps insert new photos at the front
            self.allPosts.insert(post, at: 0)
//            self.posts.append(post)

            self.collectionView?.reloadData()
            
        }) { (err) in
            
            print("Failed to fetch ordered posts:", err)
        }
        
    }
    
      
    fileprivate func setupLogOutButton() {
        if user?.uid == Auth.auth().currentUser?.uid {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "signout").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleLogOut))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "starunfill").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.handleGroupOrUngroup))
        }
    }


    func handleLogOut() {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (_) in
            
            do {
                try Auth.auth().signOut()
                let manager = FBSDKLoginManager()
                try manager.logOut()
                let loginController = LoginController()
                let navController = UINavigationController( rootViewController: loginController)
                self.present(navController, animated: true, completion: nil)
                
            } catch let signOutErr {
                print("Failed to sign out:", signOutErr)
            }

        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    
        present(alertController, animated: true, completion: nil)
    
    }
    
    
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allPosts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
//        print("collectionview post count", self.allPosts.count)
//        print("isfinishedpaging",self.isFinishedPaging)
//        print(indexPath.item)
        if indexPath.item == self.allPosts.count - 1 && !isFinishedPaging{
            
            paginatePosts()
        }
        
        
        if isGridView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! UserProfilePhotoCell
            cell.post = allPosts[indexPath.item]
            cell.delegate = self
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: homePostCellId, for: indexPath) as! HomePostCell
            cell.enableDelete = true
            cell.post = allPosts[indexPath.item]
            cell.delegate = self
            return cell
        }
    

        

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ cofllectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if isGridView {
        let width = (view.frame.width - 2) / 3
            return CGSize(width: width, height: width)
        } else {
            var height: CGFloat = 40 + 8 + 8 //username userprofileimageview
            height += view.frame.width
            height += 50
            height += 60
            
            return CGSize(width: view.frame.width, height: height)
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerId", for: indexPath) as! UserProfileHeader
        
        header.user = self.user
        header.delegate = self
                
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 200)
    }
    
    
    fileprivate func fetchUser() {

        // uid using userID if exist, if not, uses current user, if not uses blank
        
        let uid = userId ?? Auth.auth().currentUser?.uid ?? ""
        
//        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        Database.fetchUserWithUID(uid: uid) { (user) in
            self.user = user
            self.navigationItem.title = self.user?.username
            if user.uid != Auth.auth().currentUser?.uid {
                self.setupGroupButton()
            } else {
                self.setupLogOutButton()
            }
            
            self.collectionView?.reloadData()
            self.paginatePosts()
            
        }
        
    }
    
}


