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
            
            photoImageView.loadImage(urlString: imageUrl)

        }
    }
    
    
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
        
    }()
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(UserProfilePhotoCell.handlePictureTap))
        photoImageView.addGestureRecognizer(TapGesture)
        photoImageView.isUserInteractionEnabled = true

    }
    
    
    func handlePictureTap() {
        guard let post = post else {return}
        print("Tap Picture")
        delegate?.didTapPicture(post: post)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}
