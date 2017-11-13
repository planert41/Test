//
//  MessageCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/19/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
//
//  BookmarkPhotoCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/22/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//


import UIKit
import Firebase

protocol InboxCellDelegate {
    func didTapComment(post:Post)
    func didTapUser(uid:String)
    func didTapLocation(post:Post)
    func didTapMessage(post:Post)
   // func deletePost(post:Post)
    func refreshPost(post:Post)
    func didTapPicture(post:Post)
    
}

class InboxCell: UICollectionViewCell {
    
    let adressLabelSize = 12 as CGFloat
    var delegate: InboxCellDelegate?
    
    var cellMessage: Message? {
        didSet {
            
            print(cellMessage?.senderUser)
            
            post = cellMessage?.sendPost
            self.senderUsernameLabel.text = cellMessage?.senderUser?.username
            self.senderMessageLabel.text = cellMessage?.senderMessage
            self.post = cellMessage?.sendPost
            guard let imageUrl = cellMessage?.senderUser?.profileImageUrl else {return}
            senderUserProfileImageView.loadImage(urlString: imageUrl)
            
            let timeAgoDisplay = cellMessage?.creationDate.timeAgoDisplay()
            let attributedText = NSMutableAttributedString(string: timeAgoDisplay!, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12),NSForegroundColorAttributeName: UIColor.darkGray])
            
