//
//  BookmarkPhotoCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/22/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//


import UIKit
import Firebase

protocol ThreadMessageHeaderDelegate {

    func didTapUser(post:Post)
    func didTapLocation(post:Post)
    func didTapPicture(post:Post)
    func didTapMessage(post:Post)
    func refreshPost(post:Post)
    
//    func didTapComment(post:Post)
//    func deletePost(post:Post)
//
}

class ThreadMessageHeader: UICollectionViewCell {
    
// ThreadUsers Variables
    var threadUsers: [String]?{
        didSet{
            threadUsersView.text = "Re: " + (threadUsers?.joined(separator: ","))!
        }
    }
    
    var threadUserUids: [String]? = []
    
    var threadUsersView: PaddedUILabel = {
        let label = PaddedUILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.mainBlue()
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor(white: 0, alpha: 0.2)
        return label
    }()
    
    
    let adressLabelSize = 8 as CGFloat
    var delegate: ThreadMessageHeaderDelegate?
    
    var bookmarkDate: Date?{
        didSet{
            //            let timeAgoDisplay = bookmarkDate?.timeAgoDisplay()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d YYYY"
            let timeAgoDisplay = formatter.string(from: bookmarkDate!)
            dateLabel.text = timeAgoDisplay
        }
    }
    var post: Post? {
        didSet {
            
        // Post Image
            guard let imageUrl = post?.imageUrl else {return}
            photoImageView.loadImage(urlString: imageUrl)
            
        // Post User Details
            guard let profileImageUrl = post?.user.profileImageUrl else {return}
            userProfileImageView.loadImage(urlString: profileImageUrl)
            usernameLabel.text = post?.user.username
            
        // Other Post Details
            if let locationNameDisplay = post?.locationName {
                // If no location  name and showing GPS, show the adress instead
                if locationNameDisplay.hasPrefix("GPS"){
                    locationNameLabel.text = post?.locationAdress
                    locationAdressLabel.text = ""
                } else {
                    locationNameLabel.text = locationNameDisplay
                    locationAdressLabel.text = post?.locationAdress
                    
                }
            }
            
            locationNameLabel.sizeToFit()
            nonRatingEmojiLabel.text = (post?.ratingEmoji)! + (post?.nonRatingEmoji.joined())!
            nonRatingEmojiLabel.sizeToFit()
            captionLabel.text = post?.caption
            captionLabel.sizeToFit()
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d YYYY"
            if let creationDate = post?.creationDate {
                let dateCreated = formatter.string(from: creationDate)
                dateLabel.text = dateCreated
            } else {
                dateLabel.text = ""
            }
            
        // Post Social Details
        
            if (post?.bookmarkCount)! > 0 {
                bookmarkCount.text = String(describing: (post?.bookmarkCount)!)
            } else {
                bookmarkCount.text = ""
            }
            
            if (post?.messageCount)! > 0 {
                messageCount.text = String(describing: (post?.messageCount)!)
            } else {
                messageCount.text = ""
            }
            
            if (post?.likeCount)! > 0 {
                likeCount.text = String(describing: (post?.likeCount)!)
            } else {
                likeCount.text = ""
            }
            
            
            likeButton.setImage(post?.hasLiked == true ? #imageLiteral(resourceName: "like_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
            
            bookmarkButton.setImage(post?.hasBookmarked == true ? #imageLiteral(resourceName: "bookmark_ribbon_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "bookmark_ribbon_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)
            
        }
    }
    

    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 11)
        label.sizeToFit()
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
    
    let nonRatingEmojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.textAlignment = NSTextAlignment.right
        label.backgroundColor = UIColor.white
        return label
    }()
    
