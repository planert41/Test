//
//  UserProfilePhotoCell.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

protocol UserProfilePhotoCellDelegate {
    func didTapPicture(post:Post)
    
}

class UserProfilePhotoCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    var delegate: UserProfilePhotoCellDelegate?
    var post: Post? {
        didSet {
            guard let imageUrl = post?.imageUrl else {return}
//            guard let url = URL(string: imageUrl) else {return}
//            photoImageView.setImageWith(url)
            photoImageView.loadImage(urlString: imageUrl)
            
            self.likeCount = post?.likeCount ?? 0
            self.bookmarkCount = post?.bookmarkCount ?? 0
            self.messageCount = post?.messageCount ?? 0
            self.ratingEmojiLabel.text = post?.ratingEmoji
            setupAttributedSocialCount()

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
    
    var likeCount: Int = 0
    var bookmarkCount: Int = 0
    var messageCount: Int = 0
    
    var photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
        
    }()
    
    var labelFontSize = 10 as CGFloat
    
    var socialCount: UILabel = {
        let label = UILabel()
        label.textAlignment = NSTextAlignment.right
        label.textColor = UIColor.lightGray
        label.backgroundColor = UIColor(white: 0, alpha: 0.4)
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
    
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(UserProfilePhotoCell.handlePictureTap))
        photoImageView.addGestureRecognizer(TapGesture)
        photoImageView.isUserInteractionEnabled = true
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(SharePhotoController.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.25
        longPress.delegate = self
        photoImageView.addGestureRecognizer(longPress)
        
        addSubview(socialCount)
        socialCount.anchor(top: nil, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 2, paddingRight: 2, width: 0, height: 15)
        socialCount.alpha = 0
        
        addSubview(ratingEmojiLabel)
        ratingEmojiLabel.anchor(top: nil, left: nil, bottom: bottomAnchor, right: socialCount.leftAnchor, paddingTop: 0, paddingLeft: 2, paddingBottom: 2, paddingRight: 0, width: 0, height: 15)
        ratingEmojiLabel.font = ratingEmojiLabel.font.withSize(labelFontSize)
        ratingEmojiLabel.alpha = 0

    }
    
    func setupAttributedSocialCount(){
        
        let imageSize = CGSize(width: labelFontSize, height: labelFontSize)
        
        // Likes
        let attributedText = NSMutableAttributedString(string: String(self.likeCount), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize), NSForegroundColorAttributeName: UIColor.lightGray])
        let likeImage = NSTextAttachment()
        likeImage.image = #imageLiteral(resourceName: "like_selected").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
        let likeImageString = NSAttributedString(attachment: likeImage)
        attributedText.append(likeImageString)
        
        // Bookmarks
        let bookmarkText = NSMutableAttributedString(string: String(self.bookmarkCount), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize), NSForegroundColorAttributeName: UIColor.lightGray])
        attributedText.append(bookmarkText)
        let bookmarkImage = NSTextAttachment()
        bookmarkImage.image = #imageLiteral(resourceName: "bookmark_ribbon_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
        let bookmarkImageString = NSAttributedString(attachment: bookmarkImage)
        attributedText.append(bookmarkImageString)
        
        // Messages
        let messageText = NSMutableAttributedString(string: String(self.messageCount), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize), NSForegroundColorAttributeName: UIColor.lightGray])
        attributedText.append(messageText)
        let messageImage = NSTextAttachment()
        messageImage.image = #imageLiteral(resourceName: "shoutaround").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
        let messageImageString = NSAttributedString(attachment: messageImage)
        attributedText.append(messageImageString)
        
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
        
    }
    
    
    
}
