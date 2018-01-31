//
//  UserProfilePhotoCell.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

protocol ExplorePhotoCellDelegate {
    func didTapPicture(post:Post)
    func didTapLocation(post: Post)
}

class ExplorePhotoCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    var delegate: ExplorePhotoCellDelegate?
    var post: Post? {
        didSet {
            guard let imageUrl = post?.imageUrl else {return}
            //            guard let url = URL(string: imageUrl) else {return}
            //            photoImageView.setImageWith(url)
            photoImageView.loadImage(urlString: imageUrl)
            userProfileImageView.loadImage(urlString: (post?.user.profileImageUrl)!)
            
            self.voteCount = post?.voteCount ?? 0
            self.listCount = post?.listCount ?? 0
            self.messageCount = post?.messageCount ?? 0
            
            self.ratingEmojiLabel.text = post?.ratingEmoji
            setupAttributedSocialCount()
        }
    }
    
    var selectedHeaderSort: String? = nil {
        didSet{
            setupPhotoDetails()
        }
    }
    
    var socialHide: Bool = true {
        didSet{
            if socialHide{
                self.ratingEmojiLabel.alpha = 0
                self.socialCount.alpha = 0
            } else {
                self.ratingEmojiLabel.alpha = 1
                self.socialCount.alpha = 1
            }
        }
    }
    
    var voteCount: Int = 0
    var listCount: Int = 0
    var messageCount: Int = 0
    
    var photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
        
    }()
    
    var socialCount: UILabel = {
        let label = UILabel()
        label.textAlignment = NSTextAlignment.left
        label.textColor = UIColor.lightGray
        label.backgroundColor = UIColor(white: 0, alpha: 0.4)
        label.numberOfLines = 0
        return label
    }()
    
    var ratingEmojiLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = NSTextAlignment.left
        label.textColor = UIColor.lightGray
        label.font = label.font.withSize(10)
        label.backgroundColor = UIColor.clear
        return label
    }()
    
    let labelFontSize = 12 as CGFloat
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = UIColor.black
        label.isUserInteractionEnabled = true
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    func tapLocation(){
        self.delegate?.didTapLocation(post: self.post!)
    }
    
    let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.black
        label.isUserInteractionEnabled = true
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    let metricLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.black
        label.isUserInteractionEnabled = true
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    let userProfileImageView: CustomImageView = {
        
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        return iv
        
    }()
    
    var photoDetailView = UIView()
    
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.borderWidth = 0
        

        
    // Photo Detail View - Emoji and Metrics
        
        addSubview(photoDetailView)
        photoDetailView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: photoDetailView.topAnchor, left: photoDetailView.leftAnchor, bottom: photoDetailView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 4, paddingBottom: 5, paddingRight: 2, width: 0, height: 0)
        userProfileImageView.widthAnchor.constraint(equalTo: userProfileImageView.heightAnchor, multiplier: 1).isActive = true
        userProfileImageView.layer.cornerRadius = (40-10)/2
        userProfileImageView.layer.borderWidth = 0.25
        userProfileImageView.layer.borderColor = UIColor.lightGray.cgColor
        
        addSubview(metricLabel)
        metricLabel.anchor(top: nil, left: nil, bottom: userProfileImageView.bottomAnchor, right: photoDetailView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: photoDetailView.frame.height/2)
        
        addSubview(emojiLabel)
        emojiLabel.anchor(top: nil, left: userProfileImageView.rightAnchor, bottom: userProfileImageView.bottomAnchor, right: metricLabel.leftAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: photoDetailView.frame.height/2)
        
        
        // Location Name
        addSubview(locationLabel)
        locationLabel.anchor(top: userProfileImageView.topAnchor, left: userProfileImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: photoDetailView.frame.height/2)
        locationLabel.bottomAnchor.constraint(lessThanOrEqualTo: emojiLabel.topAnchor).isActive = true
        locationLabel.bottomAnchor.constraint(lessThanOrEqualTo: metricLabel.topAnchor).isActive = true
        locationLabel.sizeToFit()
        locationLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapLocation)))



    // Photo Image
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: photoDetailView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(GridPhotoCell.handlePictureTap))
        photoImageView.addGestureRecognizer(TapGesture)
        photoImageView.isUserInteractionEnabled = true
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(SharePhotoController.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.25
        longPress.delegate = self
        photoImageView.addGestureRecognizer(longPress)

        addSubview(socialCount)
        socialCount.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        socialCount.alpha = 0
        
//        addSubview(ratingEmojiLabel)
//        ratingEmojiLabel.anchor(top: nil, left: nil, bottom: bottomAnchor, right: socialCount.leftAnchor, paddingTop: 0, paddingLeft: 2, paddingBottom: 2, paddingRight: 0, width: 0, height: 15)
//        ratingEmojiLabel.font = ratingEmojiLabel.font.withSize(labelFontSize)
//        ratingEmojiLabel.alpha = 0
    }
    
    func setupPhotoDetails(){
    // Setup Emojis
        emojiLabel.text = post?.emoji
        
        if (self.post?.isLegit)! {
            (emojiLabel.text)! += legitString
        }
        
    // Setup Location Labels
        var displayLocationName: String = ""
        guard let post = self.post else {return}

        if post.locationGooglePlaceID! == "" {
            // Detect Not Google Tagged Location
            
            let locationNameTextArray = post.locationAdress.components(separatedBy: ",")
            // Last 3 items are City, State, Country
            displayLocationName = locationNameTextArray.suffix(3).joined(separator: ",")
        } else {
            displayLocationName = post.locationName
        }
        
        self.locationLabel.text = displayLocationName
        
    // Setup Social
        var attributedText: NSMutableAttributedString = NSMutableAttributedString(string: "")
        
        let imageSize = CGSize(width: labelFontSize, height: labelFontSize)

        if selectedHeaderSort == "Votes" && self.voteCount > 0 {
            let attributedString = NSMutableAttributedString(string: "  \(String(self.voteCount)) ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize), NSForegroundColorAttributeName: UIColor.lightGray])
            let likeImage = NSTextAttachment()
            likeImage.image = #imageLiteral(resourceName: "cred_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            let likeImageString = NSAttributedString(attachment: likeImage)
            attributedText.append(attributedString)
            attributedText.append(likeImageString)
        }
        else if selectedHeaderSort == "Lists" && self.listCount > 0{
            let attributedString = NSMutableAttributedString(string: "  \(String(self.listCount)) ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize), NSForegroundColorAttributeName: UIColor.lightGray])
            let likeImage = NSTextAttachment()
            likeImage.image = #imageLiteral(resourceName: "bookmark_selected").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            let likeImageString = NSAttributedString(attachment: likeImage)
            attributedText.append(attributedString)
            attributedText.append(likeImageString)
        }
        else if selectedHeaderSort == "Messages" && self.messageCount > 0{
            let attributedString = NSMutableAttributedString(string: "  \(String(self.messageCount)) ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize), NSForegroundColorAttributeName: UIColor.lightGray])
            let likeImage = NSTextAttachment()
            likeImage.image = #imageLiteral(resourceName: "send_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            let likeImageString = NSAttributedString(attachment: likeImage)
            attributedText.append(attributedString)
            attributedText.append(likeImageString)
        }

        metricLabel.attributedText = attributedText
        metricLabel.sizeToFit()
    }
    
    func setupAttributedSocialCount(){
        
        let socialCountSize = labelFontSize + 2
        let socialCountColor = UIColor.white
        let imageSize = CGSize(width: socialCountSize, height: socialCountSize)
        
        let attributedText = NSMutableAttributedString(string: "")
        
        // Votes
        if self.voteCount > 0 {
            let attributedString = NSMutableAttributedString(string: "  \(String(self.voteCount))  ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: socialCountSize), NSForegroundColorAttributeName: socialCountColor])
            let voteImage = NSTextAttachment()
            voteImage.image = #imageLiteral(resourceName: "cred_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            let voteImageString = NSAttributedString(attachment: voteImage)
            attributedText.append(attributedString)
            attributedText.append(voteImageString)
        }
        
        // Bookmarks
        if self.listCount > 0 {
            let bookmarkText = NSMutableAttributedString(string: "  \(String(self.listCount))  ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: socialCountSize), NSForegroundColorAttributeName: socialCountColor])
            attributedText.append(bookmarkText)
            let bookmarkImage = NSTextAttachment()
            bookmarkImage.image = #imageLiteral(resourceName: "bookmark_selected").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            let bookmarkImageString = NSAttributedString(attachment: bookmarkImage)
            attributedText.append(bookmarkImageString)
        }
        
        // Messages
        if self.messageCount > 0 {
            let messageText = NSMutableAttributedString(string: "  \(String(self.messageCount))  ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: socialCountSize), NSForegroundColorAttributeName: socialCountColor])
            attributedText.append(messageText)
            let messageImage = NSTextAttachment()
            messageImage.image = #imageLiteral(resourceName: "send_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
            let messageImageString = NSAttributedString(attachment: messageImage)
            attributedText.append(messageImageString)
        }
        

        
        if let caption = self.post?.caption{
            let attributedCaptionSpace = NSMutableAttributedString(string: "\n\n", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize - 2), NSForegroundColorAttributeName: socialCountColor])
            
            let attributedCaptionString = NSMutableAttributedString(string: "\(caption)  ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize + 2), NSForegroundColorAttributeName: socialCountColor])
            
            // Legit Icon or Rating Score
            
            if (self.post?.isLegit)! {
                let legitImage = NSTextAttachment()
                legitImage.image = #imageLiteral(resourceName: "legit").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
                let legitImageString = NSAttributedString(attachment: legitImage)
                attributedCaptionString.append(legitImageString)
            }
            else if (self.post?.rating)! > 0 {
                let attributedRatingString = NSAttributedString(string: String(describing: (self.post?.rating)!), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize + 2), NSForegroundColorAttributeName: RatingColors.ratingColor(rating: post?.rating)])
                attributedCaptionString.append(attributedRatingString)
            }

            // Take out Space if there are no social Stats
            if self.voteCount == 0 && self.listCount == 0 && self.messageCount == 0 {
                let attributedText = attributedCaptionString
            } else {
                attributedText.append(attributedCaptionSpace)
                attributedText.append(attributedCaptionString)
            }
        }
        
        
        
        // Set Label
        socialCount.attributedText = attributedText
        socialCount.sizeToFit()
    }
    
    
    func handlePictureTap() {
        guard let post = post else {return}
        print("Tap Picture")
        delegate?.didTapPicture(post: post)
    }
    
    func handleLongPress(_ gestureReconizer: UILongPressGestureRecognizer) {
        
        let animationDuration = 0.25
        
        if socialHide {
            if gestureReconizer.state != UIGestureRecognizerState.recognized {
                // Fade in Social Counts when held
                UIView.animate(withDuration: animationDuration, animations: { () -> Void in
                    self.socialCount.alpha = 1
                    self.ratingEmojiLabel.alpha = 1
                }) { (Bool) -> Void in
                }
            }
            else if gestureReconizer.state != UIGestureRecognizerState.changed {
                // Fade Out Social Counts when released
                UIView.animate(withDuration: animationDuration, animations: { () -> Void in
                    self.socialCount.alpha = 0
                    self.ratingEmojiLabel.alpha = 0
                }) { (Bool) -> Void in
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        //Flickering is caused by reused cell having previous photo or loading prior image request
        photoImageView.image = nil
        photoImageView.cancelImageRequestOperation()
        post = nil
        metricLabel.attributedText = NSAttributedString(string: "")        
    }
    
    
    
}

