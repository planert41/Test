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

class UserProfileController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UserProfileHeaderDelegate, HomePostCellDelegate {
    
    let cellId = "cellId"
    let homePostCellId = "homePostCellId"
    
    var posts = [Post]()
    var isFinishedPaging = false
    
    var userId:String?
    
    var isGridView = true
    
    func didChangeToGridView() {
        isGridView = true
        collectionView?.reloadData()
    }
    
    func didChangeToListView() {
        isGridView = false
        collectionView?.reloadData()
    }

    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        collectionView?.backgroundColor = .white
        
        collectionView?.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerId")
        
        collectionView?.register(UserProfilePhotoCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: homePostCellId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        
        setupLogOutButton()
        fetchUser()
        
        IQKeyboardManager.sharedManager().enable = false
        
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        IQKeyboardManager.sharedManager().enable = true
    }
    
    // IOS9 - let refreshControl = UIRefreshControl()
    
    func handleRefresh() {
        
        // RemoveAll so that when user follow/unfollows it updates
        
        self.isFinishedPaging = false
        posts.removeAll()
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
    
    func refreshPost(post: Post) {
        let index = posts.index { (filteredpost) -> Bool in
        filteredpost.id  == post.id
            
    }
        let filteredindexpath = IndexPath(row:index!, section: 0)
        self.posts[index!] = post
        //        self.collectionView?.reloadItems(at: [filteredindexpath])
        
    }
    
    func didTapMessage(post: Post) {
        
        let messageController = MessageController()
        messageController.post = post
        
        navigationController?.pushViewController(messageController, animated: true)
    }
    
    

    
    fileprivate func paginatePosts(){
        
        guard let uid = self.user?.uid else {return}
        let ref = Database.database().reference().child("userposts").child(uid)
        //var query = ref.queryOrderedByKey()
        var query = ref.queryOrdered(byChild: "creationDate")
        
        print(posts.count)
        if posts.count > 0 {
            let value = posts.last?.creationDate.timeIntervalSince1970
            print(value)
            query = query.queryEnding(atValue: value)
        }
        
        let thisGroup = DispatchGroup()
        
        query.queryLimited(toLast: 6).observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard var allPostIds = snapshot.value as? [String: Any] else {return}
            
            
            if allPostIds.count < 4 {
                self.isFinishedPaging = true
            }
            print(allPostIds)
            
            if self.posts.count > 0 && allPostIds.count > 0 {
                print("before delete", allPostIds.count)
                
                let intIndex = allPostIds.count // where intIndex < myDictionary.count
                let index = allPostIds.index(allPostIds.startIndex, offsetBy: intIndex - 1)
                
                allPostIds.remove(at: allPostIds.startIndex)
                print("after delete", allPostIds.count)
            }
            
            guard let user = self.user else {return}
            
            allPostIds.forEach({ (key,value) in
                
                thisGroup.enter()
                
                Database.fetchPostWithUIDAndPostID(creatoruid: user.uid, postId: key, completion: { (fetchedPost) in

                self.posts.append(fetchedPost)
                thisGroup.leave()
                    
                })

            })
            
            thisGroup.notify(queue: .main) {
                print(self.posts.count)
                self.posts.sort(by: { (p1, p2) -> Bool in
                    return p1.creationDate.compare(p2.creationDate) == .orderedDescending })
                
                self.collectionView?.reloadData()
            }
        
         
            self.posts.forEach({ (post) in
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
            self.posts.insert(post, at: 0)
//            self.posts.append(post)

            self.collectionView?.reloadData()
            
        }) { (err) in
            
            print("Failed to fetch ordered posts:", err)
        }
        
    }
    
      
    fileprivate func setupLogOutButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "gear").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleLogOut))
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
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        print("collectionview post count", self.posts.count)
        print("isfinishedpaging",self.isFinishedPaging)
        print(indexPath.item)
        if indexPath.item == self.posts.count - 1 && !isFinishedPaging{
            
            paginatePosts()
        }
        
        
        if isGridView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! UserProfilePhotoCell
            cell.post = posts[indexPath.item]
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: homePostCellId, for: indexPath) as! HomePostCell
            cell.post = posts[indexPath.item]
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
    
    var user: User?
    
    fileprivate func fetchUser() {

        // uid using userID if exist, if not, uses current user, if not uses blank
        
        let uid = userId ?? Auth.auth().currentUser?.uid ?? ""
        
//        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        Database.fetchUserWithUID(uid: uid) { (user) in
            self.user = user
            self.navigationItem.title = self.user?.username
            self.collectionView?.reloadData()
            
            self.paginatePosts()
            
        }
        
    }
    
}


