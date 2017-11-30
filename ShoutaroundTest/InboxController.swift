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

class InboxController: UICollectionViewController,UICollectionViewDelegateFlowLayout, ThreadCellDelegate {
    
    var messages = [Message](){
        didSet{
            self.updateCounts()
        }
    }
    
    var messageThreads = [MessageThread](){
        didSet{
            self.updateCounts()
        }
    }
    
    
    let inboxCellId = "inboxCellId"
    let threadCellId = "threadCellId"

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
    
        navigationItem.title = "Inbox (" + String(messageThreads.count) + ")"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Bookmarks", style: .plain, target: self, action: #selector(toBookmarks))
        
        collectionView?.register(ThreadCell.self, forCellWithReuseIdentifier: threadCellId)

        fetchMessageThreads()
        collectionView?.backgroundColor = UIColor.white
        view.addSubview(noResultsLabel)
        noResultsLabel.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 50)
        noResultsLabel.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchMessageThreads()
    }
    
    func updateCounts(){
        navigationItem.title = "Inbox (" + String(messageThreads.count) + ")"
        if messageThreads.count == 0 {
            noResultsLabel.isHidden = false
        } else {
            noResultsLabel.isHidden = true
        }
    }
    
    func toBookmarks(){
        tabBarController?.selectedIndex = 3
    }

    func fetchMessageThreads(){
        guard let currentUserUID = Auth.auth().currentUser?.uid else {return}
        
        Database.fetchMessageThreadsForUID(userUID: currentUserUID) { (messageThreads) in
            self.messageThreads = messageThreads
            self.collectionView?.reloadData()
        }
    }
    
    // THREAD CELL DELEGATE METHODS
    
    func didTapPicture(post: Post) {
        
        let pictureController = PictureController(collectionViewLayout: UICollectionViewFlowLayout())
        pictureController.selectedPost = post
        navigationController?.pushViewController(pictureController, animated: true)
    }
    
    
    func refreshPost(post: Post) {
        // Update Cache
        postCache.removeValue(forKey: post.id!)
        postCache[post.id!] = post
    }
    

    
    func didTapMessage(post: Post) {
        
        let messageController = MessageController()
        messageController.post = post
        navigationController?.pushViewController(messageController, animated: true)
        
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.item)
        
        if let collectionView = self.collectionView {
            let cell = collectionView.cellForItem(at: indexPath) as? ThreadCell
            let threadMessageController = ThreadMessageController(collectionViewLayout: UICollectionViewFlowLayout())
            threadMessageController.messageThread = messageThreads[indexPath.item]
            threadMessageController.post = cell?.post
            navigationController?.pushViewController(threadMessageController, animated: true)
        }
    }
        

    
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messageThreads.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var displayMessage = messageThreads[indexPath.item]
        
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: threadCellId, for: indexPath) as! ThreadCell
//            cell.delegate = self
            cell.messageThread = displayMessage
            cell.delegate = self
            print("Displayed Message Thread", displayMessage)
        
            return cell

        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
            return CGSize(width: view.frame.width, height: 100)
        
    }
    
    
}
