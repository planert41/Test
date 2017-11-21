//
//  UserCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 11/15/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class UserCell: UITableViewCell {
    
    var user: User?{
        didSet {
            usernameLabel.text = user?.username
            guard let profileImageUrl = user?.profileImageUrl else {return}
            profileImageView.loadImage(urlString: profileImageUrl)
            setupFollowButton()
        }
    }
    
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .red
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    lazy var followButton: UIButton = {
        let button = UIButton()
        button.setTitle("Follow", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.backgroundColor = UIColor.mainBlue()
        button.addTarget(self, action: #selector(handleFollow), for: .touchUpInside)
        return button
        
    }()
    
    func setupFollowButton(){
        
        if user?.uid == Auth.auth().currentUser?.uid {
            self.followButton.isHidden = true
        }
        
        if (user?.isFollowing)!{
            self.followButton.setTitle("Unfollow", for: .normal)
            self.followButton.backgroundColor = UIColor.orange
        } else {
            self.followButton.setTitle("Follow", for: .normal)
            self.followButton.backgroundColor = UIColor.mainBlue()
            
        }
    }
    
    func handleFollow(){
        
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else {return}
        guard let userId = user?.uid else {return}
        
        if currentLoggedInUserId == userId {return}
        if followButton.titleLabel?.text == "Unfollow" {
            
            Database.database().reference().child("following").child(currentLoggedInUserId).child(userId).removeValue(completionBlock: { (err, ref) in
                if let err = err {
                    print("Failed to unfollow user:", err)
                    return
                }
                print("Successfully unfollowed user", self.user?.username ?? "")
                self.user?.isFollowing = !(self.user?.isFollowing)!
                self.setupFollowButton()
                
            })
            
        }   else {
            
            let ref = Database.database().reference().child("following").child(currentLoggedInUserId)
            
            let values = [userId: 1]
            
            ref.updateChildValues(values) { (err, ref) in
                if let err = err {
                    
                    print("Failed to Follow User", err)
                    return
                }
                print("Successfully followed user: ", self.user?.username ?? "")
                
                self.user?.isFollowing = !(self.user?.isFollowing)!
                self.setupFollowButton()
            }
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 50/2
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        addSubview(separatorView)
        separatorView.anchor(top: nil, left: usernameLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        addSubview(followButton)
        followButton.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 15, paddingLeft: 0, paddingBottom: 15, paddingRight: 5, width: 100, height: 0)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
}
