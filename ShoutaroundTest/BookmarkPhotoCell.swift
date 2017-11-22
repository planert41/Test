//
//  BookmarkPhotoCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/22/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//


import UIKit
import Firebase

protocol BookmarkPhotoCellDelegate {
    func didTapComment(post:Post)
    func didTapUser(post:Post)
    func didTapLocation(post:Post)
    func didTapMessage(post:Post)
    func deletePost(post:Post)
    func refreshPost(post:Post)
    func didTapPicture(post:Post)
    
}

class BookmarkPhotoCell: UICollectionViewCell {
    
    let adressLabelSize = 12 as CGFloat
    var delegate: BookmarkPhotoCellDelegate?
    
    var bookmarkDate: Date?{
        didSet{
            let timeAgoDisplay = bookmarkDate?.timeAgoDisplay()
            dateLabel.text = timeAgoDisplay
        }
    }
    var post: Post? {
        didSet {
            
            guard let imageUrl = post?.imageUrl else {return}
            photoImageView.loadImage(urlString: imageUrl)
            usernameLabel.text = post?.user.username
            locationNameLabel.text = post?.locationName
            locationAdressLabel.text = post?.locationAdress
            nonRatingEmojiLabel.text = (post?.ratingEmoji)! + (post?.nonRatingEmoji.joined())!
//            ratingEmojiLabel.text = post?.ratingEmoji
            captionLabel.text = post?.caption
            
            
            
            guard let profileImageUrl = post?.user.profileImageUrl else {return}
            userProfileImageView.loadImage(urlString: profileImageUrl)
            
       //     setupAttributedLocationName()
            
            likeButton.setImage(post?.hasLiked == true ? #imageLiteral(resourceName: "like_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
            
            bookmarkButton.setImage(post?.hasBookmarked == true ? #imageLiteral(resourceName: "bookmark_ribbon_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "bookmark_ribbon_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)
            
            
            
            print("Post Distance is",post?.distance)
            if post?.distance != nil && post?.locationGPS?.coordinate.longitude != 0 && post?.locationGPS?.coordinate.latitude != 0 {
                
                guard let postdistance = post?.distance else {return}
                let distanceformat = ".2"
                
                if postdistance < 100000 {
                // Convert to M to KM
                let locationDistance = postdistance/1000
                distanceLabel.text =  " \(locationDistance.format(f: distanceformat)) Miles"
                }
                
                else if postdistance >= 500000 {
                    
                    // Convert to M to KM
                    let locationDistance = postdistance/100000
                    distanceLabel.text =  ">500 Miles"
                }
            } else {
                    distanceLabel.text = ""
            }
            
            
        }
    }
    
    fileprivate func setupAttributedLocationName(){
        
        guard let post = self.post else {return}
        
        let attributedText = NSMutableAttributedString(string: post.locationName.truncate(length: 20), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: adressLabelSize)])
        
        if post.distance != nil && post.locationGPS?.coordinate.longitude != 0 && post.locationGPS?.coordinate.latitude != 0 {
            
            let distanceformat = ".2"
            
            // Convert to M to KM
            let locationDistance = post.distance!/1000
            
            attributedText.append(NSAttributedString(string: " \(locationDistance.format(f: distanceformat)) KM", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: adressLabelSize),NSForegroundColorAttributeName: UIColor.mainBlue()]))
        }
        
        self.locationNameLabel.attributedText = attributedText
        
    }
    
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.sizeToFit()
        return label
    }()
    
    let distanceLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 10)
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
    
    let nonRatingEmojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 13)
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
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.sizeToFit()
        return label
    }()
    
    let dateLabel: UILabel = {
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
        
        guard let postId = self.post?.id else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let values = [postId: self.post?.hasLiked == true ? 0 : 1]
        Database.database().reference().child("likes").child(uid).updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to like post", err)
                return
            }
            print("Succesfully Saved Likes")
            self.post?.hasLiked = !(self.post?.hasLiked)!
            self.delegate?.refreshPost(post: self.post!)
        }
    
        self.likeButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.likeButton.transform = .identity
            },
                       completion: nil)
    
    }
    
    // Bookmark
    
    lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "ribbon").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
        return button
        
    }()
    
    func handleBookmark() {
        
        //delegate?.didBookmark(for: self)
        
        guard let postId = self.post?.id else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let values = ["bookmarked": self.post?.hasBookmarked == true ? 0 : 1, "creatorUID": post?.creatorUID] as [String : Any]
        
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
        guard let post = post else {return}
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

// Photo Image View
        
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        photoImageView.widthAnchor.constraint(equalTo: photoImageView.heightAnchor, multiplier: 1).isActive = true
        
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(BookmarkPhotoCell.handlePictureTap))
        photoImageView.addGestureRecognizer(TapGesture)
        photoImageView.isUserInteractionEnabled = true
        
