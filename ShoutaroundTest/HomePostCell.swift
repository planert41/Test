//
//  HomePostCell.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import mailgun
import Firebase


protocol HomePostCellDelegate {
    func didTapComment(post:Post)
    func didTapUser(post:Post)
    func didTapLocation(post:Post)
    func didTapMessage(post:Post)
    func refreshPost(post:Post)
    func userOptionPost(post:Post)
    func displaySelectedEmoji(emoji: String, emojitag: String)
//    func didLike(for cell: HomePostCell)
//    func didBookmark(for cell: HomePostCell)

}

class HomePostCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    var delegate: HomePostCellDelegate?
    var popView = UIView()
    var enableDelete: Bool = false
    var isZooming = false


    var post: Post? {
        didSet {
                
            guard let imageUrl = post?.imageUrl else {return}

            bookmarkButton.setImage(post?.hasBookmarked == true ? #imageLiteral(resourceName: "bookmark_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "bookmark_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
            
            upVoteButton.setImage(post?.hasVoted == 1 ? #imageLiteral(resourceName: "upvote_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "upvote").withRenderingMode(.alwaysOriginal), for: .normal)
            
            downVoteButton.setImage(post?.hasVoted == -1 ? #imageLiteral(resourceName: "downvote_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "downvote").withRenderingMode(.alwaysOriginal), for: .normal)
            
            photoImageView.loadImage(urlString: imageUrl)
            
            usernameLabel.text = post?.user.username
            usernameLabel.sizeToFit()
            
            usernameLabel.isUserInteractionEnabled = true
            let usernameTap = UITapGestureRecognizer(target: self, action: #selector(HomePostCell.usernameTap))
            usernameLabel.addGestureRecognizer(usernameTap)
            
            setupEmojiLabels()
            locationLabel.text = post?.locationName.truncate(length: 30)
            adressLabel.text = post?.locationAdress.truncate(length: 60)
            
            guard let profileImageUrl = post?.user.profileImageUrl else {return}
            
            userProfileImageView.loadImage(urlString: profileImageUrl)
            captionLabel.text = post?.caption
            setupAttributedCaption()
            setupAttributedSocialCount()
            
            
            if post?.distance != nil && post?.locationGPS?.coordinate.longitude != 0 && post?.locationGPS?.coordinate.latitude != 0 {
                
                let distanceformat = ".2"
                
                // Convert to M to KM (Temp Miles just for display)
                let locationDistance = (post?.distance)!/1000
                if locationDistance < 1000 {
                    locationDistanceLabel.text = String(locationDistance.format(f: distanceformat)) + " Miles"
                } else {
                    locationDistanceLabel.text = ""

                }

            } else {
                locationDistanceLabel.text = ""
            }

            if post?.creatorUID == Auth.auth().currentUser?.uid {
                optionsButton.isHidden = false
            } else {
                optionsButton.isHidden = true
            }
            
            
           // setupAttributedLocationName()
        }
    }

    
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
    
    var bookmarkLabelConstraint: NSLayoutConstraint? = nil
    
    fileprivate func setupAttributedSocialCount(){
        
        guard let post = self.post else {return}
        
        if post.messageCount > 0 {
            self.messageCount.text = String( post.messageCount)
        } else {
            self.messageCount.text = ""
        }
//        self.messageCount.sizeToFit()
        
        if post.bookmarkCount > 0 {
            self.bookmarkCount.text = String( post.bookmarkCount)
        } else {
            self.bookmarkCount.text = ""
        }
        
        if post.voteCount != 0 {
            self.voteCount.text = String( post.voteCount)
        } else {
            self.voteCount.text = ""
        }
        
        // Resizes bookmark label to fit new count
//        self.bookmarkCount.sizeToFit()
        bookmarkLabelConstraint?.constant = self.bookmarkCount.frame.size.width
//        self.layoutIfNeeded()
        
    }
    
    fileprivate func setupAttributedCaption(){
        
        guard let post = self.post else {return}
        
        let attributedText = NSMutableAttributedString(string: post.user.username, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
        
        attributedText.append(NSAttributedString(string: " \(post.caption)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)]))
        
        attributedText.append(NSAttributedString(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 4)]))
        
        
//        let timeAgoDisplay = post.creationDate.timeAgoDisplay()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d YYYY, h:mm a"
        let timeAgoDisplay = formatter.string(from: post.creationDate)
        
        attributedText.append(NSAttributedString(string: timeAgoDisplay, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12),NSForegroundColorAttributeName: UIColor.gray]))
        
        self.captionLabel.attributedText = attributedText
        
        
    }
    
    fileprivate func setupAttributedLocationName(){
        
        guard let post = self.post else {return}
        
        let attributedText = NSMutableAttributedString(string: post.locationName.truncate(length: 20), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12)])
        
        if post.distance != nil && post.locationGPS?.coordinate.longitude != 0 && post.locationGPS?.coordinate.latitude != 0 {

            let distanceformat = ".2"
            
            // Convert to M to KM
            let locationDistance = post.distance!/1000
            
            attributedText.append(NSAttributedString(string: " \(locationDistance.format(f: distanceformat)) KM", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 10),NSForegroundColorAttributeName: UIColor.gray]))
        }
        
        self.locationLabel.attributedText = attributedText
        
    }
    
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
        iv.isUserInteractionEnabled = true
        
        return iv
        
    }()
    
    lazy var ratingEmojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.textAlignment = NSTextAlignment.right
        label.backgroundColor = UIColor.clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(ratingEmojiSelected(_:)))
        label.addGestureRecognizer(tap)
        label.isUserInteractionEnabled = true
        return label
        
    }()
    
    
    lazy var nonRatingEmojiLabel1: UILabel = {
        let label = UILabel()
        let tap = UITapGestureRecognizer(target: self, action: #selector(nonRatingEmojiSelected(_:)))
        label.addGestureRecognizer(tap)
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor.clear
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.tag = 0
        return label
    }()
    
    lazy var nonRatingEmojiLabel2: UILabel = {
        let label = UILabel()
        let tap = UITapGestureRecognizer(target: self, action: #selector(nonRatingEmojiSelected(_:)))
        label.addGestureRecognizer(tap)
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor.clear
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.tag = 1
        return label
    }()
    
    lazy var nonRatingEmojiLabel3: UILabel = {
        let label = UILabel()
        let tap = UITapGestureRecognizer(target: self, action: #selector(nonRatingEmojiSelected(_:)))
        label.addGestureRecognizer(tap)
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor.clear
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.tag = 2
        return label
    }()
    
    lazy var nonRatingEmojiLabel4: UILabel = {
        let label = UILabel()
        let tap = UITapGestureRecognizer(target: self, action: #selector(nonRatingEmojiSelected(_:)))
        label.addGestureRecognizer(tap)
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor.clear
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.tag = 3
        return label
    }()
    
    lazy var nonRatingEmojiLabel5: UILabel = {
        let label = UILabel()
        let tap = UITapGestureRecognizer(target: self, action: #selector(nonRatingEmojiSelected(_:)))
        label.addGestureRecognizer(tap)
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor.clear
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.tag = 4
        return label
    }()

    var nonRatingEmojiLabelArray:[UILabel] = []
    
    func setupEmojiLabels(){
        
        guard let post = post else {return}
        
        self.ratingEmojiLabel.text = self.post?.ratingEmoji
        
        for label in self.nonRatingEmojiLabelArray {
            label.text = ""
        }
        if self.post?.nonRatingEmoji != nil {
            for (index, emoji) in (self.post?.nonRatingEmoji.enumerated())! {
                self.nonRatingEmojiLabelArray[index].text = emoji
                self.nonRatingEmojiLabelArray[index].sizeToFit()
            }
        }
    }
    
    
    func nonRatingEmojiSelected(_ sender: UIGestureRecognizer){
        print("Non Rating Emoji Selected")
        
        guard let post = post else {return}
        guard let labelTag = sender.view?.tag else {return}
        
        var displayEmoji = self.post?.nonRatingEmoji[labelTag]
        var displayEmojiTag = self.post?.nonRatingEmojiTags[labelTag]
        
        if let emojiTagLookup = ReverseEmojiDictionary.key(forValue: displayEmojiTag!) {
            displayEmojiTag = emojiTagLookup
        }
        
        let selectedLabel = self.nonRatingEmojiLabelArray[labelTag]
        selectedLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        selectedLabel.transform = .identity
            },
                       completion: nil)
        
        self.delegate?.displaySelectedEmoji(emoji: displayEmoji!, emojitag: displayEmojiTag!)
        
//        var origin: CGPoint = selectedLabel.center;
//        var topleft = CGPoint(x: selectedLabel.center.x - selectedLabel.bounds.size.width/2, y: selectedLabel.center.y - (selectedLabel.bounds.size.height / 2) - 200 )
//        popView.backgroundColor = UIColor.blue
//        popView = UIView(frame: CGRect(x: topleft.x, y: topleft.y, width: 200, height: 200))
//        popView.frame.origin.x = topleft.x
//        popView.frame.origin.y = topleft.y
//        self.addSubview(popView)
        
    }
    
    func ratingEmojiSelected(_ sender: UIGestureRecognizer){
        print("Rating Emoji Selected")
        
        guard let post = post else {return}
        
        var displayEmoji = self.post?.ratingEmoji
        var displayEmojiTag = displayEmoji
        
        if let emojiTagLookup = ReverseEmojiDictionary.key(forValue: displayEmoji!) {
            displayEmojiTag = emojiTagLookup
        } else {
        }
        
        self.ratingEmojiLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.ratingEmojiLabel.transform = .identity
            },
                       completion: nil)
        
        self.delegate?.displaySelectedEmoji(emoji: displayEmoji!, emojitag: displayEmojiTag!)
    }
    
    
    let emojiDetailLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 204, green: 238, blue: 255)
        label.layer.cornerRadius = 30/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.lightGray.cgColor
        label.layer.masksToBounds = true
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    
    let locationView: UIView = {
        let uv = UIView()
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(locationTap))
        uv.addGestureRecognizer(locationTapGesture)
