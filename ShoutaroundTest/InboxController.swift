//
//  InboxController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/19/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class InboxController: UICollectionViewController,UICollectionViewDelegateFlowLayout, InboxCellDelegate {
    
    var messages = [Message]()
    let inboxCellId = "inboxCellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        navigationItem.title = "Inbox"
        collectionView?.register(InboxCell.self, forCellWithReuseIdentifier: inboxCellId)
        fetchBookmarks()
        collectionView?.backgroundColor = UIColor.white
        
    
    }
    
    func fetchBookmarks(){
        
        let myGroup = DispatchGroup()
        
        guard let currentUserUID = Auth.auth().currentUser?.uid else {return}
        
        Database.fetchMessageForUID(userUID: currentUserUID) { (fetchedMessages) in
            self.messages = fetchedMessages
            self.collectionView?.reloadData()
//            self.messages.forEach({ messageSingle in
//                
//                
//                
//                
////                guard let dictionary = value as? [String: Any] else {return}
////                guard let senderUID = dictionary["senderUID"] else {return}
////                guard let postID = dictionary["postUID"] else {return}
////                guard let message = dictionary["message"] else {return}
////                guard let creationTime = dictionary["creationDate"] else {return}
//                myGroup.enter()
//                Database.fetchPostWithPostID(postId: messageSingle.postId, completion: { (post) in
//                    self.messagesPost.append(post)
//                    myGroup.leave()
//                })
//                
//                Database.fetchUserWithUID(uid: messageSingle.senderUID, completion: { (user) in
//                    self.senderUser.append(user)
//                    myGroup.leave()
//                })
//            })
        }

    }
    
    // HOME POST CELL DELEGATE METHODS
    
    func didTapPicture(post: Post) {
        
        let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
        pictureController.selectedPost = post
        
        
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    
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
        print("Refresh Message Post")
    }
    
//    func refreshMessage(message: Message) {
//        let index = messages.index { (message) -> Bool in
//            message.postId  == post.id
//        }
//        
//        let filteredindexpath = IndexPath(row:index!, section: 0)
//        print(index)
//        if post.hasBookmarked == false{
//        
//        
//        self.messages[index!] = post
//        //        self.collectionView?.reloadItems(at: [filteredindexpath])
//    }
    
    func didTapMessage(post: Post) {
        
        let messageController = MessageController()
        messageController.post = post
        
        navigationController?.pushViewController(messageController, animated: true)
        
    }
    
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var displayMessage = messages[indexPath.item]
        
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: inboxCellId, for: indexPath) as! InboxCell
            cell.delegate = self
            cell.cellMessage = displayMessage
        
            return cell

        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
            return CGSize(width: view.frame.width, height: 220)
        
    }
    
    
}
