//
//  UploadLocationCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/5/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

class UploadLocationCell: UICollectionViewCell {
    
    let uploadLocations: UILabel = {
        
        let iv = UILabel()
        iv.backgroundColor = .clear
        iv.font = UIFont.systemFont(ofSize: 15)
        
        return iv
        
    }()
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        backgroundColor = .white
        addSubview(uploadLocations)
        uploadLocations.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)

        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        layer.cornerRadius = 5
        layer.masksToBounds = true
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder error")
    }
    
}