//        uv.isUserInteractionEnabled = true
        return uv
    }()
    
    let headerView: UIView = {
        let uv = UIView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(usernameTap))
        uv.addGestureRecognizer(tap)
        uv.isUserInteractionEnabled = true
        uv.backgroundColor = UIColor.clear
        return uv
    }()
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.black
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(locationTap))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(locationTapGesture)
        return label
    }()
    
    let locationDistanceLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 11)
        
        label.textColor = UIColor.mainBlue()
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    let adressLabel: UILabel = {
        let label = UILabel()
        label.text = "Adress"
        label.font = UIFont.italicSystemFont(ofSize: 10)
        label.textColor = UIColor.darkGray
        return label
    }()
    
    lazy var locationButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.clear
        button.addTarget(self, action: #selector(locationTap), for: .touchUpInside)
        return button
        
    }()
    
    let captionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()


    lazy var optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("•••", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(handleOptions), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()
    
    
    
    func handleOptions() {
        
        guard let post = post else {return}
        print("Options Button Pressed")
        delegate?.userOptionPost(post: post)

    }
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(headerView)
        addSubview(photoImageView)
        addSubview(userProfileImageView)
        addSubview(usernameLabel)
        addSubview(emojiDetailLabel)
        addSubview(ratingEmojiLabel)
        addSubview(bookmarkButton)
        
        headerView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)

