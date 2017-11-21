//
//  EmojiCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/17/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

class EmojiCell: UITableViewCell {
    
    var emoji: Emoji? {
        didSet{
            emojiLabel.text = emoji?.emoji
            emojiTextLabel.text = emoji?.name
        }
    }
    
    let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = NSTextAlignment.right
        label.backgroundColor = UIColor.white
        return label
        
    }()
    
    let emojiTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.textAlignment = NSTextAlignment.left
        label.font = UIFont.boldSystemFont(ofSize: 20)
        return label
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        addSubview(emojiLabel)
        addSubview(emojiTextLabel)
        
        emojiLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 50, height: 40)
        emojiTextLabel.anchor(top: topAnchor, left: emojiLabel.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

    }
    
    
}
