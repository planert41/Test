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

class UserProfilePhotoCell: UICollectionViewCell {
    
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
    
    var socialCount: UILabel = {
        let label = UILabel()
        label.textAlignment = NSTextAlignment.left
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
        
//        addSubview(socialCount)
//        socialCount.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 2, paddingLeft: 2, paddingBottom: 0, paddingRight: 0, width: 0, height: 15)
//        
//        setupAttributedSocialCount()

    }
    
    func setupAttributedSocialCount(){
        
        let labelFontSize = 10 as CGFloat
        let imageSize = CGSize(width: labelFontSize, height: labelFontSize)
        
        // Likes
        let attributedText = NSMutableAttributedString(string: String(self.likeCount), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize)])
        let likeImage = NSTextAttachment()
        likeImage.image = #imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal)
        let likeImageString = NSAttributedString(attachment: likeImage)
        attributedText.append(likeImageString)
        
        // Bookmarks
        let bookmarkText = NSMutableAttributedString(string: String(self.bookmarkCount), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize)])
        attributedText.append(bookmarkText)
        let bookmarkImage = NSTextAttachment()
        bookmarkImage.image = #imageLiteral(resourceName: "bookmark_ribbon_unfilled").withRenderingMode(.alwaysOriginal)
        let bookmarkImageString = NSAttributedString(attachment: bookmarkImage)
        attributedText.append(bookmarkImageString)
        
        // Messages
        let messageText = NSMutableAttributedString(string: String(self.messageCount), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize)])
        attributedText.append(messageText)
        let messageImage = NSTextAttachment()
        messageImage.image = #imageLiteral(resourceName: "message").withRenderingMode(.alwaysOriginal)
        let messageImageString = NSAttributedString(attachment: bookmarkImage)
        attributedText.append(messageImageString)
        
        // Set Label
        socialCount.attributedText = attributedText
    }
    
    
    func handlePictureTap() {
        guard let post = post else {return}
        print("Tap Picture")
        delegate?.didTapPicture(post: post)
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
