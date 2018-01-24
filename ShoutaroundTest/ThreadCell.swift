//
//  ThreadCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 11/27/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Firebase

protocol ThreadCellDelegate {
    func refreshPost(post:Post)
    func didTapPicture(post:Post)
}

class ThreadCell: UICollectionViewCell {

    var delegate: ThreadCellDelegate?
    
    
    var messageThread: MessageThread? {
        didSet{
            
            // Set Posts
            Database.fetchPostWithPostID(postId: (messageThread?.postId)!) { (post, error) in
                if let error = error {
                    print("Error Fetching Message Thread Post \(self.messageThread?.threadID)")
                }
            self.post = post
            }
            
//            print(self.messageThread)
//             Set Latest Message as Displayed Message
            self.fetchLatestMessage(messageThread: self.messageThread)
            
            // Set Thread Users
            
            if let userList = messageThread?.threadUsers.joined(separator: ",") {
                let userAttributedText = NSAttributedString(string: "Re: " + userList, attributes: [NSFontAttributeName: UIFont.italicSystemFont(ofSize: 10),NSForegroundColorAttributeName: UIColor.gray])
                self.usersLabel.attributedText = userAttributedText
            }
        }
    }
    
    var post: Post? {
        didSet{
            guard let imageUrl = post?.imageUrl else {return}
            photoImageView.loadImage(urlString: imageUrl)
            postEmojiLabel.text = post?.emoji
            
            bookmarkButton.setImage(post?.hasBookmarked == true ? #imageLiteral(resourceName: "bookmark_ribbon_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "bookmark_ribbon_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)
            
        }
    }
    
    var displayedMessage: Message? {
        didSet{
            guard let displayedMessage = displayedMessage else {return}
            Database.fetchUserWithUID(uid: displayedMessage.senderUID) { (user) in
                self.user = user
            }
            
            print("Displayed Msg: \(displayedMessage)")
            
            let formatter = DateFormatter()
//            formatter.dateFormat = "MMM d YYYY, h:mm a"
            formatter.dateFormat = "MMM d YYYY"
            let timeAgoDisplay = formatter.string(from: displayedMessage.creationDate)
            self.messageDate.text = timeAgoDisplay
            self.messageDate.sizeToFit()
            self.messageTextView.text = self.displayedMessage?.message
            self.messageTextView.sizeToFit()
        }
    }
    
    var user: User? = nil {
        didSet{
            guard let profileImageUrl = self.user?.profileImageUrl else {return}
            self.userProfileImageView.loadImage(urlString: profileImageUrl)
            self.usernameLabel.text = self.user?.username
            self.usernameLabel.sizeToFit()
        }
    }
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
        
    }()
    
    let messageView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .blue
        return iv
    }()
    
    var usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.sizeToFit()
        return label
    }()
    
    var messageDate: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.textAlignment = NSTextAlignment.right
        label.font = UIFont.boldSystemFont(ofSize: 9)
        label.textColor = UIColor.lightGray
        label.sizeToFit()
        return label
    }()
    
    var messageTextView: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.numberOfLines = 0
        label.sizeToFit()
        return label
    }()
    
    var usersLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.sizeToFit()
        return label
    }()
    
    let postActionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    var postEmojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.white
        return label
    }()
    
    lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "bookmark_ribbon_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
        return button
        
    }()
    
    func handleBookmark() {
        
        //    delegate?.didBookmark(for: self)
        
        guard let postId = self.post?.id else {return}
        guard let creatorId = self.post?.creatorUID else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        Database.handleBookmark(postId: postId, creatorUid: creatorId){
        }
        
        // Animates before database function is complete
        
        if (self.post?.hasBookmarked)! {
            self.post?.listCount -= 1
        } else {
            self.post?.listCount += 1
        }
        self.post?.hasBookmarked = !(self.post?.hasBookmarked)!
        self.delegate?.refreshPost(post: self.post!)
        
        bookmarkButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.bookmarkButton.transform = .identity
            },
                       completion: nil)

        
    }
    
    
    func fetchLatestMessage(messageThread: MessageThread!){
    
        guard let messageDictionaries = messageThread.messageDictionaries else {return}
        var messages: [Message] = []
        
        for (key,value) in messageDictionaries {
            let tempDictionary = value as! [String:Any]
            let tempMessage = Message.init(messageID: key, dictionary: tempDictionary)
            messages.append(tempMessage)
        }
    
        messages.sorted { (p1, p2) -> Bool in
            return p1.creationDate.compare(p2.creationDate) == .orderedDescending
        }
        
        self.displayedMessage = messages[0]
    }

    
    override init(frame: CGRect) {
        super.init(frame:frame)
     
    // Add Photo
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageView.widthAnchor.constraint(equalTo: photoImageView.heightAnchor, multiplier: 1).isActive = true
        
    // Add Post Emoji and Bookmark Button
        addSubview(postActionView)
        postActionView.anchor(top: nil, left: photoImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        addSubview(bookmarkButton)
        bookmarkButton.anchor(top: postActionView.topAnchor, left: nil, bottom: postActionView.bottomAnchor, right: postActionView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 20, height: 20)
        
        addSubview(postEmojiLabel)
        postEmojiLabel.anchor(top: postActionView.topAnchor, left: photoImageView.rightAnchor, bottom: postActionView.bottomAnchor, right: bookmarkButton.leftAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        
    // Add Message View
        addSubview(messageView)
        messageView.anchor(top: topAnchor, left: photoImageView.rightAnchor, bottom: postActionView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(messageDate)
        messageDate.anchor(top: messageView.topAnchor, left: nil, bottom: nil, right: messageView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 6, width: 100, height: 10)
        
        addSubview(usersLabel)
        usersLabel.anchor(top: nil, left: messageView.leftAnchor, bottom: messageView.bottomAnchor, right: messageView.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 10)
        
        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: messageView.topAnchor, left: messageView.leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 0, width: 30, height: 30)
        userProfileImageView.widthAnchor.constraint(equalTo: userProfileImageView.heightAnchor, multiplier: 1).isActive = true
        userProfileImageView.layer.cornerRadius = 25/2
        userProfileImageView.clipsToBounds = true
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: userProfileImageView.topAnchor, left: userProfileImageView.rightAnchor, bottom: nil, right: messageDate.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        usernameLabel.heightAnchor.constraint(equalTo: userProfileImageView.heightAnchor, multiplier: 0.5).isActive = true
//        usernameLabel.backgroundColor = UIColor.yellow

    
        addSubview(messageTextView)
        messageTextView.anchor(top: usernameLabel.bottomAnchor, left: userProfileImageView.rightAnchor, bottom: nil, right: messageView.rightAnchor, paddingTop: 2, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        messageTextView.sizeToFit()
//        messageTextView.backgroundColor = UIColor.blue
        
        let senderBottomDividerView = UIView()
        senderBottomDividerView.backgroundColor = UIColor.lightGray
        addSubview(senderBottomDividerView)
        senderBottomDividerView.anchor(top: postActionView.bottomAnchor, left: photoImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
    
    
}


