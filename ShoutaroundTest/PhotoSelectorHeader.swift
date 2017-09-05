//
//  PhotoSelectorHeader.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/27/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

class PhotoSelectorHeader: UICollectionViewCell {
    
    let photoImageView: UIImageView = {
        
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .cyan
        return iv
        
    }()
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        backgroundColor = .brown
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder error")
    }
    
    
    
}
