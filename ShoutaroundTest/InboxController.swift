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
    
    var messages = [Message](){
        didSet{
            self.updateCounts()
        }
    }
    let inboxCellId = "inboxCellId"

    var noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Messages"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = UIColor.black
        label.isHidden = true
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        navigationItem.title = "Inbox (" + String(messages.count) + ")"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Bookmarks", style: .plain, target: self, action: #selector(toBookmarks))
        
        collectionView?.register(InboxCell.self, forCellWithReuseIdentifier: inboxCellId)
        fetchMessages()
        collectionView?.backgroundColor = UIColor.white
        view.addSubview(noResultsLabel)
        noResultsLabel.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 50)
        noResultsLabel.isHidden = true
    
    }
    
    func updateCounts(){
        navigationItem.title = "Inbox (" + String(messages.count) + ")"
        if messages.count == 0 {
            noResultsLabel.isHidden = false
        } else {
            noResultsLabel.isHidden = true
        }
    }
    
    func toBookmarks(){
        tabBarController?.selectedIndex = 3
    }
    
    
    func fetchMessages(){
        
        guard let currentUserUID = Auth.auth().currentUser?.uid else {return}
        
        Database.fetchMessageForUID(userUID: currentUserUID) { (fetchedMessages) in

            self.messages = fetchedMessages
            self.collectionView?.reloadData()
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
    
    func didTapUser(uid: String) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.userId = uid
        
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
