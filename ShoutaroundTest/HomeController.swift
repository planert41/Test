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

class HomeController: UICollectionViewController, UICollectionViewDelegateFlowLayout, HomePostCellDelegate {
    
    let cellId = "cellId"
    var posts = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//            let name = NSNotification.Name(rawValue: "UpdateFeed")
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: SharePhotoController.updateFeedNotificationName, object: nil)
        
        collectionView?.backgroundColor = .white
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: cellId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        setupNavigationItems()
        
        fetchAllPosts()
    
    }
    
    func handleUpdateFeed() {
        handleRefresh()
    }
    
    // IOS9 - let refreshControl = UIRefreshControl()
    
    func handleRefresh() {

        // RemoveAll so that when user follow/unfollows it updates
        
        posts.removeAll()
        fetchAllPosts()
        self.collectionView?.refreshControl?.endRefreshing()
        print("Refresh")
    }
    
    fileprivate func fetchAllPosts() {
        fetchPosts()
        fetchFollowingUserIds()
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
                
                
                guard let uid = Auth.auth().currentUser?.uid else {return}
                
                Database.database().reference().child("likes").child(key).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
                    print(snapshot)
                    
                    if let value = snapshot.value as? Int, value == 1 {
                        post.hasLiked = true
                    } else {
                        post.hasLiked = false
                    }
                    
                    self.posts.append(post)
                    
                    self.posts.sort(by: { (p1, p2) -> Bool in
                        return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                        })
                    
                    self.collectionView?.reloadData()
                    
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
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! HomePostCell
        cell.post = posts[indexPath.item]
        cell.delegate = self
        
        return cell
    }
    
    func didLike(for cell: HomePostCell) {
        print("Handling Like inside controller")
        
        guard let indexPath = collectionView?.indexPath(for: cell) else {return}
        
        var post = self.posts[indexPath.item]
        print(post.caption)
        
        
        guard let postId = post.id else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let values = [uid: post.hasLiked == true ? 0 : 1]
        
        
        
        Database.database().reference().child("likes").child(postId).updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to like post", err)
                return
            }
            print("Succesfully Saved Likes")
            post.hasLiked = !post.hasLiked
            
            self.posts[indexPath.item] = post
            self.collectionView?.reloadItems(at: [indexPath])
            
        }
        
        
    }
    
    func didTapComment(post: Post) {
        
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.post = post
        
        navigationController?.pushViewController(commentsController, animated: true)
    }
    
    
    func didSendMessage(post:Post){
        
            print("emailtest")
            let mailgun = Mailgun.client(withDomain: "sandbox036bf1de5ba44e7e8ad4f19b9cc5b7d8.mailgun.org", apiKey: "key-2562988360d4f7f8a1fcc6f3647b446a")
        
        let message = MGMessage(from:"Excited User <someone@sample.org>",
                                to:"Jay Baird <planert41@gmail.com>",
                                subject:"Mailgun is awesome!",
                                body:("<html>Inline image here: <img src=cid:image01.jpg></html>"))!
        

        
        let postImage = CustomImageView()
        postImage.loadImage(urlString: post.imageUrl)

//        message.add(postImage.image, withName: "image01", type: .JPEGFileType, inline: true)
        message.html = "<html>Inline image here: <img src="+post.imageUrl+" width = \"25%\" height = \"25%\"/></html>"

        
        // someImage: UIImage
        // type can be either .JPEGFileType or .PNGFileType
        // message.add(postImage.image, withName: "image01", type:.PNGFileType)
        
        
            mailgun?.send(message, success: { (success) in
                print("success sending email")
            }, failure: { (error) in
                print(error)
            })
        
    }
}