// Setup Non Rating Emojis
        
        nonRatingEmojiLabelArray = [nonRatingEmojiLabel1, nonRatingEmojiLabel2, nonRatingEmojiLabel3, nonRatingEmojiLabel4, nonRatingEmojiLabel5]
        
        for (index,label) in nonRatingEmojiLabelArray.enumerated(){
            addSubview(label)
            
            if index == 0{
                label.anchor(top: headerView.topAnchor, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            } else {
                label.anchor(top: headerView.topAnchor, left: nonRatingEmojiLabelArray[index - 1].rightAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            }
        }
        
    
        emojiDetailLabel.anchor(top: topAnchor, left: nil, bottom: photoImageView.topAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 200, height: 0)
        emojiDetailLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        emojiDetailLabel.isHidden = true
        
// Username Details and Rating Emojis
        
        userProfileImageView.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 40, height: 40)
        userProfileImageView.layer.cornerRadius = 40/2
        userProfileImageView.layer.borderWidth = 0.25
        userProfileImageView.layer.borderColor = UIColor.lightGray.cgColor
        
        usernameLabel.anchor(top: topAnchor, left: nil, bottom: photoImageView.topAnchor, right: userProfileImageView.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 0, height: userProfileImageView.frame.height)
        
        usernameLabel.textAlignment = .right
        
        addSubview(locationDistanceLabel)
 
        locationDistanceLabel.anchor(top: nil, left: nil, bottom: photoImageView.topAnchor, right: userProfileImageView.leftAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 3, paddingRight: 10, width: 0, height: 0)
        
        
        ratingEmojiLabel.anchor(top: topAnchor, left: nil, bottom: photoImageView.topAnchor, right: usernameLabel.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 2, width: 0, height: 0)
        
// Photo Image View and Complex User Interactions
        
        photoImageView.anchor(top: headerView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(photoDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        photoImageView.addGestureRecognizer(doubleTap)
        photoImageView.isUserInteractionEnabled = true
        
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(locationTap))
        photoImageView.addGestureRecognizer(locationTapGesture)
        locationTapGesture.require(toFail: doubleTap)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
        pinch.delegate = self
        self.photoImageView.addGestureRecognizer(pinch)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.pan(sender:)))
        pan.delegate = self
        self.photoImageView.addGestureRecognizer(pan)
        
        
