//
//  HomePostCell.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import mailgun
import Firebase


protocol HomePostCellDelegate {
    func didTapComment(post:Post)
    func didTapUser(post:Post)
    func didTapLocation(post:Post)
    func didTapMessage(post:Post)
    func refreshPost(post:Post)
    
//    func didSendMessage(post:Post)
//    func didLike(for cell: HomePostCell)
//    func didBookmark(for cell: HomePostCell)

}

class HomePostCell: UICollectionViewCell {
    
    var delegate: HomePostCellDelegate?
    
    var post: Post? {
        didSet {
                
            guard let imageUrl = post?.imageUrl else {return}
            
            likeButton.setImage(post?.hasLiked == true ? #imageLiteral(resourceName: "like_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
            
            bookmarkButton.setImage(post?.hasBookmarked == true ? #imageLiteral(resourceName: "bookmark_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "bookmark_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
                
            photoImageView.loadImage(urlString: imageUrl)
            usernameLabel.text = post?.user.username

            emojiLabel.text = post?.emoji
            
            usernameLabel.isUserInteractionEnabled = true
            let usernameTap = UITapGestureRecognizer(target: self, action: #selector(HomePostCell.usernameTap))
            usernameLabel.addGestureRecognizer(usernameTap)
            
            locationLabel.isUserInteractionEnabled = true
            let locationTap = UITapGestureRecognizer(target: self, action: #selector(HomePostCell.locationTap))
            locationLabel.addGestureRecognizer(locationTap)
            
            guard let profileImageUrl = post?.user.profileImageUrl else {return}
            
            userProfileImageView.loadImage(urlString: profileImageUrl)
            captionLabel.text = post?.caption
            setupAttributedCaption()

            
            setupAttributedLocationName()
            
            
                
        }
    }

    
    func usernameTap() {
        print("Tap username label", post?.user.username ?? "")
        guard let post = post else {return}
        delegate?.didTapUser(post: post)
    }
    
    func locationTap() {
        print("Tap location label", post?.locationName ?? "")
        guard let post = post else {return}
        delegate?.didTapLocation(post: post)
    }
    
    
    fileprivate func setupAttributedCaption(){
        
        guard let post = self.post else {return}
        
        
        let attributedText = NSMutableAttributedString(string: post.user.username, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
        
        attributedText.append(NSAttributedString(string: " \(post.caption)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)]))
        
        attributedText.append(NSAttributedString(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 4)]))
        
        
        let timeAgoDisplay = post.creationDate.timeAgoDisplay()
        attributedText.append(NSAttributedString(string: timeAgoDisplay, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14),NSForegroundColorAttributeName: UIColor.gray]))
        
        self.captionLabel.attributedText = attributedText
        
        
    }
    
    fileprivate func setupAttributedLocationName(){
        
        guard let post = self.post else {return}
        
        let attributedText = NSMutableAttributedString(string: post.locationName.truncate(length: 20), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12)])
        
        if post.distance != nil && post.locationGPS?.coordinate.longitude != 0 && post.locationGPS?.coordinate.latitude != 0 {

            let distanceformat = ".2"
            
            // Convert to M to KM
            let locationDistance = post.distance!/1000
            
            attributedText.append(NSAttributedString(string: " \(locationDistance.format(f: distanceformat)) KM", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 10),NSForegroundColorAttributeName: UIColor.gray]))
        }
        
