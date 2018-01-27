//
//  BookmarkPhotoCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/22/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//


import UIKit
import Firebase

protocol ListPhotoCellDelegate {
    func didTapComment(post:Post)
    func didTapUser(post:Post)
    func didTapLocation(post:Post)
    func didTapMessage(post:Post)
    func refreshPost(post:Post)
    
    func deletePost(post:Post)
    func didTapPicture(post:Post)
    func didTapExtraTag(tagName: String, tagId: String, post: Post)

}

class ListPhotoCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    let adressLabelSize = 8 as CGFloat
    var delegate: ListPhotoCellDelegate?
    
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
        
        // Post Image
            if post?.image == nil {
                guard let imageUrl = post?.imageUrl else {return}
                photoImageView.loadImage(urlString: imageUrl)
            } else {
                photoImageView.image = post?.image
            }
        
        // User Profile Image View
            guard let profileImageUrl = post?.user.profileImageUrl else {return}
            userProfileImageView.loadImage(urlString: profileImageUrl)
            
        // Emojis
            nonRatingEmojiLabel.text = (post?.nonRatingEmoji.joined())!
            nonRatingEmojiLabel.sizeToFit()
            
        // Location Name
            if let locationNameDisplay = post?.locationName {
                // If no location  name and showing GPS, show the adress instead
                if locationNameDisplay.hasPrefix("GPS"){
                    locationNameLabel.text = post?.locationAdress
                } else {
                    locationNameLabel.text = locationNameDisplay
                }
            }
            locationNameLabel.sizeToFit()
            
        // Star Rating

            if (post?.rating)! > 0 {
                starRatingLabel.isHidden = false
                starRatingLabel.rating = (post?.rating)!
            } else{
                starRatingLabel.isHidden = true
            }
            // Always keep star rating label there even if hidden to keep white space
//            starRatingLabel.sizeToFit()
            
        // Caption
            captionLabel.text = post?.caption
            captionLabel.sizeToFit()
            
        // Distance
            if post?.distance != nil && post?.locationGPS?.coordinate.longitude != 0 && post?.locationGPS?.coordinate.latitude != 0 {
                
                guard let postdistance = post?.distance else {return}
                let distanceInKM = postdistance/1000
                let locationDistance = Measurement.init(value: distanceInKM, unit: UnitLength.kilometers)

                if distanceInKM < 100 {
                    distanceLabel.text =  CurrentUser.distanceFormatter.string(from: locationDistance)
                }  else if distanceInKM < 300 {
                    distanceLabel.text =  "🚗"+CurrentUser.distanceFormatter.string(from: locationDistance)
                }  else if distanceInKM >= 300 {
                    distanceLabel.text =  "✈️"+CurrentUser.distanceFormatter.string(from: locationDistance)
                }
            } else {
                distanceLabel.text = ""
            }
            distanceLabel.adjustsFontSizeToFitWidth = true
            distanceLabel.sizeToFit()
            
