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
    func deletePost(post:Post)
    
//    func didSendMessage(post:Post)
//    func didLike(for cell: HomePostCell)
//    func didBookmark(for cell: HomePostCell)

}

class HomePostCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    var delegate: HomePostCellDelegate?
    var popView = UIView()
    var enableDelete: Bool = false
    var isZooming = false


    var post: Post? {
        didSet {
                
            guard let imageUrl = post?.imageUrl else {return}
            
            likeButton.setImage(post?.hasLiked == true ? #imageLiteral(resourceName: "like_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
            
            bookmarkButton.setImage(post?.hasBookmarked == true ? #imageLiteral(resourceName: "bookmark_ribbon_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "bookmark_ribbon_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)
                
            photoImageView.loadImage(urlString: imageUrl)
            usernameLabel.text = post?.user.username


            
            usernameLabel.isUserInteractionEnabled = true
            let usernameTap = UITapGestureRecognizer(target: self, action: #selector(HomePostCell.usernameTap))
            usernameLabel.addGestureRecognizer(usernameTap)
            
            let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(HomePostCell.locationTap))
            let locationTapGesture2 = UITapGestureRecognizer(target: self, action: #selector(HomePostCell.locationTap))

            
            locationLabel.text = post?.locationName.truncate(length: 30)
            locationLabel.isUserInteractionEnabled = true
            locationLabel.addGestureRecognizer(locationTapGesture)
            
            adressLabel.text = post?.locationAdress.truncate(length: 60)
            adressLabel.isUserInteractionEnabled = true
            adressLabel.addGestureRecognizer(locationTapGesture2)
            
            emojiLabel.text = post?.emoji
            emojiLabel.isUserInteractionEnabled = true
            let emojiTap = UITapGestureRecognizer(target: self, action: #selector(HomePostCell.emojiTap))
            usernameLabel.addGestureRecognizer(usernameTap)
            emojiLabel.addGestureRecognizer(emojiTap)

            
            
            guard let profileImageUrl = post?.user.profileImageUrl else {return}
            
            userProfileImageView.loadImage(urlString: profileImageUrl)
            captionLabel.text = post?.caption
            setupAttributedCaption()
            
            
            if post?.distance != nil && post?.locationGPS?.coordinate.longitude != 0 && post?.locationGPS?.coordinate.latitude != 0 {
                
                let distanceformat = ".2"
                
                // Convert to M to KM
                let locationDistance = (post?.distance)!/1000
                if locationDistance < 1000 {
                    locationDistanceLabel.text = String(locationDistance.format(f: distanceformat)) + "KM"
                } else {
                    locationDistanceLabel.text = ""

                }

            } else {
                locationDistanceLabel.text = ""
            }

            if post?.creatorUID == Auth.auth().currentUser?.uid && enableDelete {
                deleteButton.isHidden = false
            } else {
                deleteButton.isHidden = true
            }
            
           // setupAttributedLocationName()
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
    
    func emojiTap(){
     
        print("Tap Emoji")
        
        if self.emojiDetailLabel.isHidden == false {
            self.emojiDetailLabel.isHidden = true
        }

        guard let emojiString = emojiLabel.text else {return}
        let emojiSplit = Array(emojiString.characters)
        print(emojiSplit)
        var emojiDetails: String = ""
        
        for emoji in emojiSplit {
            if let emojiTranslate = EmojiDictionary[String(emoji)]{
            emojiDetails = emojiDetails + " " + String(emoji) + emojiTranslate
            }
       }
        
        self.emojiDetailLabel.text = emojiDetails
        self.emojiDetailLabel.isHidden = false
        let when = DispatchTime.now() + 5 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            if self.emojiDetailLabel.isHidden == false {
            self.emojiDetailLabel.isHidden = true
            }
        }
        
    }
    
    
    fileprivate func setupAttributedCaption(){
        
        guard let post = self.post else {return}
        
        
        let attributedText = NSMutableAttributedString(string: post.user.username, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
        
        attributedText.append(NSAttributedString(string: " \(post.caption)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)]))
        
        attributedText.append(NSAttributedString(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 4)]))
        
        
        let timeAgoDisplay = post.creationDate.timeAgoDisplay()
        attributedText.append(NSAttributedString(string: timeAgoDisplay, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12),NSForegroundColorAttributeName: UIColor.gray]))
        
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
        label.backgroundColor = UIColor.clear
        return label
        
    }()
    
    let emojiDetailLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.rgb(red: 204, green: 238, blue: 255)
        label.layer.cornerRadius = 30/2
        label.layer.borderWidth = 0.25
        label.layer.borderColor = UIColor.lightGray.cgColor
        label.layer.masksToBounds = true
        return label
        
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    
    let locationView: UIView = {
        let uv = UIView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(locationTap))
        uv.addGestureRecognizer(tap)
        uv.isUserInteractionEnabled = true
        return uv
    }()
    
    let headerView: UIView = {
        let uv = UIView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(usernameTap))
        uv.addGestureRecognizer(tap)
        uv.isUserInteractionEnabled = true
        uv.backgroundColor = UIColor.clear
        return uv
    }()
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.black
        return label
    }()
    
    let locationDistanceLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.mainBlue()
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    let adressLabel: UILabel = {
        let label = UILabel()
        label.text = "Adress"
        label.font = UIFont.italicSystemFont(ofSize: 10)
        label.textColor = UIColor.darkGray
        return label
    }()
    
    lazy var locationButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.clear
        button.addTarget(self, action: #selector(locationTap), for: .touchUpInside)
        return button
        
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
        let bookmarkTime = Date().timeIntervalSince1970
        
        let values = ["bookmarked": self.post?.hasBookmarked == true ? 0 : 1, "creatorUID": post?.creatorUID, "bookmarkDate": bookmarkTime] as [String : Any]
        
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
        button.setImage(#imageLiteral(resourceName: "message").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleMessage), for: .touchUpInside)
        return button
    
    }()

    func handleMessage(){
        guard let post = post else {return}
        delegate?.didTapMessage(post: post)
        
    }
    
// Delete Post
    
    lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "Trash").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(deletePost), for: .touchUpInside)
        return button
        
    }()
    
    func deletePost(){
        
        guard let post = post else {return}
        delegate?.deletePost(post: post)

        
//        guard let post = post else {return}
//        delegate?.didTapMessage(post: post)
        
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
        
        addSubview(headerView)
        addSubview(photoImageView)
        addSubview(userProfileImageView)
        addSubview(usernameLabel)
        addSubview(emojiLabel)
        addSubview(emojiDetailLabel)


//        
//        addSubview(optionsButton)
//        optionsButton.anchor(top: topAnchor, left: nil, bottom: photoImageView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 44, height: 0)
        
        
        
        headerView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        emojiLabel.anchor(top: topAnchor, left: leftAnchor, bottom: photoImageView.topAnchor, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 140, height: 0)
        
        emojiLabel.textAlignment = .left
        
        let emojiTapGesture = UITapGestureRecognizer(target: self, action: #selector(HomePostCell.emojiTap))
        emojiLabel.isUserInteractionEnabled = true
        emojiLabel.addGestureRecognizer(emojiTapGesture)
        
        emojiDetailLabel.anchor(top: topAnchor, left: nil, bottom: photoImageView.topAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 200, height: 0)
        emojiDetailLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        emojiDetailLabel.isHidden = true

//        locationLabel.anchor(top: usernameLabel.bottomAnchor, left: userProfileImageView.rightAnchor, bottom: photoImageView.topAnchor, right: emojiLabel.leftAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        
        userProfileImageView.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 40, height: 40)
        userProfileImageView.layer.cornerRadius = 40/2
        userProfileImageView.layer.borderWidth = 0.25
        userProfileImageView.layer.borderColor = UIColor.lightGray.cgColor
        
        
        usernameLabel.anchor(top: topAnchor, left: nil, bottom: photoImageView.topAnchor, right: userProfileImageView.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 0, height: userProfileImageView.frame.height)
        
        usernameLabel.textAlignment = .right
        
        photoImageView.anchor(top: headerView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
 
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(photoDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        photoImageView.addGestureRecognizer(doubleTap)
        photoImageView.isUserInteractionEnabled = true
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
        pinch.delegate = self
        self.photoImageView.addGestureRecognizer(pinch)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.pan(sender:)))
        pan.delegate = self
        self.photoImageView.addGestureRecognizer(pan)
        
        addSubview(locationView)
        locationView.anchor(top: photoImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
//        locationView.backgroundColor = UIColor.yellow
        
//        addSubview(locationButton)
        addSubview(locationLabel)
        addSubview(adressLabel)
        addSubview(locationDistanceLabel)
        addSubview(bookmarkButton)
        bookmarkButton.anchor(top: locationView.bottomAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        
        locationDistanceLabel.anchor(top: photoImageView.bottomAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 75, height: 50)
        
//        locationButton.anchor(top: locationView.topAnchor, left: locationView.leftAnchor, bottom: locationView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 8, paddingBottom: 5, paddingRight: 0, width: 30, height: 30)
        
        locationLabel.anchor(top: locationView.topAnchor, left: leftAnchor, bottom: nil, right: bookmarkButton.leftAnchor, paddingTop: 5, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 15)
        
        adressLabel.anchor(top: locationLabel.bottomAnchor, left: leftAnchor, bottom: locationView.bottomAnchor, right: bookmarkButton.leftAnchor, paddingTop: 2, paddingLeft: 15, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        
        addSubview(locationButton)
        locationButton.anchor(top: locationView.topAnchor, left: locationView.leftAnchor, bottom: locationView.bottomAnchor, right: locationView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor.lightGray
        addSubview(bottomDividerView)
        
        bottomDividerView.anchor(top: locationView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        setupActionButtons()
        
        addSubview(captionLabel)
        captionLabel.anchor(top: likeButton.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
//        captionLabel.backgroundColor = UIColor.blue
    
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    var originalImageCenter:CGPoint?
    
    func pan(sender: UIPanGestureRecognizer) {
        if self.isZooming && sender.state == .began {
            self.originalImageCenter = sender.view?.center
        } else if self.isZooming && sender.state == .changed {
            let translation = sender.translation(in: self)
            if let view = sender.view {
                view.center = CGPoint(x:view.center.x + translation.x,
                                      y:view.center.y + translation.y)
            }
            sender.setTranslation(CGPoint.zero, in: self.photoImageView.superview)
        }
    }
    
    func pinch(sender:UIPinchGestureRecognizer) {
        if sender.state == .began {
            let currentScale = self.photoImageView.frame.size.width / self.photoImageView.bounds.size.width
            let newScale = currentScale*sender.scale
            if newScale > 1 {
                self.isZooming = true
            }
        } else if sender.state == .changed {
            guard let view = sender.view else {return}
            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
                                      y: sender.location(in: view).y - view.bounds.midY)
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: sender.scale, y: sender.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            let currentScale = self.photoImageView.frame.size.width / self.photoImageView.bounds.size.width
            var newScale = currentScale*sender.scale
            if newScale < 1 {
                newScale = 1
                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
                self.photoImageView.transform = transform
                sender.scale = 1
            }else {
                view.transform = transform
                sender.scale = 1
            }
        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
            guard let center = self.originalImageCenter else {return}
            UIView.animate(withDuration: 0.3, animations: {
                self.photoImageView.transform = CGAffineTransform.identity
                self.photoImageView.center = center
                self.superview?.bringSubview(toFront: self.photoImageView)
            }, completion: { _ in
                self.isZooming = false
            })
        }
    }
    
    func photoDoubleTapped(){
        self.handleLike()
        print("Double Tap")

        var origin: CGPoint = self.photoImageView.center;
        popView.backgroundColor = UIColor.blue
        popView = UIView(frame: CGRect(x: origin.x, y: origin.y, width: 200, height: 200))
        popView = UIImageView(image: #imageLiteral(resourceName: "heart"))
        popView.contentMode = .scaleToFill
        popView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
        popView.frame.origin.x = origin.x
        popView.frame.origin.y = origin.y * (1/3)
        
        photoImageView.addSubview(popView)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.popView.alpha = 1
            self.popView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }) { (done) in
            self.popView.alpha = 0
        }

    }
    
    fileprivate func setupActionButtons() {
        
        let stackView = UIStackView(arrangedSubviews: [likeButton, commentButton, sendMessageButton])
        
//        if post?.creatorUID == Auth.auth().currentUser?.uid {
//            deleteButton.isHidden = false
//        } else {
//            deleteButton.isHidden = true
//        }
        stackView.distribution = .fillEqually
        
        addSubview(stackView)
        stackView.anchor(top: locationView.bottomAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 120, height: 40)
        addSubview(deleteButton)
        deleteButton.anchor(top: locationView.bottomAnchor, left: stackView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        deleteButton.isHidden = false

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}
