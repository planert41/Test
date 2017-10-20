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
    func didTapUser(post:Post)
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
            locationNameLabel.text = post?.locationName
            locationAdressLabel.text = post?.locationAdress
            emojiLabel.text = post?.emoji
            
            captionLabel.text = post?.caption
            
            //     setupAttributedLocationName()
            
            likeButton.setImage(post?.hasLiked == true ? #imageLiteral(resourceName: "like_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
            
            bookmarkButton.setImage(post?.hasBookmarked == true ? #imageLiteral(resourceName: "bookmark_ribbon_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "bookmark_ribbon_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)
            
            bookmarkButtonAdd.setImage(post?.hasBookmarked == true ? #imageLiteral(resourceName: "bookmark_ribbon_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "bookmark_ribbon_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)
            

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
    
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 9)
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
        return label
    }()
    
    
    let senderMessageLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 13)
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
        return label
    }()
    
    let locationAdressLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.textColor = UIColor.darkGray
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
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
        button.setImage(#imageLiteral(resourceName: "ribbon").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
        return button
        
    }()
    
    lazy var bookmarkButtonAdd: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "ribbon").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
        return button
        
    }()
    
    func handleBookmark() {
        
        //delegate?.didBookmark(for: self)
        
        guard let postId = self.cellMessage?.sendPost?.id else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let values = ["bookmarked": self.cellMessage?.sendPost?.hasBookmarked == true ? 0 : 1, "creatorUID": self.cellMessage?.sendPost?.creatorUID] as [String : Any]
        
        Database.database().reference().child("bookmarks").child(uid).child(postId).updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to bookmark post", err)
                return
            }
            print("Succesfully Saved Bookmark")
            var tempPost: Post? = self.cellMessage?.sendPost
            self.post?.hasBookmarked = !(self.post?.hasBookmarked)!
            var tempMessage = self.cellMessage
            
        }
        
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
        delegate?.didTapUser(post: post)
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
        var senderView = UIView()
            senderView.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
            senderMessageLabel.backgroundColor = senderView.backgroundColor
            
        addSubview(senderView)
        senderView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 55)
            
            
        addSubview(senderMessageLabel)
        senderMessageLabel.anchor(top: nil, left: nil, bottom: senderView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 25)


            

        senderView.addSubview(senderUsernameLabel)
        senderView.addSubview(senderMessageDate)
        senderView.addSubview(senderUserProfileImageView)

            
        senderUserProfileImageView.anchor(top: senderView.topAnchor, left: senderView.leftAnchor, bottom: senderView.bottomAnchor, right: nil, paddingTop: 3, paddingLeft: 3, paddingBottom: 3, paddingRight: 3, width: 0, height: 0)
        senderUserProfileImageView.widthAnchor.constraint(equalTo: senderUserProfileImageView.heightAnchor, multiplier: 1).isActive = true
        senderUserProfileImageView.layer.cornerRadius = 25/2
            
        senderMessageLabel.anchor(top: nil, left: senderUserProfileImageView.rightAnchor, bottom: senderView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 25)
            
        senderMessageDate.anchor(top: senderView.topAnchor, left: nil, bottom: senderMessageLabel.topAnchor, right: senderView.rightAnchor, paddingTop: 0, paddingLeft: 3, paddingBottom: 0, paddingRight: 0, width: 100, height: 0)
            
        addSubview(bookmarkButtonAdd)
        bookmarkButtonAdd.anchor(top: senderMessageLabel.topAnchor, left: nil, bottom: senderMessageLabel.bottomAnchor, right: senderView.rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 1, paddingRight: 20, width: 15, height: 0)
            
            
        senderUsernameLabel.anchor(top: senderView.topAnchor, left: senderUserProfileImageView.rightAnchor, bottom: senderMessageLabel.topAnchor, right: senderMessageDate.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            
            let senderBottomDividerView = UIView()
            senderBottomDividerView.backgroundColor = UIColor.lightGray
        addSubview(senderBottomDividerView)
            senderBottomDividerView.anchor(top: senderView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
            
            
        // Setup Action Buttons and PhotoImageView
        let buttonStackView = UIStackView(arrangedSubviews: [likeButton, commentButton, sendMessageButton, bookmarkButton])
        buttonStackView.distribution = .fillEqually
        
        addSubview(buttonStackView)
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: nil, bottom: senderView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageView.widthAnchor.constraint(equalTo: photoImageView.heightAnchor, multiplier: 1).isActive = true
        
        buttonStackView.anchor(top: nil, left: leftAnchor, bottom: senderView.topAnchor, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 5, paddingRight: 0, width: 120, height: 25)
        //        buttonStackView.widthAnchor.constraint(equalTo: photoImageView.heightAnchor, multiplier: 1).isActive = true
        
        
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(BookmarkPhotoCell.handlePictureTap))
        photoImageView.addGestureRecognizer(TapGesture)
        photoImageView.isUserInteractionEnabled = true
        
        let emojiRow = UIView()
        
        // Setup Bookmark Stack View
        
        addSubview(emojiRow)
        emojiRow.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: photoImageView.leftAnchor, paddingTop: 10, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 30)
        
        emojiRow.addSubview(emojiLabel)
        emojiLabel.anchor(top: emojiRow.topAnchor, left: emojiRow.leftAnchor, bottom: emojiRow.bottomAnchor, right: emojiRow.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 80, height: 0)
        
        addSubview(distanceLabel)
        distanceLabel.anchor(top: emojiRow.topAnchor, left: emojiLabel.rightAnchor, bottom: emojiRow.bottomAnchor, right: emojiRow.rightAnchor, paddingTop: 2, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 15)
        
        
        addSubview(locationNameLabel)
        
        locationNameLabel.anchor(top: emojiRow.bottomAnchor, left: leftAnchor, bottom: nil, right: emojiRow.rightAnchor, paddingTop: 10, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 15)
        
        addSubview(locationAdressLabel)
        locationAdressLabel.anchor(top: locationNameLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: photoImageView.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 24)
        
        addSubview(captionLabel)
        captionLabel.anchor(top: locationAdressLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: photoImageView.leftAnchor, paddingTop: 10, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        captionLabel.sizeToFit()
        
        
        // Adding Gesture Recognizers
        
        userProfileImageView.isUserInteractionEnabled = true
        let usernameTap = UITapGestureRecognizer(target: self, action: #selector(BookmarkPhotoCell.usernameTap))
        userProfileImageView.addGestureRecognizer(usernameTap)
        userProfileImageView.isUserInteractionEnabled = true
        
        
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(BookmarkPhotoCell.locationTap))
        locationNameLabel.addGestureRecognizer(locationTapGesture)
        locationNameLabel.isUserInteractionEnabled = true
        let locationTapGesture2 = UITapGestureRecognizer(target: self, action: #selector(BookmarkPhotoCell.locationTap))
        
        locationAdressLabel.addGestureRecognizer(locationTapGesture2)
        locationAdressLabel.isUserInteractionEnabled = true
        
        // Setup Dividers
        
        let topDividerView = UIView()
        topDividerView.backgroundColor = UIColor.lightGray
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor.lightGray
        
        addSubview(topDividerView)
        addSubview(bottomDividerView)
        
        topDividerView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        bottomDividerView.anchor(top: photoImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