// Location View
        
        addSubview(locationView)
        locationView.anchor(top: photoImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
//        addSubview(optionsButton)
//        optionsButton.anchor(top: locationView.topAnchor, left: nil, bottom: photoImageView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 44, height: 0)

        addSubview(locationLabel)
        addSubview(adressLabel)
        addSubview(locationDistanceLabel)
        
        addSubview(optionsButton)
        optionsButton.anchor(top: locationView.topAnchor, left: nil, bottom: locationView.bottomAnchor, right: locationView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        optionsButton.centerYAnchor.constraint(equalTo: locationView.centerYAnchor).isActive = true
        optionsButton.isHidden = true
        
        locationLabel.anchor(top: locationView.topAnchor, left: leftAnchor, bottom: nil, right: optionsButton.leftAnchor, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 15)
        
        adressLabel.anchor(top: locationLabel.bottomAnchor, left: leftAnchor, bottom: locationView.bottomAnchor, right: optionsButton.leftAnchor, paddingTop: 2, paddingLeft: 15, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        
//        addSubview(locationButton)
//        locationButton.anchor(top: locationView.topAnchor, left: locationView.leftAnchor, bottom: locationView.bottomAnchor, right: locationView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        

        
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor.lightGray
        addSubview(bottomDividerView)
        
        bottomDividerView.anchor(top: locationView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        setupActionButtons()

        addSubview(captionLabel)
        captionLabel.anchor(top: actionBar.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 2, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        captionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
    
    }
    
    // Action Buttons
    
    var actionBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
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
        self.setupAttributedSocialCount()
        self.delegate?.refreshPost(post: self.post!)
        
    }
    
    // Bookmark
    
    lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "bookmark_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
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
            self.post?.bookmarkCount -= 1
        } else {
            self.post?.bookmarkCount += 1
        }
        self.post?.hasBookmarked = !(self.post?.hasBookmarked)!
        self.setupAttributedSocialCount()
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

    
    let bookmarkCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:12)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    let messageCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:12)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    let commentCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:12)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    // Upvote Downvote
    
    lazy var upVoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "upvote").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleUpVote), for: .touchUpInside)
        return button
        
    }()
    
    lazy var downVoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "downvote").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleDownVote), for: .touchUpInside)
        return button
        
    }()
    
    let voteCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:11)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    func handleUpVote(){
        guard let postId = self.post?.id else {return}
        guard let creatorId = self.post?.creatorUID else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        self.upVoteButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        self.layoutIfNeeded()
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.upVoteButton.transform = .identity
                        self?.upVoteButton.layoutIfNeeded()
                        
            },
                       completion: nil)
        
        Database.handleVote(postId: postId, creatorUid: creatorId, vote: 1) { 
            
        }

        
        // Animates before database function is complete
        
        if (self.post?.hasVoted)! == 1 {
            // Unselect Upvote
            self.post?.hasVoted = 0
            self.post?.voteCount -= 1
        } else if (self.post?.hasVoted)! == 0 {
            // Upvote
            self.post?.hasVoted = 1
            self.post?.voteCount += 1
        } else if (self.post?.hasVoted)! == -1 {
            // Upvote
            self.post?.hasVoted = 1
            self.post?.voteCount += 2
        }
        
        self.setupAttributedSocialCount()
        self.delegate?.refreshPost(post: self.post!)
    }
    
    func handleDownVote(){
        guard let postId = self.post?.id else {return}
        guard let creatorId = self.post?.creatorUID else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        self.downVoteButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        self.layoutIfNeeded()
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.downVoteButton.transform = .identity
                        self?.downVoteButton.layoutIfNeeded()
                        
            },
                       completion: nil)
        
        Database.handleVote(postId: postId, creatorUid: creatorId, vote: -1) {
            
        }
        
        
        // Animates before database function is complete
        
        if (self.post?.hasVoted)! == 1 {
            // Downvote
            self.post?.hasVoted = -1
            self.post?.voteCount += -2
        } else if (self.post?.hasVoted)! == 0 {
            // Downvote
            self.post?.hasVoted = -1
            self.post?.voteCount += -1
        } else if (self.post?.hasVoted)! == -1 {
            // Unselect Downvote
            self.post?.hasVoted = 0
            self.post?.voteCount += 1
        }
        
        self.setupAttributedSocialCount()
        self.delegate?.refreshPost(post: self.post!)
    }
    
    
    fileprivate func setupActionButtons() {

        addSubview(actionBar)
        actionBar.anchor(top: locationView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        let voteView = UIView()
//        voteView.backgroundColor = UIColor.blue
        
        let commentView = UIView()
//        commentView.backgroundColor = UIColor.yellow
        
        let bookmarkView = UIView()
//        bookmarkView.backgroundColor = UIColor.blue
        
        let messageView = UIView()
//        messageView.backgroundColor = UIColor.yellow
        
        let voteContainer = UIView()
        let commentContainer = UIView()
        let bookmarkContainer = UIView()
        let messageContainer = UIView()
        
        
        let actionStackView = UIStackView(arrangedSubviews: [voteView, commentView, bookmarkView, messageView])
        actionStackView.distribution = .fillEqually
        addSubview(actionStackView)
        
        actionStackView.anchor(top: locationView.bottomAnchor, left: leftAnchor, bottom: actionBar.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        addSubview(upVoteButton)
        addSubview(downVoteButton)
        addSubview(voteCount)
        
        upVoteButton.anchor(top: voteView.topAnchor, left: voteView.leftAnchor, bottom: voteView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        upVoteButton.widthAnchor.constraint(equalTo: upVoteButton.heightAnchor, multiplier: 1).isActive = true
        
        downVoteButton.anchor(top: voteView.topAnchor, left: nil, bottom: voteView.bottomAnchor, right: voteView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        downVoteButton.widthAnchor.constraint(equalTo: downVoteButton.heightAnchor, multiplier: 1).isActive = true
        
        voteCount.anchor(top: voteView.topAnchor, left: upVoteButton.rightAnchor, bottom: voteView.bottomAnchor, right: downVoteButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        voteCount.sizeToFit()
        
    // Comments
        
        commentContainer.addSubview(commentButton)
        commentContainer.addSubview(commentCount)
        
        commentButton.anchor(top: commentContainer.topAnchor, left: commentContainer.leftAnchor, bottom: commentContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        commentButton.widthAnchor.constraint(equalTo: commentButton.heightAnchor, multiplier: 1).isActive = true

        commentCount.anchor(top: commentContainer.topAnchor, left: commentButton.rightAnchor, bottom: commentContainer.bottomAnchor, right: commentContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        commentCount.centerYAnchor.constraint(equalTo: commentButton.centerYAnchor).isActive = true
        commentCount.sizeToFit()
        
        addSubview(commentContainer)
        commentContainer.anchor(top: commentView.topAnchor, left: nil, bottom: commentView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        commentContainer.centerXAnchor.constraint(equalTo: commentView.centerXAnchor).isActive = true
        
    // Bookmarks
        
        bookmarkContainer.addSubview(bookmarkButton)
        bookmarkContainer.addSubview(bookmarkCount)
        
        bookmarkButton.anchor(top: bookmarkContainer.topAnchor, left: bookmarkContainer.leftAnchor, bottom: bookmarkContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        bookmarkButton.widthAnchor.constraint(equalTo: bookmarkButton.heightAnchor, multiplier: 1).isActive = true
        
        bookmarkCount.anchor(top: bookmarkContainer.topAnchor, left: bookmarkButton.rightAnchor, bottom: bookmarkContainer.bottomAnchor, right: bookmarkContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        bookmarkCount.centerYAnchor.constraint(equalTo: bookmarkButton.centerYAnchor).isActive = true
        
        bookmarkCount.sizeToFit()
        
        addSubview(bookmarkContainer)
        bookmarkContainer.anchor(top: bookmarkView.topAnchor, left: nil, bottom: bookmarkView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        bookmarkContainer.centerXAnchor.constraint(equalTo: bookmarkView.centerXAnchor).isActive = true

        
    // Message
        
        messageContainer.addSubview(sendMessageButton)
        messageContainer.addSubview(messageCount)
        
        sendMessageButton.anchor(top: messageContainer.topAnchor, left: messageContainer.leftAnchor, bottom: messageContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        sendMessageButton.widthAnchor.constraint(equalTo: sendMessageButton.heightAnchor, multiplier: 1).isActive = true
        
        messageCount.anchor(top: messageContainer.topAnchor, left: sendMessageButton.rightAnchor, bottom: messageContainer.bottomAnchor, right: messageContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        messageCount.centerYAnchor.constraint(equalTo: sendMessageButton.centerYAnchor).isActive = true
        
        messageCount.text = "10"
        messageCount.sizeToFit()
        
        addSubview(messageContainer)
        messageContainer.anchor(top: messageView.topAnchor, left: nil, bottom: messageView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        messageContainer.centerXAnchor.constraint(equalTo: messageView.centerXAnchor).isActive = true
        
    // Dividers
        
        let div1 = UIView()
        div1.backgroundColor = .black
        addSubview(div1)
        div1.anchor(top: actionStackView.topAnchor, left: commentView.leftAnchor, bottom: actionStackView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 1, height: 0)
        div1.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true

        let div2 = UIView()
        div2.backgroundColor = .black
        addSubview(div2)
        div2.anchor(top: actionStackView.topAnchor, left: bookmarkView.leftAnchor, bottom: actionStackView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 1, height: 0)
        div2.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true
        

        let div3 = UIView()
        div3.backgroundColor = .black
        addSubview(div3)
        div3.anchor(top: actionStackView.topAnchor, left: messageView.leftAnchor, bottom: actionStackView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 1, height: 0)
        div3.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true
        
        
        
//        for i in 1 ..< (actionStackView.arrangedSubviews.count - 1){
//            let div = UIView()
//            div.widthAnchor.constraint(equalToConstant: 1).isActive = true
//            div.backgroundColor = .black
//            addSubview(div)
//            div.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true
//            div.centerXAnchor.constraint(equalTo: actionStackView.arrangedSubviews[i].leftAnchor).isActive = true
//            div.centerYAnchor.constraint(equalTo: actionStackView.centerYAnchor).isActive = true
//        }

        
        
    }
    
    fileprivate func setupActionButtonsTest() {
        
//        let stackView = UIStackView(arrangedSubviews: [likeButton, commentButton, sendMessageButton])
//        stackView.distribution = .fillEqually
//        addSubview(stackView)
//        stackView.anchor(top: locationView.bottomAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 120, height: 40)
        
        
        addSubview(actionBar)
        actionBar.anchor(top: locationView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
//        addSubview(likeButton)
//        likeButton.anchor(top: actionBar.topAnchor, left: actionBar.leftAnchor, bottom: actionBar.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 8, paddingBottom: 5, paddingRight: 0, width: 30, height: 30)
        
        addSubview(commentButton)
        commentButton.anchor(top: actionBar.topAnchor, left: actionBar.leftAnchor, bottom: actionBar.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 2, paddingBottom: 5, paddingRight: 0, width: 30, height: 30)
        
        addSubview(sendMessageButton)
        sendMessageButton.anchor(top: actionBar.topAnchor, left: commentButton.rightAnchor, bottom: actionBar.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 2, paddingBottom: 5, paddingRight: 0, width: 30, height: 30)
        
        addSubview(messageCount)
        messageCount.anchor(top: actionBar.topAnchor, left: sendMessageButton.rightAnchor, bottom: actionBar.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 2, paddingBottom: 5, paddingRight: 0, width: 30, height: 30)
        
        
        
        addSubview(upVoteButton)
        addSubview(downVoteButton)
        addSubview(voteCount)
        
        downVoteButton.anchor(top: actionBar.topAnchor, left: nil, bottom: actionBar.bottomAnchor, right: actionBar.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 30, height: 0)
        downVoteButton.widthAnchor.constraint(equalTo: downVoteButton.heightAnchor, multiplier: 1)
        
        voteCount.anchor(top: actionBar.topAnchor, left: nil, bottom: actionBar.bottomAnchor, right: downVoteButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        voteCount.sizeToFit()
        
        upVoteButton.anchor(top: actionBar.topAnchor, left: nil, bottom: actionBar.bottomAnchor, right: voteCount.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        upVoteButton.widthAnchor.constraint(equalTo: upVoteButton.heightAnchor, multiplier: 1)
        
        
//        addSubview(bookmarkCount)
//        bookmarkCount.anchor(top: actionBar.topAnchor, left: nil, bottom: actionBar.bottomAnchor, right: upVoteButton.leftAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 8, width: 0, height: 30)
//        bookmarkCount.sizeToFit()
//        bookmarkLabelConstraint = NSLayoutConstraint(item: self.bookmarkCount, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: self.bookmarkCount.frame.size.width)
//        self.bookmarkCount.addConstraint(bookmarkLabelConstraint!)
//        bookmarkLabel.widthAnchor.constraint(equalToConstant: self.bookmarkLabel.frame.size.width).isActive = true
        
        // Width anchor is set after bookmark counts are displayed to figure out label width
        addSubview(bookmarkButton)
        bookmarkButton.anchor(top: actionBar.topAnchor, left: nil, bottom: actionBar.bottomAnchor, right: upVoteButton.leftAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 2, width: 30, height: 30)

//        addSubview(testlabel)
//        testlabel.anchor(top: bookmarkButton.topAnchor, left: bookmarkButton.leftAnchor, bottom: bookmarkButton.bottomAnchor, right: bookmarkButton.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        
        
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    var originalImageCenter:CGPoint?
    
    func pan(sender: UIPanGestureRecognizer) {
        if self.isZooming && sender.state == .began {
            self.originalImageCenter = sender.view?.center
        } else if self.isZooming && sender.state == .changed {
            let translation = sender.translation(in: self)
            if let view = sender.view {
                view.center = CGPoint(x:view.center.x + translation.x,
                                      y:view.center.y + translation.y)
            }
            sender.setTranslation(CGPoint.zero, in: self.photoImageView.superview)
        }
    }
    
    func pinch(sender:UIPinchGestureRecognizer) {
        if sender.state == .began {
            let currentScale = self.photoImageView.frame.size.width / self.photoImageView.bounds.size.width
            let newScale = currentScale*sender.scale
            if newScale > 1 {
                self.isZooming = true
            }
        } else if sender.state == .changed {
            guard let view = sender.view else {return}
            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
                                      y: sender.location(in: view).y - view.bounds.midY)
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: sender.scale, y: sender.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            let currentScale = self.photoImageView.frame.size.width / self.photoImageView.bounds.size.width
            var newScale = currentScale*sender.scale
            if newScale < 1 {
                newScale = 1
                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
                self.photoImageView.transform = transform
                sender.scale = 1
            }else {
                view.transform = transform
                sender.scale = 1
            }
        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
            guard let center = self.originalImageCenter else {return}
            UIView.animate(withDuration: 0.3, animations: {
                self.photoImageView.transform = CGAffineTransform.identity
                self.photoImageView.center = center
                self.superview?.bringSubview(toFront: self.photoImageView)
            }, completion: { _ in
                self.isZooming = false
            })
        }
    }
    
    func photoDoubleTapped(){
        self.handleLike()
        print("Double Tap")

        var origin: CGPoint = self.photoImageView.center;
        popView = UIView(frame: CGRect(x: origin.x, y: origin.y, width: 200, height: 200))
        popView = UIImageView(image: #imageLiteral(resourceName: "heart"))
        popView.contentMode = .scaleToFill
        popView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
        popView.frame.origin.x = origin.x
        popView.frame.origin.y = origin.y * (1/3)
        
        photoImageView.addSubview(popView)
        
            UIView.animate(withDuration: 1.5,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.popView.transform = .identity
                }) { (done) in
                    self.popView.alpha = 0
                }

    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
        photoImageView.cancelImageRequestOperation()
    }
    
    
}
