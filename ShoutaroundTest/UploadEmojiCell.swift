//
//  UploadEmojiCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/13/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit


class UploadEmojiCell: UICollectionViewCell {
    
    let uploadEmojis: UILabel = {
        
        let iv = UILabel()
        iv.backgroundColor = .clear
        iv.font = iv.font.withSize(EmojiSize.width-10)
        iv.textAlignment = NSTextAlignment.center
        
        return iv
        
    }()
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        backgroundColor = .white
        addSubview(uploadEmojis)
        uploadEmojis.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        uploadEmojis.textAlignment = NSTextAlignment.center
        uploadEmojis.center = self.center


        
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.cgColor
        layer.cornerRadius = 10
        layer.masksToBounds = true
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder error")
    }
    
}