// Setup Bookmark Stack View

        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: topAnchor, left: photoImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        userProfileImageView.layer.cornerRadius = 30/2
        userProfileImageView.clipsToBounds = true
        userProfileImageView.layer.borderWidth = 0.25
        userProfileImageView.layer.borderColor = UIColor.lightGray.cgColor
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: userProfileImageView.topAnchor, left: userProfileImageView.rightAnchor, bottom: userProfileImageView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 80, height: 0)
        usernameLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
//
//        addSubview(ratingEmojiLabel)
//        ratingEmojiLabel.anchor(top: userProfileImageView.topAnchor, left: nil, bottom: userProfileImageView.bottomAnchor, right: userProfileImageView.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 30, height: 30)
//        ratingEmojiLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        
        addSubview(nonRatingEmojiLabel)
        nonRatingEmojiLabel.anchor(top: userProfileImageView.topAnchor, left: nil, bottom: userProfileImageView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        nonRatingEmojiLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true

        
// Location Data

        addSubview(distanceLabel)
        distanceLabel.anchor(top: userProfileImageView.bottomAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 5, paddingBottom: 5, paddingRight: 10, width: 70, height: 15)
        
        addSubview(locationNameLabel)
        locationNameLabel.anchor(top: userProfileImageView.bottomAnchor, left: photoImageView.rightAnchor, bottom: nil, right: distanceLabel.leftAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 15)


        addSubview(locationAdressLabel)
        locationAdressLabel.anchor(top: locationNameLabel.bottomAnchor, left: photoImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 24)
        
        addSubview(captionLabel)
        captionLabel.anchor(top: locationAdressLabel.bottomAnchor, left: photoImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        captionLabel.sizeToFit()
        
        addSubview(dateLabel)
        dateLabel.anchor(top: nil, left: photoImageView.rightAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 5, paddingRight: 0, width: 60, height: 30)
        
        
        
//        let buttonStackView = UIStackView(arrangedSubviews: [likeButton, commentButton, sendMessageButton, bookmarkButton])
        let buttonStackView = UIStackView(arrangedSubviews: [sendMessageButton, bookmarkButton])
        
        buttonStackView.distribution = .fillEqually
        addSubview(buttonStackView)
        
        buttonStackView.anchor(top: nil, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 5, paddingRight: 10, width: 60, height: 30)
        //        buttonStackView.widthAnchor.constraint(equalTo: photoImageView.heightAnchor, multiplier: 1).isActive = true

//        
//        let stackview = UIStackView()
//        
//        stackview.axis = .vertical
//        stackview.distribution = .fillEqually
//        stackview.insertArrangedSubview(usernameRow, at: 0)
//        stackview.insertArrangedSubview(locationNameLabel, at: 1)
//        stackview.insertArrangedSubview(locationAdressLabel, at: 2)
//       // stackview.insertArrangedSubview(captionTextView, at: 3)
//        
//        addSubview(stackview)
//        stackview.anchor(top: topAnchor, left: leftAnchor, bottom: captionLabel.topAnchor, right: photoImageView.leftAnchor, paddingTop: 2, paddingLeft: 2, paddingBottom: 2, paddingRight: 2, width: 0, height: 0)

//        usernameRow.addSubview(userProfileImageView)
//        usernameRow.addSubview(usernameLabel)
//        userProfileImageView.anchor(top: usernameRow.topAnchor, left: usernameRow.leftAnchor, bottom: usernameRow.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        userProfileImageView.widthAnchor.constraint(equalTo: userProfileImageView.heightAnchor, multiplier: 1).isActive = true
//        userProfileImageView.layer.cornerRadius = 25/2
//        
//        usernameLabel.anchor(top: usernameRow.topAnchor, left: userProfileImageView.rightAnchor, bottom: usernameRow.bottomAnchor, right: distanceLabel.leftAnchor, paddingTop: 0, paddingLeft: 3, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        
        
        
        
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
        
        
        bottomDividerView.anchor(top: bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}
