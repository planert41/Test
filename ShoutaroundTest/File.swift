//
//  BookmarkPhotoCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/22/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//


import UIKit
import Firebase

protocol BackupListPhotoCellDelegate {
    func didTapComment(post:Post)
    func didTapUser(post:Post)
    func didTapLocation(post:Post)
    func didTapMessage(post:Post)
    func refreshPost(post:Post)
    
    func deletePost(post:Post)
    func didTapPicture(post:Post)
}

class ListPhotoCellBackup: UICollectionViewCell {
    
    let adressLabelSize = 8 as CGFloat
    var delegate: BackupListPhotoCellDelegate?
    
    var bookmarkDate: Date?{
        didSet{
            //            let timeAgoDisplay = bookmarkDate?.timeAgoDisplay()
            if let bookmarkDate = bookmarkDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d YYYY"
                let timeAgoDisplay = formatter.string(from: bookmarkDate)
                dateLabel.text = timeAgoDisplay
            }
        }
    }
    var post: Post? {
        didSet {
            
            if post?.image == nil {
                guard let imageUrl = post?.imageUrl else {return}
                photoImageView.loadImage(urlString: imageUrl)
            } else {
                photoImageView.image = post?.image
            }
            usernameLabel.text = post?.user.username
            
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
            //            ratingEmojiLabel.text = post?.ratingEmoji
            captionLabel.text = post?.caption
            captionLabel.sizeToFit()
            
            if (post?.listCount)! > 0 {
                bookmarkCount.text = String(describing: (post?.listCount)!)
            } else {
                bookmarkCount.text = ""
            }
            
            if (post?.messageCount)! > 0 {
                messageCount.text = String(describing: (post?.messageCount)!)
            } else {
                messageCount.text = ""
            }
            
            
            guard let profileImageUrl = post?.user.profileImageUrl else {return}
            userProfileImageView.loadImage(urlString: profileImageUrl)
            
            //     setupAttributedLocationName()
            
            likeButton.setImage(post?.hasLiked == true ? #imageLiteral(resourceName: "like_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
            
            bookmarkButton.setImage(post?.hasBookmarked == true ? #imageLiteral(resourceName: "bookmark_ribbon_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "bookmark_ribbon_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)
            
            
            
            //            print("Post Distance is",post?.distance)
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
            
            distanceLabel.sizeToFit()
            
            
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
        label.font = UIFont.boldSystemFont(ofSize: 11)
        label.sizeToFit()
        return label
    }()
    
    let distanceLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 9)
        label.textColor = UIColor.mainBlue()
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    let userProfileImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)

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
        label.textAlignment = NSTextAlignment.right
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
        
        // Update Cache
        postCache.removeValue(forKey: postId)
        postCache[postId] = post
        
        
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
        
        //        photoImageView.widthAnchor.constraint(equalTo: self.frame.height, multiplier: 1).isActive = true
        
        //        photoImageView.widthAnchor.constraint(equalToConstant: self.frame.height).isActive = true
        photoImageView.widthAnchor.constraint(equalTo: photoImageView.heightAnchor, multiplier: 1).isActive = true
        
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(ListPhotoCell.handlePictureTap))
        photoImageView.addGestureRecognizer(TapGesture)
        photoImageView.isUserInteractionEnabled = true
        
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
        
        addSubview(distanceLabel)
        distanceLabel.anchor(top: nonRatingEmojiLabel.bottomAnchor, left: nonRatingEmojiLabel.leftAnchor, bottom: locationNameLabel.topAnchor, right: nonRatingEmojiLabel.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
        
        
        let detailView = UIView()
        addSubview(detailView)
        detailView.anchor(top: nil, left: photoImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 20)
        
        addSubview(captionLabel)
        captionLabel.anchor(top: locationAdressLabel.bottomAnchor, left: photoImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 2, paddingRight: 20, width: 0, height: 0)
        captionLabel.bottomAnchor.constraint(lessThanOrEqualTo: detailView.topAnchor).isActive = true
        
        // Sets maximum caption label size
        captionLabel.frame = CGRect(x: 0, y: 0, width: self.frame.width/2, height: self.frame.height)
        captionLabel.sizeToFit()
        
        
        
        //        captionLabel.backgroundColor = UIColor.yellow
        
        
        
        
        // Add Action Buttons
        
        //        addSubview(bookmarkCount)
        //        addSubview(bookmarkButton)
        //        addSubview(messageCount)
        //        addSubview(sendMessageButton)
        //
        //        bookmarkCount.anchor(top: detailView.topAnchor, left: nil, bottom: detailView.bottomAnchor, right: detailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 15, height: 0)
        //
        //        bookmarkButton.anchor(top: detailView.topAnchor, left: nil, bottom: detailView.bottomAnchor, right: bookmarkCount.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 2, width: 20, height: 0)
        //
        //        messageCount.anchor(top: detailView.topAnchor, left: nil, bottom: detailView.bottomAnchor, right: bookmarkButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 15, height: 0)
        //
        //        sendMessageButton.anchor(top: detailView.topAnchor, left: nil, bottom: detailView.bottomAnchor, right: messageCount.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 2, width: 20, height: 0)
        
        
        addSubview(sendMessageButton)
        sendMessageButton.anchor(top: detailView.topAnchor, left: nil, bottom: detailView.bottomAnchor, right: detailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 2, paddingRight: 10, width: 0, height: 0)
        sendMessageButton.widthAnchor.constraint(equalTo: sendMessageButton.heightAnchor, multiplier: 1).isActive = true
        
        addSubview(dateLabel)
        dateLabel.anchor(top: detailView.topAnchor, left: detailView.leftAnchor, bottom: detailView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 60, height: 0)
        
        addSubview(bookmarkButton)
        bookmarkButton.anchor(top: detailView.topAnchor, left: dateLabel.rightAnchor, bottom: detailView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 2, paddingRight: 5, width: 0, height: 0)
        bookmarkButton.widthAnchor.constraint(equalTo: bookmarkButton.heightAnchor, multiplier: 1).isActive = true
        
        
        //        let buttonStackView = UIStackView(arrangedSubviews: [sendMessageButton, bookmarkButton])
        //        buttonStackView.distribution = .fillEqually
        //        buttonStackView.spacing = 10
        //        addSubview(buttonStackView)
        //        buttonStackView.anchor(top: detailView.topAnchor, left: nil, bottom: detailView.bottomAnchor, right: dateLabel.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 80, height: 0)
        
        
        
        //        let buttonStackView = UIStackView(arrangedSubviews: [likeButton, commentButton, sendMessageButton, bookmarkButton])
        
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
        let usernameTap = UITapGestureRecognizer(target: self, action: #selector(ListPhotoCell.usernameTap))
        userProfileImageView.addGestureRecognizer(usernameTap)
        userProfileImageView.isUserInteractionEnabled = true
        
        
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(ListPhotoCell.locationTap))
        locationNameLabel.addGestureRecognizer(locationTapGesture)
        locationNameLabel.isUserInteractionEnabled = true
        let locationTapGesture2 = UITapGestureRecognizer(target: self, action: #selector(ListPhotoCell.locationTap))
        
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