        self.locationLabel.attributedText = attributedText
        
    }
    
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
        label.textAlignment = NSTextAlignment.right
        label.backgroundColor = UIColor.white
        return label
        
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.darkGray
        return label
    }()

    
    let captionLabel: UILabel = {
        let label = UILabel()
        
        label.numberOfLines = 0
        return label
    }()
    
    
    let optionsButton: UIButton = {
        let button = UIButton(type: .system)
         button.setTitle("•••", for: .normal)
//        button.setTitle("😀👌🇰🇷🍖🐷🍺", for: .normal)
//        button.contentHorizontalAlignment = .right;
//        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
//       // button.titleLabel?.backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        
        
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    
    lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        return button
        
    }()
    
    func handleLike() {
  //      delegate?.didLike(for: self)
        
        guard let postId = self.post?.id else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let values = [postId: self.post?.hasLiked == true ? 0 : 1]
        
        
        Database.database().reference().child("likes").child(uid).updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to like post", err)
                return
            }
            print("Succesfully Saved Likes")
            self.post?.hasLiked = !(self.post?.hasLiked)!
            self.delegate?.refreshPost(post: self.post!)
        }
    }

    // Bookmark
    
    lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "ribbon").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
        return button
        
    }()
    
    func handleBookmark() {
        
    //    delegate?.didBookmark(for: self)
        
        guard let postId = self.post?.id else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let values = ["bookmarked": self.post?.hasBookmarked == true ? 0 : 1, "creatorUID": post?.creatorUID] as [String : Any]
        
        Database.database().reference().child("bookmarks").child(uid).child(postId).updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to bookmark post", err)
                return
            }
            print("Succesfully Saved Bookmark")
            self.post?.hasBookmarked = !(self.post?.hasBookmarked)!
            self.delegate?.refreshPost(post: self.post!)
            
        }
        
    }

    
// Comments
    
    lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "comment").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        return button
        
    }()
    
    func handleComment() {
        guard let post = post else {return}
        delegate?.didTapComment(post: post)
    }

// Send Message
    
    lazy var sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "send2").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleMessage), for: .touchUpInside)
        return button
    
    }()

    func handleMessage(){
        guard let post = post else {return}
        delegate?.didTapMessage(post: post)
        
    }
    
    
    
//    func handleMessage(){
//        guard let post = self.post else {return}
//        
//        print("emailtest")
//        let mailgun = Mailgun.client(withDomain: "sandbox036bf1de5ba44e7e8ad4f19b9cc5b7d8.mailgun.org", apiKey: "key-2562988360d4f7f8a1fcc6f3647b446a")
//        
//        let message = MGMessage(from:"Excited User <someone@sample.org>",
//                                to:"Jay Baird <planert41@gmail.com>",
//                                subject:"Mailgun is awesome!",
//                                body:("<html>Inline image here: <img src=cid:image01.jpg></html>"))!
//        
//        
//        
//        let postImage = CustomImageView()
//        postImage.loadImage(urlString: post.imageUrl)
//        
//        //        message.add(postImage.image, withName: "image01", type: .JPEGFileType, inline: true)
//        message.html = "<html>Inline image here: <img src="+post.imageUrl+" width = \"25%\" height = \"25%\"/></html>"
//        
//        
//        // someImage: UIImage
//        // type can be either .JPEGFileType or .PNGFileType
//        // message.add(postImage.image, withName: "image01", type:.PNGFileType)
//        
//        
//        mailgun?.send(message, success: { (success) in
//            print("success sending email")
//        }, failure: { (error) in
//            print(error)
//        })
//    }
    

    

    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(photoImageView)
        addSubview(userProfileImageView)
        addSubview(usernameLabel)
        addSubview(locationLabel)
//
        addSubview(emojiLabel)


//        
//        addSubview(optionsButton)
//        optionsButton.anchor(top: topAnchor, left: nil, bottom: photoImageView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 44, height: 0)
        
        emojiLabel.anchor(top: topAnchor, left: nil, bottom: photoImageView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 140, height: 0)
        
        usernameLabel.anchor(top: topAnchor, left: userProfileImageView.rightAnchor, bottom: nil, right: emojiLabel.leftAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: userProfileImageView.frame.height/2)

        locationLabel.anchor(top: usernameLabel.bottomAnchor, left: userProfileImageView.rightAnchor, bottom: photoImageView.topAnchor, right: emojiLabel.leftAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
        userProfileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        userProfileImageView.layer.cornerRadius = 40/2
        
        photoImageView.anchor(top: userProfileImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        

        
        setupActionButtons()
        
        addSubview(captionLabel)
        captionLabel.anchor(top: likeButton.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
    
    }
    
    fileprivate func setupActionButtons() {
        
        let stackView = UIStackView(arrangedSubviews: [likeButton, commentButton, sendMessageButton])
        stackView.distribution = .fillEqually
        
        addSubview(stackView)
        stackView.anchor(top: photoImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 120, height: 50)
        
        addSubview(bookmarkButton)
        bookmarkButton.anchor(top: photoImageView.bottomAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 50)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}