    let ratingEmojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.right
        label.backgroundColor = UIColor.white
        return label
    }()
    
    let locationNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.numberOfLines = 0
        label.textColor = UIColor.black
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.sizeToFit()
        label.frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        return label
    }()
    
    let locationAdressLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.boldSystemFont(ofSize: 8)
        label.textColor = UIColor.darkGray
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.sizeToFit()
        return label
    }()
    
    let captionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.numberOfLines = 0
        //        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        //        label.sizeToFit()
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 9)
        label.textAlignment = NSTextAlignment.left
        label.textColor = UIColor.gray
        label.sizeToFit()
        return label
    }()
    
    let captionTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.boldSystemFont(ofSize: 12)
        return tv
    }()
    
    // Social Counts
    let bookmarkCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:10)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    let messageCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:10)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    let likeCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:10)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    
    lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        return button
        
    }()
    
    func handleLike() {
        guard let postId = self.post?.id else {return}
        guard let creatorId = self.post?.creatorUID else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        self.likeButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        self.layoutIfNeeded()
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.likeButton.transform = .identity
                        self?.likeButton.layoutIfNeeded()
                        
            },
                       completion: nil)
        
        
        Database.handleLike(postId: postId, creatorUid: creatorId){
        }
        
        // Animates before database function is complete
        
        if (self.post?.hasLiked)! {
            self.post?.likeCount -= 1
        } else {
            self.post?.likeCount += 1
        }
        self.post?.hasLiked = !(self.post?.hasLiked)!
        
        self.delegate?.refreshPost(post: self.post!)

    }
    
    // Bookmark
    
    lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "ribbon").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
        return button
        
    }()
    
    func handleBookmark() {
        
        //    delegate?.didBookmark(for: self)
        
        guard let postId = self.post?.id else {return}
        guard let creatorId = self.post?.creatorUID else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let post = self.post else {return}
        
        Database.handleBookmark(postId: postId, creatorUid: creatorId){
        }
        
        // Animates before database function is complete
        
        if (self.post?.hasBookmarked)! {
            self.post?.bookmarkCount -= 1
        } else {
            self.post?.bookmarkCount += 1
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
        
        // Update Cache
        postCache.removeValue(forKey: postId)
        postCache[postId] = post
    }
    
    
    // Comments
//    
//    lazy var commentButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setImage(#imageLiteral(resourceName: "comment").withRenderingMode(.alwaysOriginal), for: .normal)
//        button.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
//        return button
//        
//    }()
//    
//    func handleComment() {
//        guard let post = post else {return}
//        delegate?.didTapComment(post: post)
//    }
//    
    // Send Message
    
    lazy var sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "message").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleMessage), for: .touchUpInside)
        return button
        
    }()
    
    func handleMessage(){
        guard let post = post else {return}
        delegate?.didTapMessage(post: post)
        
    }
    
    // Username/Location Tap
    
    func usernameTap() {
        print("Tap username label", post?.user.username ?? "")
        guard let post = post else {return}
        delegate?.didTapUser(post: post)
    }
    
    func locationTap() {
        print("Tap location label", post?.locationName ?? "")
        guard let post = post else {return}
        delegate?.didTapLocation(post: post)
    }
    
    func handlePictureTap() {
        guard let post = post else {return}
        delegate?.didTapPicture(post: post)
    }
    
    
    
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        // MessageThread User Labels
        addSubview(threadUsersView)
        threadUsersView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 20)
        
        // Photo Image View
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: threadUsersView.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageView.widthAnchor.constraint(equalTo: photoImageView.heightAnchor, multiplier: 1).isActive = true
        
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(BookmarkPhotoCell.handlePictureTap))
        photoImageView.addGestureRecognizer(TapGesture)
        photoImageView.isUserInteractionEnabled = true
        
        // Detail View
        
        let detailView = UIView()
        addSubview(detailView)
        detailView.anchor(top: nil, left: photoImageView.rightAnchor, bottom: threadUsersView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 20)
        
        // Setup Bookmark Stack View
        
        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: topAnchor, left: photoImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        userProfileImageView.layer.cornerRadius = 30/2
        userProfileImageView.clipsToBounds = true
        userProfileImageView.layer.borderWidth = 0.25
        userProfileImageView.layer.borderColor = UIColor.lightGray.cgColor
        
        // Tagged Emoji Data
        
        addSubview(nonRatingEmojiLabel)
        nonRatingEmojiLabel.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 60, height: 10)
        nonRatingEmojiLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: userProfileImageView.topAnchor, left: userProfileImageView.rightAnchor, bottom: userProfileImageView.bottomAnchor, right: nonRatingEmojiLabel.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        //        usernameLabel.heightAnchor.constraint(equalTo: userProfileImageView.heightAnchor, multiplier: 0.5).isActive = true
        
        usernameLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        
        
        // Location Data
        
        addSubview(locationNameLabel)
        locationNameLabel.anchor(top: userProfileImageView.bottomAnchor, left: photoImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        locationNameLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 20).isActive = true
        locationNameLabel.sizeToFit()
        
        
        addSubview(locationAdressLabel)
        locationAdressLabel.anchor(top: locationNameLabel.bottomAnchor, left: photoImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        locationAdressLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 10).isActive = true
        locationAdressLabel.sizeToFit()
        
        
        // Location Distance
        
        addSubview(captionLabel)
        captionLabel.anchor(top: locationAdressLabel.bottomAnchor, left: photoImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 2, paddingRight: 20, width: 0, height: 0)
        captionLabel.bottomAnchor.constraint(lessThanOrEqualTo: detailView.topAnchor).isActive = true
        captionLabel.sizeToFit()
        
        let stackview = UIStackView(arrangedSubviews: [likeButton,likeCount, bookmarkButton, bookmarkCount, sendMessageButton, messageCount])
        stackview.distribution = .fillEqually
        addSubview(stackview)
        stackview.anchor(top: detailView.topAnchor, left: nil, bottom: detailView.bottomAnchor, right: detailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        stackview.widthAnchor.constraint(equalTo: stackview.heightAnchor, multiplier: 6).isActive = true
//        
//        addSubview(bookmarkButton)
//        bookmarkButton.anchor(top: detailView.topAnchor, left: nil, bottom: detailView.bottomAnchor, right: detailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 2, paddingRight: 10, width: 0, height: 0)
//        bookmarkButton.widthAnchor.constraint(equalTo: sendMessageButton.heightAnchor, multiplier: 1).isActive = true
        
        addSubview(dateLabel)
        dateLabel.anchor(top: detailView.topAnchor, left: detailView.leftAnchor, bottom: detailView.bottomAnchor, right: stackview.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        
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
        
        let detailDivider = UIView()
        bottomDividerView.backgroundColor = UIColor.lightGray
        
        addSubview(topDividerView)
        addSubview(detailDivider)
        addSubview(bottomDividerView)
        
        topDividerView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        detailDivider.anchor(top: threadUsersView.topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.25)
        
        bottomDividerView.anchor(top: bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}
