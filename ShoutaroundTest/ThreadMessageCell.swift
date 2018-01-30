//
//  CommentCell.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 9/3/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import Firebase

class ThreadMessageCell: UICollectionViewCell {
    
    var message: Message? {
        didSet {
            
            guard let message = message else {return}
            Database.fetchUserWithUID(uid: message.senderUID) { (user) in
                self.messageUser = user
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d YYYY"
            let dateDisplay = formatter.string(from: message.creationDate)
            dateLabel.text = dateDisplay
            //            guard let profileImageUrl = comment.user.profileImageUrl else {return}
            //            guard let username = comment.user.username else {return}
            
        }
    }
    
    var messageUser: User? {
        didSet {
            guard let profileImageUrl = messageUser?.profileImageUrl else {return}
            guard let username = messageUser?.username else {return}
            
            let attributedText = NSMutableAttributedString(string: username, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12)])
            attributedText.append(NSAttributedString(string: " " + (message?.message)!, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12)]))
            
            textView.attributedText = attributedText
            
            profileImageView.loadImage(urlString: profileImageUrl)
        }
    }
    
    let textView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.isScrollEnabled = false
        textView.backgroundColor = .white
        textView.isUserInteractionEnabled = false
        return textView
    }()
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.image = #imageLiteral(resourceName: "profile_outline").withRenderingMode(.alwaysOriginal)
        return iv
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGray
        label.font = UIFont.systemFont(ofSize: 10)
        label.textAlignment = NSTextAlignment.right
        return label
        
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        profileImageView.layer.cornerRadius = 40/2
        
        addSubview(dateLabel)
        dateLabel.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 70, height: 10)
        
        addSubview(textView)
        textView.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, right: dateLabel.leftAnchor, paddingTop: 4, paddingLeft: 4, paddingBottom: 4, paddingRight: 4, width: 0, height: 0)
        

        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
}
