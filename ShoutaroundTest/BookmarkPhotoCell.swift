//
//  BookmarkPhotoCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/22/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//


import UIKit

class BookmarkPhotoCell: UICollectionViewCell {
    
    let adressLabelSize = 12 as CGFloat
    
    var post: Post? {
        didSet {
            
            guard let imageUrl = post?.imageUrl else {return}
            photoImageView.loadImage(urlString: imageUrl)
            usernameLabel.text = post?.user.username
            locationNameLabel.text = post?.locationName
            locationAdressLabel.text = post?.locationAdress
            emojiLabel.text = post?.emoji
            
            guard let profileImageUrl = post?.user.profileImageUrl else {return}
            userProfileImageView.loadImage(urlString: profileImageUrl)
            captionLabel.text = post?.caption
            
            setupAttributedLocationName()
            
        }
    }
    
    fileprivate func setupAttributedLocationName(){
        
        guard let post = self.post else {return}
        
        let attributedText = NSMutableAttributedString(string: post.locationName.truncate(length: 20), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: adressLabelSize)])
        
        if post.distance != nil && post.locationGPS?.coordinate.longitude != 0 && post.locationGPS?.coordinate.latitude != 0 {
            
            let distanceformat = ".2"
            
            // Convert to M to KM
            let locationDistance = post.distance!/1000
            
            attributedText.append(NSAttributedString(string: " \(locationDistance.format(f: distanceformat)) KM", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: adressLabelSize),NSForegroundColorAttributeName: UIColor.gray]))
        }
        
        self.locationNameLabel.attributedText = attributedText
        
    }
    
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 14)
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
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = NSTextAlignment.left
        label.backgroundColor = UIColor.white
        return label
        
    }()
    
    let locationNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.darkGray
        return label
    }()
    
    let locationAdressLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.darkGray
        return label
    }()
    
    let captionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        return label
    }()
    
    
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageView.widthAnchor.constraint(equalTo: photoImageView.heightAnchor, multiplier: 1).isActive = true

        let usernameRow = UIView()

        let stackview = UIStackView()
        stackview.axis = .vertical
        stackview.distribution = .fillEqually
        stackview.insertArrangedSubview(usernameRow, at: 0)
        stackview.insertArrangedSubview(locationNameLabel, at: 1)
        stackview.insertArrangedSubview(locationAdressLabel, at: 2)
        stackview.insertArrangedSubview(captionLabel, at: 3)
        
        addSubview(stackview)
        stackview.anchor(top: topAnchor, left: photoImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 2, paddingLeft: 2, paddingBottom: 2, paddingRight: 2, width: 0, height: 0)
        
        usernameRow.addSubview(userProfileImageView)
        usernameRow.addSubview(emojiLabel)
        
        userProfileImageView.anchor(top: usernameRow.topAnchor, left: usernameRow.leftAnchor, bottom: usernameRow.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        userProfileImageView.widthAnchor.constraint(equalTo: userProfileImageView.heightAnchor, multiplier: 1).isActive = true
        
        emojiLabel.anchor(top: usernameRow.topAnchor, left: userProfileImageView.rightAnchor, bottom: usernameRow.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
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