//            setupExtraTags()
            setupAttributedSocialCount()
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
        label.font = UIFont.boldSystemFont(ofSize: 9)
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
        label.textAlignment = NSTextAlignment.left
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
    
    // Social Counts
    let detailView = UIView()
    var socialCounts = UIStackView()
    let socialCountFontSize: CGFloat = 10
    
    let voteView = UIView()
    var voteCount: UILabel = {
        let label = UILabel()
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    let listView = UIView()
    let listCount: UILabel = {
        let label = UILabel()
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    let messageView = UIView()
    let messageCount: UILabel = {
        let label = UILabel()
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    var starRatingLabel = RatingLabel(ratingScore: 0, frame: CGRect.zero)
    
// Setup Extra Tags
    
    let extraTagView: UIView = {
        let uv = UIView()
        uv.backgroundColor = UIColor.clear
        return uv
    }()
    
    let extraTagFontSize: CGFloat = 10
    let extraTagViewHeightSize: CGFloat = 20
    var extraTagViewHeight:NSLayoutConstraint?
    
    var extraTagsNameArray: [String] = []
    var extraTagsIdArray: [String] = []
    
    var extraTagsArray:[UIButton] = []
    lazy var extraTagLabel1 = UIButton()
    lazy var extraTagLabel2 = UIButton()
    lazy var extraTagLabel3 = UIButton()
    lazy var extraTagLabel4 = UIButton()
    
    func extraTagselected(_ sender: UIButton){
        guard let post = post else {return}
        let listTag = sender.tag

        var selectedListName = self.extraTagsNameArray[listTag]
        var selectedListId = self.extraTagsIdArray[listTag]

        print("Selected Creator Tag: \(selectedListName), \(selectedListId)")
        delegate?.didTapExtraTag(tagName: selectedListName, tagId: selectedListId, post: post)
    }
    
    func setupExtraTags(){
     
        // Refresh Tags - Only Creator Tags
        extraTagsNameArray.removeAll()
        extraTagsIdArray.removeAll()

        // Reset Extra Tags
        extraTagsArray = [extraTagLabel1, extraTagLabel2, extraTagLabel3, extraTagLabel4]
        
        for label in self.extraTagsArray {
            label.setTitle(nil, for: .normal)
            label.setImage(nil, for: .normal)
            label.layer.borderWidth = 0
            label.removeFromSuperview()
        }
        
        // Creator Created Tags
        if post?.creatorListId != nil {
            var listCount = post?.creatorListId?.count
            
            // Add Legit List
            for list in (post?.creatorListId)! {
                if list.value == legitListName {
                    extraTagsNameArray.append(list.value)
                    extraTagsIdArray.append(list.key)
                }
            }
            
            // Add Other List
            for list in (post?.creatorListId)! {
                if list.value != legitListName && list.value != bookmarkListName {
                    if extraTagsNameArray.count < 2 {
                        extraTagsNameArray.append(list.value)
                        extraTagsIdArray.append(list.key)
                    } else if extraTagsNameArray.count == 2 && listCount! == 3 {
                        extraTagsNameArray.append(list.value)
                        extraTagsIdArray.append(list.key)
                    } else if extraTagsNameArray.count == 2 && listCount! > 3 {
                        extraTagsNameArray.append("\(listCount! - 2)")
                        extraTagsIdArray.append("creatorLists")
                    }
                }
            }
        }
        
        // Creator Price Tag
        if post?.price != nil {
            extraTagsNameArray.append((post?.price)!)
            extraTagsIdArray.append("price")
        }
        
        // Extra Tag Button Label
        if extraTagsNameArray.count > 0 {
            for (index, listName) in (self.extraTagsNameArray.enumerated()) {
                
                extraTagsArray[index].tag = index
                extraTagsArray[index].setTitle(extraTagsNameArray[index], for: .normal)
                extraTagsArray[index].titleLabel?.font = UIFont.boldSystemFont(ofSize: extraTagFontSize)
                extraTagsArray[index].titleLabel?.textAlignment = NSTextAlignment.center
                extraTagsArray[index].layer.borderWidth = 1
                extraTagsArray[index].layer.backgroundColor = UIColor.white.cgColor
                extraTagsArray[index].layer.borderColor = UIColor.white.cgColor
                extraTagsArray[index].layer.cornerRadius = 5
                extraTagsArray[index].layer.masksToBounds = true
                extraTagsArray[index].contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
                extraTagsArray[index].addTarget(self, action: #selector(extraTagselected(_:)), for: .touchUpInside)
                
                
                if extraTagsNameArray[index] == bookmarkListName {
                    extraTagsArray[index].setImage(#imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal), for: .normal)
                    extraTagsArray[index].setTitle(nil, for: .normal)
                    extraTagsArray[index].setTitleColor(UIColor.white, for: .normal)
                    extraTagsArray[index].layer.backgroundColor = UIColor.white.cgColor
                }
                    
                else if extraTagsNameArray[index] == legitListName {
                    extraTagsArray[index].setTitleColor(UIColor.white, for: .normal)
                    extraTagsArray[index].setImage(#imageLiteral(resourceName: "legit").withRenderingMode(.alwaysOriginal), for: .normal)
                    extraTagsArray[index].layer.backgroundColor = UIColor.legitColor().cgColor.copy(alpha: 0.5)
                }
                    
                else if extraTagsIdArray[index] == "price" {
                    extraTagsArray[index].setTitleColor(UIColor.white, for: .normal)
                    extraTagsArray[index].layer.backgroundColor = UIColor.legitColor().cgColor
                }
                    
                else {
                        // Creator Tags
                        extraTagsArray[index].setTitle(extraTagsNameArray[index].truncate(length: 10) + "!", for: .normal)
                        extraTagsArray[index].setTitleColor(UIColor.white, for: .normal)
                        extraTagsArray[index].layer.backgroundColor = UIColor.legitColor().cgColor
                }
                
                extraTagsArray[index].layer.borderWidth = 1
                
                // Add Tags to View
                let displayButton = extraTagsArray[index]
                self.addSubview(displayButton)
                
                if index == 0{
                    displayButton.anchor(top: extraTagView.topAnchor, left: extraTagView.leftAnchor, bottom: extraTagView.bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 10, paddingBottom: 1, paddingRight: 0, width: 0, height: 0)
                } else {
                    displayButton.anchor(top: extraTagView.topAnchor, left: extraTagsArray[index - 1].rightAnchor, bottom: extraTagView.bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 6, paddingBottom: 1, paddingRight: 0, width: 0, height: 0)
                }
            }
        }
        
        if extraTagsNameArray.count == 0 {
            extraTagViewHeight?.constant = 0
        } else {
            extraTagViewHeight?.constant = extraTagViewHeightSize
        }
        
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
        
    // Add User Profile Image
        let userProfileImageHeight: CGFloat = 25
        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: userProfileImageHeight, height: userProfileImageHeight)
        userProfileImageView.layer.cornerRadius = userProfileImageHeight/2
        userProfileImageView.clipsToBounds = true
        userProfileImageView.layer.borderWidth = 0.25
        userProfileImageView.layer.borderColor = UIColor.lightGray.cgColor
        
        
    // Add Star Rating
        
        starRatingLabel = RatingLabel.init(ratingScore: 0, frame: CGRect(x: 0, y: 0, width: userProfileImageHeight * 0.7, height: userProfileImageHeight * 0.7))
        addSubview(starRatingLabel)
        starRatingLabel.anchor(top: nil, left: nil, bottom: nil, right: userProfileImageView.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 3, width: starRatingLabel.frame.width, height: starRatingLabel.frame.height)
        starRatingLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        

        
        // Tagged Emoji Data
        
        addSubview(nonRatingEmojiLabel)
        nonRatingEmojiLabel.anchor(top: nil, left: photoImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        nonRatingEmojiLabel.rightAnchor.constraint(lessThanOrEqualTo: starRatingLabel.leftAnchor).isActive = true
        nonRatingEmojiLabel.centerYAnchor.constraint(equalTo: userProfileImageView.centerYAnchor).isActive = true
        nonRatingEmojiLabel.heightAnchor.constraint(lessThanOrEqualTo: userProfileImageView.heightAnchor, multiplier: 0.8).isActive = true
        nonRatingEmojiLabel.sizeToFit()
        
        // Location Data
        
        addSubview(locationNameLabel)
        locationNameLabel.anchor(top: nonRatingEmojiLabel.bottomAnchor, left: photoImageView.rightAnchor, bottom: nil, right: starRatingLabel.leftAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        locationNameLabel.rightAnchor.constraint(lessThanOrEqualTo: starRatingLabel.leftAnchor).isActive = true
        locationNameLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 20).isActive = true
        locationNameLabel.sizeToFit()
        
        
        // Location Distance
        addSubview(distanceLabel)
        distanceLabel.anchor(top: userProfileImageView.bottomAnchor, left: starRatingLabel.leftAnchor, bottom: nil, right: userProfileImageView.rightAnchor, paddingTop: 3, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        distanceLabel.sizeToFit()

        
        addSubview(detailView)
        detailView.anchor(top: nil, left: photoImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 20)
        setupSocialAndDateViews()
        
//        addSubview(extraTagView)
//        extraTagView.anchor(top: nil, left: photoImageView.rightAnchor, bottom: detailView.topAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        extraTagViewHeight = NSLayoutConstraint(item: extraTagView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1, constant: extraTagViewHeightSize)
//        extraTagViewHeight?.isActive = true
//
        addSubview(captionLabel)
        captionLabel.anchor(top: locationNameLabel.bottomAnchor, left: photoImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 2, paddingRight: 20, width: 0, height: 0)
        captionLabel.bottomAnchor.constraint(lessThanOrEqualTo: detailView.topAnchor).isActive = true
        
        // Sets maximum caption label size
//        captionLabel.frame = CGRect(x: 0, y: 0, width: self.frame.width/2, height: self.frame.height)
        captionLabel.sizeToFit()

        
        // Adding Gesture Recognizers
        
        userProfileImageView.isUserInteractionEnabled = true
        let usernameTap = UITapGestureRecognizer(target: self, action: #selector(ListPhotoCell.usernameTap))
        userProfileImageView.addGestureRecognizer(usernameTap)
        userProfileImageView.isUserInteractionEnabled = true
        
        
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(ListPhotoCell.locationTap))
        locationNameLabel.addGestureRecognizer(locationTapGesture)
        locationNameLabel.isUserInteractionEnabled = true
        let locationTapGesture2 = UITapGestureRecognizer(target: self, action: #selector(ListPhotoCell.locationTap))
        
//        locationAdressLabel.addGestureRecognizer(locationTapGesture2)
//        locationAdressLabel.isUserInteractionEnabled = true
        
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
    
    func setupSocialAndDateViews(){
        
        addSubview(dateLabel)
        dateLabel.textAlignment = NSTextAlignment.right
        dateLabel.anchor(top: detailView.topAnchor, left: nil, bottom: detailView.bottomAnchor, right: detailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        dateLabel.sizeToFit()
        
        
        
        let socialCounts = UIStackView(arrangedSubviews: [voteView, listView, messageView])
        socialCounts.distribution = .fillEqually
        addSubview(socialCounts)
        socialCounts.anchor(top: detailView.topAnchor, left: detailView.leftAnchor, bottom: detailView.bottomAnchor, right: dateLabel.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(voteCount)
        voteCount.anchor(top: voteView.topAnchor, left: voteView.leftAnchor, bottom: voteView.bottomAnchor, right: voteView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(listCount)
        listCount.anchor(top: listView.topAnchor, left: listView.leftAnchor, bottom: listView.bottomAnchor, right: listView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(messageCount)
        messageCount.anchor(top: messageView.topAnchor, left: messageView.leftAnchor, bottom: messageView.bottomAnchor, right: messageView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    func setupAttributedSocialCount(){

        guard let post = post else {return}
        let imageSize = CGSize(width: socialCountFontSize, height: socialCountFontSize)
        var attributedText: NSMutableAttributedString

        // Votes
        var voteCountString: String = ""
        if (post.voteCount) > 0 {
            voteCountString = String(describing: post.voteCount)
        }
        attributedText = NSMutableAttributedString(string: voteCountString, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: socialCountFontSize), NSForegroundColorAttributeName: UIColor.lightGray])
        let voteImage = NSTextAttachment()
        voteImage.image = #imageLiteral(resourceName: "cred_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
        let voteImageString = NSAttributedString(attachment: voteImage)
        attributedText.append(voteImageString)
        voteCount.attributedText = attributedText
//        voteCount.backgroundColor = UIColor.blue
        
        // Bookmarks
        var listCountString: String = ""
        if (post.listCount) > 0 {
            listCountString = String(describing: post.listCount)
        }
        attributedText = NSMutableAttributedString(string: listCountString, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: socialCountFontSize), NSForegroundColorAttributeName: UIColor.lightGray])
        let listImage = NSTextAttachment()
        listImage.image = #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
        let listImageString = NSAttributedString(attachment: listImage)
        attributedText.append(listImageString)
        listCount.attributedText = attributedText
//        listCount.backgroundColor = UIColor.green

        
        // Messages
        var messageCountString: String = ""
        if (post.messageCount) > 0 {
            messageCountString = String(describing: post.messageCount)
        }
        attributedText = NSMutableAttributedString(string: messageCountString, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: socialCountFontSize), NSForegroundColorAttributeName: UIColor.lightGray])
        let messageImage = NSTextAttachment()
        messageImage.image = ((post.hasMessaged) ? #imageLiteral(resourceName: "send_filled") : #imageLiteral(resourceName: "send2")).withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
        let messageImageString = NSAttributedString(attachment: messageImage)
        attributedText.append(messageImageString)
        messageCount.attributedText = attributedText
//        messageCount.backgroundColor = UIColor.blue

        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}