            self.senderMessageDate.attributedText = attributedText
            
        }
    }
    
    var post: Post? {
    
        didSet {
    
            guard let imageUrl = post?.imageUrl else {return}
            photoImageView.loadImage(urlString: imageUrl)
            userProfileImageView.loadImage(urlString: (post?.user.profileImageUrl)!)
            usernameLabel.text = post?.user.username
    
            locationNameLabel.text = post?.locationName
            locationAdressLabel.text = post?.locationAdress
            emojiLabel.text = post?.emoji
            captionLabel.text = post?.caption
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d YYYY"
            postDateLabel.text = formatter.string(from: (post?.creationDate)!)
            
            
            bookmarkButton.setImage(post?.hasBookmarked == true ? #imageLiteral(resourceName: "bookmark_ribbon_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "bookmark_ribbon_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)
            
            print("Post Distance is",post?.distance)
            if post?.distance != nil && post?.locationGPS?.coordinate.longitude != 0 && post?.locationGPS?.coordinate.latitude != 0 {
                
                guard let postdistance = post?.distance else {return}
                let distanceformat = ".2"
                
                if postdistance < 100000 {
                    // Convert to M to KM
                    let locationDistance = postdistance/1000
                    distanceLabel.text =  " \(locationDistance.format(f: distanceformat)) km"
                }
                    
                else if postdistance >= 100000 {
                    // Convert to M to KM
                    let locationDistance = postdistance/100000
                    distanceLabel.text =  " \(locationDistance.format(f: distanceformat))K km"
                }
            }
        }
    }
    
    let senderUserProfileImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
        
    }()
    
    let senderUsernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(senderUsernameTap))
        label.addGestureRecognizer(tap)
        return label
    }()
    
    
    let senderMessageLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.darkGray
        label.sizeToFit()
        return label
    }()
    
    let senderMessageDate: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.textAlignment = NSTextAlignment.right
        label.font = UIFont.boldSystemFont(ofSize: 9)
        label.sizeToFit()
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.sizeToFit()
        return label
    }()
    
    let distanceLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.mainBlue()
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    let userProfileImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .blue
        return iv
        
    }()
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
        
    }()
    
    let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.white
        return label
        
    }()
    
    let locationNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.black
        label.sizeToFit()
        label.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(locationTap))
        label.addGestureRecognizer(tap)
        return label
    }()
    
    let locationAdressLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.textColor = UIColor.darkGray
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(locationTap))
        label.addGestureRecognizer(tap)
        return label
    }()
    
    let captionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.sizeToFit()
        return label
    }()
    
    let postDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.textColor = UIColor.gray
        label.sizeToFit()
        return label
    }()
    
    let captionTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.boldSystemFont(ofSize: 12)
        return tv
    }()
    
    lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        return button
        
    }()
    
    func handleLike() {
        //      delegate?.didLike(for: self)
        
        guard let postId = self.cellMessage?.sendPost?.id else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let values = [postId: self.cellMessage?.sendPost?.hasLiked == true ? 0 : 1]
        Database.database().reference().child("likes").child(uid).updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to like post", err)
                return
            }
            print("Succesfully Saved Likes")
            self.post?.hasLiked = !(self.post?.hasLiked)!
        }
    }
    
    // Bookmark
    
    lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "bookmark_ribbon_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
        return button
        
    }()
    
    func handleBookmark() {
        
        //delegate?.didBookmark(for: self)
        
        guard let postId = self.post?.id else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let bookmarkTime = Date().timeIntervalSince1970
        
        let values = ["bookmarked": self.post?.hasBookmarked == true ? 0 : 1, "creatorUID": post?.creatorUID, "bookmarkDate": bookmarkTime] as [String : Any]
        
        Database.database().reference().child("bookmarks").child(uid).child(postId).updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to bookmark post", err)
                return
            }
            print("Succesfully Saved Bookmark")
            self.post?.hasBookmarked = !(self.post?.hasBookmarked)!
            self.delegate?.refreshPost(post: self.post!)
            
        }
        
        self.bookmarkButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        
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
    
    
    // Comments
    
    lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "comment").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        return button
        
    }()
    
    func handleComment() {
        guard let post = self.cellMessage?.sendPost else {return}
        delegate?.didTapComment(post: post)
    }
    
    // Send Message
    
    lazy var sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "message").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleMessage), for: .touchUpInside)
        return button
        
    }()
    
    func handleMessage(){
        guard let post = self.cellMessage?.sendPost else {return}
        delegate?.didTapMessage(post: post)
        
    }
    
    // Username/Location Tap
    
    func usernameTap() {
        print("Tap username label", self.cellMessage?.sendPost?.user.username ?? "")
        guard let post = self.cellMessage?.sendPost else {return}
        guard let uid = self.cellMessage?.sendPost?.user.uid else {return}
        delegate?.didTapUser(uid: uid)
    }
    
    func senderUsernameTap() {
        print("Tap username label", self.cellMessage?.senderUser?.username ?? "")
        guard let post = self.cellMessage?.sendPost else {return}
        guard let uid = self.cellMessage?.senderUser?.uid else {return}
        delegate?.didTapUser(uid: uid)
    }
    
    func locationTap() {
        print("Tap location label", self.cellMessage?.sendPost?.locationName ?? "")
        guard let post = self.cellMessage?.sendPost else {return}
        delegate?.didTapLocation(post: post)
    }
    
    func handlePictureTap() {
        guard let post = self.cellMessage?.sendPost else {return}
        delegate?.didTapPicture(post: post)
    }
    
    
        override init(frame: CGRect) {
        super.init(frame:frame)
            
        // Sender View
            
        var senderView = UIView()
        senderView.backgroundColor = UIColor.rgb(red: 204, green: 230, blue: 255)
        senderMessageLabel.backgroundColor = senderView.backgroundColor
            
        addSubview(senderView)
        addSubview(senderUserProfileImageView)
        addSubview(senderUsernameLabel)
        addSubview(senderMessageLabel)
        addSubview(senderMessageDate)
        
        senderView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 55)
            
        senderUserProfileImageView.anchor(top: senderView.topAnchor, left: senderView.leftAnchor, bottom: senderView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 0, width: 40, height: 40)
        senderUserProfileImageView.widthAnchor.constraint(equalTo: senderUserProfileImageView.heightAnchor, multiplier: 1).isActive = true
        senderUserProfileImageView.layer.cornerRadius = 40/2
        senderUserProfileImageView.clipsToBounds = true
            
        senderUsernameLabel.anchor(top: senderUserProfileImageView.topAnchor, left: senderUserProfileImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 100, height: 15)
            
        senderMessageLabel.anchor(top: senderUsernameLabel.bottomAnchor, left: senderUserProfileImageView.rightAnchor, bottom: senderView.bottomAnchor, right: senderView.rightAnchor, paddingTop: 2, paddingLeft: 10, paddingBottom: 2, paddingRight: 0, width: 0, height: 0)
       
        senderMessageDate.anchor(top: senderView.topAnchor, left: nil, bottom: senderUsernameLabel.bottomAnchor, right: senderView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 0)
            
        addSubview(bookmarkButton)
        bookmarkButton.anchor(top: senderMessageLabel.topAnchor, left: nil, bottom: senderMessageLabel.bottomAnchor, right: senderView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        bookmarkButton.widthAnchor.constraint(equalTo: bookmarkButton.heightAnchor, multiplier: 1).isActive = true

        let senderBottomDividerView = UIView()
        senderBottomDividerView.backgroundColor = UIColor.lightGray
        addSubview(senderBottomDividerView)
            senderBottomDividerView.anchor(top: senderView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
            
        // Setup Action Buttons and PhotoImageView
        
        var postView = UIView()
        postView.backgroundColor = UIColor.white
        postView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handlePictureTap))
        postView.addGestureRecognizer(tap)
            
            
        addSubview(postView)
        postView.anchor(top: senderView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            
        addSubview(photoImageView)
            
        photoImageView.anchor(top: postView.topAnchor, left: nil, bottom: postView.bottomAnchor, right: postView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageView.widthAnchor.constraint(equalTo: photoImageView.heightAnchor, multiplier: 1).isActive = true
        
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(BookmarkPhotoCell.handlePictureTap))
        photoImageView.addGestureRecognizer(TapGesture)
        photoImageView.isUserInteractionEnabled = true
        
            
        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: postView.topAnchor, left: postView.leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        userProfileImageView.layer.cornerRadius = 40/2
        userProfileImageView.clipsToBounds = true
        userProfileImageView.layer.borderWidth = 0.25
        userProfileImageView.layer.borderColor = UIColor.lightGray.cgColor
            
        addSubview(usernameLabel)
        usernameLabel.anchor(top: userProfileImageView.topAnchor, left: userProfileImageView.rightAnchor, bottom: userProfileImageView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 80, height: 0)
            usernameLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        
            
        addSubview(emojiLabel)
        emojiLabel.anchor(top: userProfileImageView.topAnchor, left: nil, bottom: userProfileImageView.bottomAnchor, right: photoImageView.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        emojiLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        
        addSubview(locationNameLabel)
        locationNameLabel.anchor(top: userProfileImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: photoImageView.leftAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 15)
            
        addSubview(locationAdressLabel)
        locationAdressLabel.anchor(top: locationNameLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: photoImageView.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 24)
        
        addSubview(captionLabel)
        captionLabel.anchor(top: locationAdressLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: photoImageView.leftAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        captionLabel.sizeToFit()
            
        addSubview(postDateLabel)
        postDateLabel.anchor(top: nil, left: postView.leftAnchor, bottom: postView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 5, paddingRight: 0, width: 100, height: 30)

        // Add Gesture Recognizers
        let senderTap = UITapGestureRecognizer(target: self, action: #selector(senderUsernameTap))
        senderUserProfileImageView.isUserInteractionEnabled = true
        senderUserProfileImageView.addGestureRecognizer(senderTap)
            
        let senderTap1 = UITapGestureRecognizer(target: self, action: #selector(senderUsernameTap))
        senderUsernameLabel.isUserInteractionEnabled = true
        senderUsernameLabel.addGestureRecognizer(senderTap1)
            
        let userTap = UITapGestureRecognizer(target: self, action: #selector(usernameTap))
        userProfileImageView.isUserInteractionEnabled = true
        userProfileImageView.addGestureRecognizer(userTap)
            
        let userTap1 = UITapGestureRecognizer(target: self, action: #selector(usernameTap))
        usernameLabel.isUserInteractionEnabled = true
        usernameLabel.addGestureRecognizer(userTap1)
            
        let locationGesture = UITapGestureRecognizer(target: self, action: #selector(locationTap))
        locationNameLabel.isUserInteractionEnabled = true
        locationNameLabel.addGestureRecognizer(locationGesture)

        let locationGesture1 = UITapGestureRecognizer(target: self, action: #selector(locationTap))
        locationAdressLabel.isUserInteractionEnabled = true
        locationAdressLabel.addGestureRecognizer(locationGesture1)
            
        // Setup Dividers
        
        let topDividerView = UIView()
        topDividerView.backgroundColor = UIColor.lightGray
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor.lightGray
        
        addSubview(topDividerView)
        addSubview(bottomDividerView)
        
        topDividerView.anchor(top: postView.topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        bottomDividerView.anchor(top: postView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
