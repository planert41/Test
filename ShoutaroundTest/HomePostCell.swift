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
    func didTapBookmark(post: Post)
    func didTapComment(post:Post)
    func didTapUser(post:Post)
    func didTapLocation(post:Post)
    func didTapMessage(post:Post)
    func didTapExtraTag(tagName: String, tagId: String, post: Post)
    func refreshPost(post:Post)
    func userOptionPost(post:Post)
    func displaySelectedEmoji(emoji: String, emojitag: String)
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
            
            bookmarkButton.setImage(post?.hasBookmarked == true ? #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "bookmark_unfilled").withRenderingMode(.alwaysOriginal), for: .normal)
            
            upVoteButton.setImage(post?.hasVoted == 1 ? #imageLiteral(resourceName: "upvote_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "upvote").withRenderingMode(.alwaysOriginal), for: .normal)
            
            downVoteButton.setImage(post?.hasVoted == -1 ? #imageLiteral(resourceName: "downvote_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "downvote").withRenderingMode(.alwaysOriginal), for: .normal)
            
            photoImageView.loadImage(urlString: imageUrl)
            
            usernameLabel.text = post?.user.username
            usernameLabel.sizeToFit()
            
            usernameLabel.isUserInteractionEnabled = true
            let usernameTap = UITapGestureRecognizer(target: self, action: #selector(HomePostCell.usernameTap))
            usernameLabel.addGestureRecognizer(usernameTap)
            
//            self.starRatingLabel.rating = (post?.rating)!
//            if (post?.rating)! == 0 {
//                starRatingLabelWidth?.constant = 0
//            } else {
////                starRatingLabelWidth?.constant = 25
//
//                starRatingLabelWidth?.constant = 0
//            }
//            self.starRatingLabel.layoutIfNeeded()
            
            setupEmojiLabels()

            
            guard let profileImageUrl = post?.user.profileImageUrl else {return}
            
            userProfileImageView.loadImage(urlString: profileImageUrl)
            starRatingLabel.layoutIfNeeded()
            setupExtraTags()
            captionLabel.text = post?.caption
            setupAttributedLocationName()
            setupAttributedCaption()
            setupAttributedSocialCount()
            
//            locationLabel.text = post?.locationName.truncate(length: 30)
//            adressLabel.text = post?.locationAdress.truncate(length: 60)
            
            captionBubble.text = post?.caption
            captionBubble.sizeToFit()
            
            
            if post?.distance != nil && post?.locationGPS?.coordinate.longitude != 0 && post?.locationGPS?.coordinate.latitude != 0 {
                
                let distanceformat = ".2"
                
                // Convert to M to KM (Temp Miles just for display)
                let locationDistance = (post?.distance)!/1000
                if locationDistance < 1000 {
                    locationDistanceLabel.text = String(locationDistance.format(f: distanceformat)) + " Miles"
                } else {
                    locationDistanceLabel.text = ""

                }

            } else {
                locationDistanceLabel.text = ""
            }

            if post?.creatorUID == Auth.auth().currentUser?.uid {
                optionsButton.isHidden = false
            } else {
                optionsButton.isHidden = true
            }
            
            // Check for Creator Legit List
            
            checkPostForLegit()
            
           // setupAttributedLocationName()
        }
    }
    
    func checkPostForLegit(){
        
        guard let creatorListId = post?.creatorListId else {
            self.legitIcon.isHidden = true
            return
        }
        
        self.legitIcon.isHidden = true

        for (key,value) in creatorListId {
            // Only show if there is a legit list
            if value == legitListName{
                self.legitIcon.isHidden = false
            }
        }
    }

    
    func usernameTap() {
        print("Tap username label", post?.user.username ?? "")
        guard let post = post else {return}
        delegate?.didTapUser(post: post)
    }
    
    func locationTap() {
        print("Post Information: ", post)
        
        print("Tap location label", post?.locationName ?? "")
        guard let post = post else {return}
        delegate?.didTapLocation(post: post)
    }
    
    var bookmarkLabelConstraint: NSLayoutConstraint? = nil
    
    fileprivate func setupAttributedSocialCount(){
        
        guard let post = self.post else {return}
        
        if post.messageCount > 0 {
            self.messageCount.text = String( post.messageCount)
        } else {
            self.messageCount.text = ""
        }
//        self.messageCount.sizeToFit()
        
        if post.bookmarkCount > 0 {
            self.bookmarkCount.text = String( post.bookmarkCount)
        } else {
            self.bookmarkCount.text = ""
        }
        
        if post.voteCount != 0 {
            self.voteCount.text = String( post.voteCount)
        } else {
            self.voteCount.text = ""
        }
        
        // Resizes bookmark label to fit new count
//        self.bookmarkCount.sizeToFit()
        bookmarkLabelConstraint?.constant = self.bookmarkCount.frame.size.width
//        self.layoutIfNeeded()
        
    }
    
    
    
    fileprivate func setupAttributedCaption(){
        
        guard let post = self.post else {return}
        
//        let attributedText = NSMutableAttributedString(string: post.user.username, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
//
//        attributedText.append(NSAttributedString(string: " \(post.caption)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)]))
//
//        attributedText.append(NSAttributedString(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 4)]))
        
        
//        let timeAgoDisplay = post.creationDate.timeAgoDisplay()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d YYYY, h:mm a"
        let timeAgoDisplay = formatter.string(from: post.creationDate)
        
//        attributedText.append(NSAttributedString(string: timeAgoDisplay, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12),NSForegroundColorAttributeName: UIColor.gray]))
        
        let attributedText = NSAttributedString(string: timeAgoDisplay, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12),NSForegroundColorAttributeName: UIColor.gray])

//        self.captionLabel.attributedText = attributedText
        self.postDateLabel.attributedText = attributedText
        
        
    }
    
    fileprivate func setupAttributedLocationName(){
        
        guard let post = self.post else {return}
        var displayLocationName: String = ""
        
        if post.locationGooglePlaceID! == "" {
            // Detect Not Google Tagged Location

            let locationNameTextArray = post.locationAdress.components(separatedBy: ",")
            // Last 3 items are City, State, Country
            displayLocationName = locationNameTextArray.suffix(3).joined(separator: ",")
        } else {
            displayLocationName = post.locationName
        }
        
        self.locationLabel.text = displayLocationName
//
//
//        let attributedText = NSMutableAttributedString(string: post.locationName.truncate(length: 20), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12)])
//
//        if post.distance != nil && post.locationGPS?.coordinate.longitude != 0 && post.locationGPS?.coordinate.latitude != 0 {
//
//            let distanceformat = ".2"
//
//            // Convert to M to KM
//            let locationDistance = post.distance!/1000
//
//            attributedText.append(NSAttributedString(string: " \(locationDistance.format(f: distanceformat)) KM", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 10),NSForegroundColorAttributeName: UIColor.gray]))
//        }
//        self.locationLabel.attributedText = attributedText
        
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
        iv.isUserInteractionEnabled = true
        
        return iv
        
    }()
    
    var starRatingLabel = RatingLabel()
    var starRatingLabelWidth: NSLayoutConstraint?
    
    lazy var legitIcon: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "starfilled").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(openLegitList), for: .touchUpInside)
        return button
    }()
    
    func openLegitList(){
        print("Open Legit List")
    }

    lazy var ratingEmojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emojis"
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.textAlignment = NSTextAlignment.right
        label.backgroundColor = UIColor.clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(ratingEmojiSelected(_:)))
        label.addGestureRecognizer(tap)
        label.isUserInteractionEnabled = true
        return label
        
    }()
    
    
    lazy var nonRatingEmojiLabel1: UILabel = {
        let label = UILabel()
        let tap = UITapGestureRecognizer(target: self, action: #selector(nonRatingEmojiSelected(_:)))
        label.addGestureRecognizer(tap)
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor.clear
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.tag = 0
        return label
    }()
    
    lazy var nonRatingEmojiLabel2: UILabel = {
        let label = UILabel()
        let tap = UITapGestureRecognizer(target: self, action: #selector(nonRatingEmojiSelected(_:)))
        label.addGestureRecognizer(tap)
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor.clear
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.tag = 1
        return label
    }()
    
    lazy var nonRatingEmojiLabel3: UILabel = {
        let label = UILabel()
        let tap = UITapGestureRecognizer(target: self, action: #selector(nonRatingEmojiSelected(_:)))
        label.addGestureRecognizer(tap)
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor.clear
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.tag = 2
        return label
    }()
    
    lazy var nonRatingEmojiLabel4: UILabel = {
        let label = UILabel()
        let tap = UITapGestureRecognizer(target: self, action: #selector(nonRatingEmojiSelected(_:)))
        label.addGestureRecognizer(tap)
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor.clear
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.tag = 3
        return label
    }()
    
    lazy var nonRatingEmojiLabel5: UILabel = {
        let label = UILabel()
        let tap = UITapGestureRecognizer(target: self, action: #selector(nonRatingEmojiSelected(_:)))
        label.addGestureRecognizer(tap)
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor.clear
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.tag = 4
        return label
    }()

    var nonRatingEmojiLabelArray:[UILabel] = []
    
    func setupEmojiLabels(){
        
        guard let post = post else {return}
        
        self.ratingEmojiLabel.text = self.post?.ratingEmoji
        
        for label in self.nonRatingEmojiLabelArray {
            label.text = ""
        }
        if self.post?.nonRatingEmoji != nil {
            for (index, emoji) in (self.post?.nonRatingEmoji.enumerated())! {
                self.nonRatingEmojiLabelArray[index].text = emoji
                self.nonRatingEmojiLabelArray[index].sizeToFit()
            }
        }
    }
    
    
    func nonRatingEmojiSelected(_ sender: UIGestureRecognizer){
        print("Non Rating Emoji Selected")
        
        guard let post = post else {return}
        guard let labelTag = sender.view?.tag else {return}
        
        var displayEmoji = self.post?.nonRatingEmoji[labelTag]
        var displayEmojiTag = self.post?.nonRatingEmojiTags[labelTag]
        
        if let emojiTagLookup = ReverseEmojiDictionary.key(forValue: displayEmojiTag!) {
            displayEmojiTag = emojiTagLookup
        }
        
        let selectedLabel = self.nonRatingEmojiLabelArray[labelTag]
        selectedLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        selectedLabel.transform = .identity
            },
                       completion: nil)
        
        self.delegate?.displaySelectedEmoji(emoji: displayEmoji!, emojitag: displayEmojiTag!)
        
//        var origin: CGPoint = selectedLabel.center;
//        var topleft = CGPoint(x: selectedLabel.center.x - selectedLabel.bounds.size.width/2, y: selectedLabel.center.y - (selectedLabel.bounds.size.height / 2) - 200 )
//        popView.backgroundColor = UIColor.blue
//        popView = UIView(frame: CGRect(x: topleft.x, y: topleft.y, width: 200, height: 200))
//        popView.frame.origin.x = topleft.x
//        popView.frame.origin.y = topleft.y
//        self.addSubview(popView)
        
    }
    
    func ratingEmojiSelected(_ sender: UIGestureRecognizer){
        print("Rating Emoji Selected")
        
        guard let post = post else {return}
        
        var displayEmoji = self.post?.ratingEmoji
        var displayEmojiTag = displayEmoji
        
        if let emojiTagLookup = ReverseEmojiDictionary.key(forValue: displayEmoji!) {
            displayEmojiTag = emojiTagLookup
        } else {
        }
        
        self.ratingEmojiLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.ratingEmojiLabel.transform = .identity
            },
                       completion: nil)
        
        self.delegate?.displaySelectedEmoji(emoji: displayEmoji!, emojitag: displayEmojiTag!)
    }
    
    
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
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(locationTap))
        uv.addGestureRecognizer(locationTapGesture)
//        uv.isUserInteractionEnabled = true
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
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = UIColor.black
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(locationTap))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(locationTapGesture)
        return label
    }()
    
    let locationDistanceLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 11)
        
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
    
    let captionBubble: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textAlignment = NSTextAlignment.center
        label.layer.backgroundColor = UIColor.lightGray.cgColor.copy(alpha: 0.5)
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.numberOfLines = 0
        return label
    }()
    
    let postDateLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()


    lazy var optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("•••", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(handleOptions), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()
    
    
    
    func handleOptions() {
        
        guard let post = post else {return}
        print("Options Button Pressed")
        delegate?.userOptionPost(post: post)
    }
    
    lazy var extraTagLabel1: UIButton = {
        let label = UIButton()
        label.tag = 0
        label.addTarget(self, action: #selector(extraTagselected(_:)), for: .touchUpInside)
        
        label.backgroundColor = UIColor.white
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.layer.borderWidth = 0
        label.layer.borderColor = UIColor.gray.cgColor

        label.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)

        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        label.titleLabel?.textAlignment = NSTextAlignment.center

        return label
    }()
    
    lazy var extraTagLabel2: UIButton = {
        let label = UIButton()
        label.tag = 1
        label.addTarget(self, action: #selector(extraTagselected(_:)), for: .touchUpInside)
        
        label.backgroundColor = UIColor.white
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.layer.borderWidth = 0
        label.layer.borderColor = UIColor.gray.cgColor

        label.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)

        
        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        label.titleLabel?.textAlignment = NSTextAlignment.center

        return label
    }()
    
    lazy var extraTagLabel3: UIButton = {
        let label = UIButton()
        label.tag = 2
        label.addTarget(self, action: #selector(extraTagselected(_:)), for: .touchUpInside)
        
        label.backgroundColor = UIColor.white
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.layer.borderWidth = 0
        label.layer.borderColor = UIColor.gray.cgColor
        label.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)

        
        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        label.titleLabel?.textAlignment = NSTextAlignment.center

        return label
    }()
    
    lazy var extraTagLabel4: UIButton = {
        let label = UIButton()
        label.tag = 3
        label.addTarget(self, action: #selector(extraTagselected(_:)), for: .touchUpInside)
        
        label.backgroundColor = UIColor.white
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.gray.cgColor
        label.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)

        
        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        label.titleLabel?.textAlignment = NSTextAlignment.center

        return label
    }()
    
    lazy var extraTagLabel5: UIButton = {
        let label = UIButton()
        label.tag = 4
        label.addTarget(self, action: #selector(extraTagselected(_:)), for: .touchUpInside)
        
        label.backgroundColor = UIColor.white
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.gray.cgColor
        label.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        
        
        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        label.titleLabel?.textAlignment = NSTextAlignment.center
        
        return label
    }()
    
    lazy var extraTagLabel6: UIButton = {
        let label = UIButton()
        label.tag = 5
        label.addTarget(self, action: #selector(extraTagselected(_:)), for: .touchUpInside)
        
        label.backgroundColor = UIColor.white
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.gray.cgColor
        label.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        
        
        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        label.titleLabel?.textAlignment = NSTextAlignment.center
        
        return label
    }()

    
    func extraTagselected(_ sender: UIButton){
        guard let post = post else {return}
        let listTag = sender.tag
        
        var selectedListName = self.extraTagsNameArray[listTag]
        var selectedListId = self.extraTagsIdArray[listTag]
        
        print("Selected Creator Tag: \(selectedListName), \(selectedListId)")
        delegate?.didTapExtraTag(tagName: selectedListName, tagId: selectedListId, post: post)
    }
    
    
    let extraTagView: UIView = {
        let uv = UIView()
        uv.backgroundColor = UIColor.clear
        return uv
    }()
    
    var extraTagViewHeight:NSLayoutConstraint?
    
    let creatorTagView: UIView = {
        let uv = UIView()
        uv.backgroundColor = UIColor.clear
        return uv
    }()

    // Extra Tags
    
    let extraTagFontSize: CGFloat = 13
    let extraTagViewHeightSize: CGFloat = 25
    var extraTagsArray:[UIButton] = []
    
    var extraTagsNameArray: [String] = []
    var extraTagsIdArray: [String] = []
    var userTagsNameArray: [String] = []
    var userTagsIdArray: [String] = []
    


    
    
    func setupExtraTagButtons() {

        // Refresh Tags
        extraTagsNameArray.removeAll()
        extraTagsIdArray.removeAll()
        userTagsNameArray.removeAll()
        userTagsIdArray.removeAll()
        
    // Reset Extra Tags
        extraTagsArray = [extraTagLabel1, extraTagLabel2, extraTagLabel3, extraTagLabel4,extraTagLabel5,extraTagLabel6]

        for label in self.extraTagsArray {
            label.setTitle(nil, for: .normal)
            label.setImage(nil, for: .normal)
            label.layer.borderWidth = 0
            label.removeFromSuperview()
        }
        

        
        
    // Creator Extra Tags
        if post?.creatorListId != nil {
            var listCount = post?.creatorListId?.count
            
            // Add Legit List
            for list in (post?.creatorListId)! {
                if list.value == legitListName {
                    extraTagsNameArray.append(list.value)
                    extraTagsIdArray.append(list.key)
                }
            }
            
            // Add Other List
            for list in (post?.creatorListId)! {
                if list.value != legitListName && list.value != bookmarkListName {
                    if extraTagsNameArray.count < 2 {
                        extraTagsNameArray.append(list.value)
                        extraTagsIdArray.append(list.key)
                    } else if extraTagsNameArray.count == 2 && listCount! > 2 {
                        extraTagsNameArray.append("+\(listCount! - 2)")
                        extraTagsIdArray.append("creatorLists")
                    }
                }
            }
        }
        
    // Creator Price Tag
        if post?.price != nil {
            extraTagsNameArray.append((post?.price)!)
            extraTagsIdArray.append("price")
        }
        
    
    // User Extra Tags
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("SetupUserTag: Invalid Current User UID")
            return
        }
        
        if post?.creatorUID != uid && post?.selectedListId != nil {
            
            var userListCount = post?.selectedListId?.count

            
            // User Bookmarks
            for list in (post?.selectedListId)! {
                if list.value == bookmarkListName {
                    userTagsNameArray.append(list.value)
                    userTagsIdArray.append(list.key)
                }
            }

            // Add Other User List
            for list in (post?.selectedListId)! {
                if list.value != legitListName && list.value != bookmarkListName {
                    if userTagsNameArray.count == 0 {
                        userTagsNameArray.append(list.value)
                        userTagsIdArray.append(list.key)
                    } else if userTagsNameArray.count == 1 && userListCount! > 1{
                        userTagsNameArray.append("+\(userListCount! - 1)")
                        userTagsIdArray.append("userLists")
                    }
                }
            }
            
            // Add User Tags to Extra Tags
            extraTagsNameArray = extraTagsNameArray + userTagsNameArray
            extraTagsIdArray = extraTagsIdArray + userTagsIdArray
        
        }
        

        // Creator Tag Button Label
        if extraTagsNameArray.count > 0 {
            for (index, listName) in (self.extraTagsNameArray.enumerated()) {
                
                extraTagsArray[index].setTitle(extraTagsNameArray[index], for: .normal)
                extraTagsArray[index].titleLabel?.font = UIFont.boldSystemFont(ofSize: extraTagFontSize)
                extraTagsArray[index].layer.borderWidth = 1


                if extraTagsNameArray[index] == legitListName {
//                    extraTagsArray[index].setTitleColor(UIColor.rgb(red: 255, green: 128, blue: 0), for: .normal)
                    extraTagsArray[index].setTitleColor(UIColor.mainBlue(), for: .normal)
                    extraTagsArray[index].setImage(#imageLiteral(resourceName: "starfilled"), for: .normal)
                }
                else if extraTagsNameArray[index] == bookmarkListName {
//                    extraTagsArray[index].setTitleColor(UIColor.rgb(red: 255, green: 0, blue: 0), for: .normal)
                    extraTagsArray[index].setTitleColor(UIColor.rgb(red: 255, green: 128, blue: 0), for: .normal)
                    extraTagsArray[index].setImage(#imageLiteral(resourceName: "bookmark_filled"), for: .normal)
                }
                else if extraTagsIdArray[index] == "price" {
                    extraTagsArray[index].setTitleColor(UIColor.rgb(red: 0, green: 153, blue: 0), for: .normal)
                }
                else {
                    if index < extraTagsNameArray.count - userTagsNameArray.count {
                        // Creator Tags
                        extraTagsArray[index].setTitle(extraTagsNameArray[index].truncate(length: 10) + "!", for: .normal)
                        extraTagsArray[index].backgroundColor = UIColor.white
                        extraTagsArray[index].setTitleColor(UIColor.mainBlue(), for: .normal)
                    } else {
                        // User Tags
                        extraTagsArray[index].setTitle(extraTagsNameArray[index].truncate(length: 10) + "!", for: .normal)
                        extraTagsArray[index].backgroundColor = UIColor(white: 0, alpha: 0.2)
                        extraTagsArray[index].setTitleColor(UIColor.rgb(red: 255, green: 128, blue: 0), for: .normal)
                    }
                }
                
                extraTagsArray[index].layer.borderWidth = 1

                // Extra Tag Background Color (Different Fill Color for Creator Vs User
                if index < extraTagsNameArray.count - userTagsNameArray.count {
                    // Creator Tags
                    extraTagsArray[index].backgroundColor = UIColor.white
                    extraTagsArray[index].layer.borderColor = UIColor.mainBlue().cgColor
                } else {
                    // User Tags
                    extraTagsArray[index].backgroundColor = UIColor.rgb(red: 255, green: 204, blue: 153).withAlphaComponent(0.1)
                    extraTagsArray[index].layer.borderColor = UIColor.rgb(red: 255, green: 153, blue: 51).cgColor
                }
                
                // Green Border For Price
                if extraTagsIdArray[index] == "price" {
                    extraTagsArray[index].layer.borderColor = UIColor.rgb(red: 0, green: 153, blue: 0).cgColor
                }
                
        // Add Creator Tag Button to View
                let displayButton = extraTagsArray[index]
                self.addSubview(displayButton)
                
                if index == 0{
                    displayButton.anchor(top: extraTagView.topAnchor, left: extraTagView.leftAnchor, bottom: extraTagView.bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 10, paddingBottom: 1, paddingRight: 0, width: 0, height: 0)
                } else {
                    displayButton.anchor(top: extraTagView.topAnchor, left: extraTagsArray[index - 1].rightAnchor, bottom: extraTagView.bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 6, paddingBottom: 1, paddingRight: 0, width: 0, height: 0)
                }
            }
        }
    
    }
 
    func setupExtraTags(){
        setupExtraTagButtons()
        
        if extraTagsNameArray.count == 0 {
            extraTagViewHeight?.constant = 0
        } else {
            extraTagViewHeight?.constant = extraTagViewHeightSize
        }        
        
    }
    
    func displayCaptionBubble(){
        
        print("Bubble Caption Displayed")
        guard let post = self.post else {return}
        
        captionBubble.text = post.caption
        captionBubble.sizeToFit()
        
        self.addSubview(captionBubble)
        captionBubble.anchor(top: photoImageView.topAnchor, left: photoImageView.leftAnchor, bottom: nil, right: photoImageView.rightAnchor, paddingTop: 30, paddingLeft: 30, paddingBottom: 0, paddingRight: 30, width: 0, height: 0)
        
        self.fadeViewInThenOut(view: captionBubble, delay: 3)
    }
    
    func hideCaptionBubble(){
        
        self.captionBubble.removeFromSuperview()

    }

    func fadeViewInThenOut(view : UIView, delay: TimeInterval) {
        
        let animationDuration = 0.0
        
        // Fade in the view
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            view.alpha = 1
        }) { (Bool) -> Void in
            
            // After the animation completes, fade out the view after a delay
            
            UIView.animate(withDuration: animationDuration, delay: delay, options: .curveEaseInOut, animations: { () -> Void in
                view.alpha = 0
            },
                           completion: nil)
        }
    }

    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(headerView)
        addSubview(photoImageView)
        addSubview(userProfileImageView)
        addSubview(usernameLabel)
        addSubview(emojiDetailLabel)
        addSubview(ratingEmojiLabel)
        addSubview(bookmarkButton)
//        addSubview(starRatingLabel)
        addSubview(legitIcon)
        
        headerView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)

// Setup Non Rating Emojis
        
        nonRatingEmojiLabelArray = [nonRatingEmojiLabel1, nonRatingEmojiLabel2, nonRatingEmojiLabel3, nonRatingEmojiLabel4, nonRatingEmojiLabel5]
        
        for (index,label) in nonRatingEmojiLabelArray.enumerated(){
            addSubview(label)
            
            if index == 0{
                label.anchor(top: headerView.topAnchor, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            } else {
                label.anchor(top: headerView.topAnchor, left: nonRatingEmojiLabelArray[index - 1].rightAnchor, bottom: headerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            }
        }
        
    
        emojiDetailLabel.anchor(top: topAnchor, left: nil, bottom: photoImageView.topAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 200, height: 0)
        emojiDetailLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        emojiDetailLabel.isHidden = true
        
// Username Details and Rating Emojis
        
        userProfileImageView.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 0, paddingRight: 5, width: 40, height: 40)
        userProfileImageView.layer.cornerRadius = 40/2
        userProfileImageView.layer.borderWidth = 0.25
        userProfileImageView.layer.borderColor = UIColor.lightGray.cgColor
        
        usernameLabel.anchor(top: userProfileImageView.topAnchor, left: nil, bottom: userProfileImageView.bottomAnchor, right: userProfileImageView.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        
        usernameLabel.textAlignment = .right
//        usernameLabel.backgroundColor = UIColor.yellow

//        starRatingLabel.anchor(top: nil, left: nil, bottom: nil, right: usernameLabel.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 2, width: 0, height: 25)
//        starRatingLabel.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor).isActive = true
//        starRatingLabelWidth = NSLayoutConstraint(item: starRatingLabel, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 25)
//
//        starRatingLabelWidth?.isActive = true
//
        
        legitIcon.anchor(top: nil, left: nil, bottom: nil, right: usernameLabel.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 2, width: 25, height: 25)
        legitIcon.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor).isActive = true
        legitIcon.isHidden = true
        checkPostForLegit()
        
//        ratingEmojiLabel.anchor(top: topAnchor, left: nil, bottom: photoImageView.topAnchor, right: usernameLabel.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 2, width: 0, height: 0)
        
// Photo Image View and Complex User Interactions
        
        photoImageView.anchor(top: headerView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        photoImageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(photoDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        photoImageView.addGestureRecognizer(doubleTap)
        photoImageView.isUserInteractionEnabled = true
        
//        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(locationTap))
//        photoImageView.addGestureRecognizer(locationTapGesture)
//        locationTapGesture.require(toFail: doubleTap)
        
        let captionTapGesture = UITapGestureRecognizer(target: self, action: #selector(displayCaptionBubble))
        photoImageView.addGestureRecognizer(captionTapGesture)
        captionTapGesture.require(toFail: doubleTap)
        
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
        pinch.delegate = self
        self.photoImageView.addGestureRecognizer(pinch)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.pan(sender:)))
        pan.delegate = self
        self.photoImageView.addGestureRecognizer(pan)

        
// Location View
        
        addSubview(locationView)
        locationView.anchor(top: photoImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 25)
        //        locationView.backgroundColor = UIColor.yellow
        
        addSubview(locationLabel)
        addSubview(locationDistanceLabel)
        
        locationDistanceLabel.anchor(top: locationView.topAnchor, left: nil, bottom: locationView.bottomAnchor, right: locationView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 5, width: 0, height: 0)
        
        locationLabel.anchor(top: locationView.topAnchor, left: leftAnchor, bottom: locationView.bottomAnchor, right: locationDistanceLabel.leftAnchor, paddingTop: 3, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        

//        extraTagView.layer.borderWidth = 0.5
//        extraTagView.layer.borderColor = UIColor.lightGray.cgColor
        //        extraTagView.backgroundColor = UIColor.blue
        

        
        addSubview(actionBar)
        actionBar.anchor(top: locationView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)

        
//        actionBar.layer.borderColor = UIColor.lightGray.cgColor
//        actionBar.layer.borderWidth = 0.5
        setupActionButtons()

//        let bottomDividerView = UIView()
//        bottomDividerView.backgroundColor = UIColor.lightGray
//        addSubview(bottomDividerView)
//
//        bottomDividerView.anchor(top: nil, left: leftAnchor, bottom: actionBar.bottomAnchor, right: rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
//
        // Setup List and Price Tags
        
        addSubview(extraTagView)
        extraTagView.anchor(top: actionBar.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        extraTagViewHeight = NSLayoutConstraint(item: extraTagView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1, constant: extraTagViewHeightSize)
        extraTagViewHeight?.isActive = true

        
        addSubview(postDateLabel)
        postDateLabel.anchor(top: extraTagView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        
        addSubview(optionsButton)
        optionsButton.anchor(top: postDateLabel.topAnchor, left: nil, bottom: postDateLabel.bottomAnchor, right: postDateLabel.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        optionsButton.widthAnchor.constraint(equalTo: optionsButton.heightAnchor).isActive = true
        optionsButton.centerYAnchor.constraint(equalTo: postDateLabel.centerYAnchor).isActive = true
        optionsButton.isHidden = true
        

    }
    
    // Action Buttons
    
    var actionBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
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
        guard let creatorId = self.post?.creatorUID else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        self.likeButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        self.layoutIfNeeded()
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.likeButton.transform = .identity
                        self?.likeButton.layoutIfNeeded()
                        
            },
                       completion: nil)
        
        
        Database.handleLike(postId: postId, creatorUid: creatorId){
        }
        
        // Animates before database function is complete
        
        if (self.post?.hasLiked)! {
            self.post?.likeCount -= 1
        } else {
            self.post?.likeCount += 1
        }
        self.post?.hasLiked = !(self.post?.hasLiked)!
        self.setupAttributedSocialCount()
        self.delegate?.refreshPost(post: self.post!)
        
    }
    
    // Bookmark
    
    lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "bookmark_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBookmark), for: .touchUpInside)
        return button
        
    }()
    
    func handleBookmark() {
        guard let post = post else {return}
        delegate?.didTapBookmark(post: post)

    }
    
//    func handleBookmark() {
//
//        //    delegate?.didBookmark(for: self)
//
//        guard let postId = self.post?.id else {return}
//        guard let creatorId = self.post?.creatorUID else {return}
//        guard let uid = Auth.auth().currentUser?.uid else {return}
//
//        Database.handleBookmark(postId: postId, creatorUid: creatorId){
//        }
//
//        // Animates before database function is complete
//
//        if (self.post?.hasBookmarked)! {
//            self.post?.bookmarkCount -= 1
//        } else {
//            self.post?.bookmarkCount += 1
//        }
//        self.post?.hasBookmarked = !(self.post?.hasBookmarked)!
//        self.setupAttributedSocialCount()
//        self.delegate?.refreshPost(post: self.post!)
//
//        bookmarkButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
//
//        UIView.animate(withDuration: 1.0,
//                       delay: 0,
//                       usingSpringWithDamping: 0.2,
//                       initialSpringVelocity: 6.0,
//                       options: .allowUserInteraction,
//                       animations: { [weak self] in
//                        self?.bookmarkButton.transform = .identity
//            },
//                       completion: nil)
//
//    }
//
    
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

    
    let bookmarkCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:12)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.right
        return label
    }()
    
    let messageCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:12)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    let commentCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:12)
        label.textColor = UIColor.black
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    // Upvote Downvote
    
    lazy var upVoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "upvote").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleUpVote), for: .touchUpInside)
        return button
        
    }()
    
    lazy var downVoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "downvote").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleDownVote), for: .touchUpInside)
        return button
        
    }()
    
    let voteCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize:11)
        label.textColor = UIColor.darkGray
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    func handleUpVote(){
        guard let postId = self.post?.id else {return}
        guard let creatorId = self.post?.creatorUID else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        self.upVoteButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        self.layoutIfNeeded()
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.upVoteButton.transform = .identity
                        self?.upVoteButton.layoutIfNeeded()
                        
            },
                       completion: nil)
        
        Database.handleVote(postId: postId, creatorUid: creatorId, vote: 1) { 
            
        }

        
        // Animates before database function is complete
        
        if (self.post?.hasVoted)! == 1 {
            // Unselect Upvote
            self.post?.hasVoted = 0
            self.post?.voteCount -= 1
        } else if (self.post?.hasVoted)! == 0 {
            // Upvote
            self.post?.hasVoted = 1
            self.post?.voteCount += 1
        } else if (self.post?.hasVoted)! == -1 {
            // Upvote
            self.post?.hasVoted = 1
            self.post?.voteCount += 2
        }
        
        self.setupAttributedSocialCount()
        self.delegate?.refreshPost(post: self.post!)
    }
    
    func handleDownVote(){
        guard let postId = self.post?.id else {return}
        guard let creatorId = self.post?.creatorUID else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        self.downVoteButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        self.layoutIfNeeded()
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.downVoteButton.transform = .identity
                        self?.downVoteButton.layoutIfNeeded()
                        
            },
                       completion: nil)
        
        Database.handleVote(postId: postId, creatorUid: creatorId, vote: -1) {
            
        }
        
        
        // Animates before database function is complete
        
        if (self.post?.hasVoted)! == 1 {
            // Downvote
            self.post?.hasVoted = -1
            self.post?.voteCount += -2
        } else if (self.post?.hasVoted)! == 0 {
            // Downvote
            self.post?.hasVoted = -1
            self.post?.voteCount += -1
        } else if (self.post?.hasVoted)! == -1 {
            // Unselect Downvote
            self.post?.hasVoted = 0
            self.post?.voteCount += 1
        }
        
        self.setupAttributedSocialCount()
        self.delegate?.refreshPost(post: self.post!)
    }
    
    
    fileprivate func setupActionButtons() {

        
        let voteView = UIView()
        //        voteView.backgroundColor = UIColor.blue
        
        let commentView = UIView()
        //        commentView.backgroundColor = UIColor.yellow
        
        let bookmarkView = UIView()
        //        bookmarkView.backgroundColor = UIColor.blue
        
        let messageView = UIView()
        //        messageView.backgroundColor = UIColor.yellow
        
        let voteContainer = UIView()
        let commentContainer = UIView()
        let bookmarkContainer = UIView()
        let messageContainer = UIView()
        let actionStackView = UIStackView(arrangedSubviews: [voteView, commentView, bookmarkView, messageView])
        actionStackView.distribution = .fillEqually

        addSubview(actionStackView)
        
        actionStackView.anchor(top: actionBar.topAnchor, left: leftAnchor, bottom: actionBar.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        addSubview(upVoteButton)
        addSubview(downVoteButton)
        addSubview(voteCount)
        
        upVoteButton.anchor(top: voteView.topAnchor, left: voteView.leftAnchor, bottom: voteView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        upVoteButton.widthAnchor.constraint(equalTo: upVoteButton.heightAnchor, multiplier: 1).isActive = true
        
        downVoteButton.anchor(top: voteView.topAnchor, left: nil, bottom: voteView.bottomAnchor, right: voteView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        downVoteButton.widthAnchor.constraint(equalTo: downVoteButton.heightAnchor, multiplier: 1).isActive = true
        
        voteCount.anchor(top: voteView.topAnchor, left: upVoteButton.rightAnchor, bottom: voteView.bottomAnchor, right: downVoteButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        voteCount.sizeToFit()
        
    // Comments
        
        commentContainer.addSubview(commentButton)
        commentContainer.addSubview(commentCount)
        
        commentButton.anchor(top: commentContainer.topAnchor, left: commentContainer.leftAnchor, bottom: commentContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        commentButton.widthAnchor.constraint(equalTo: commentButton.heightAnchor, multiplier: 1).isActive = true

        commentCount.anchor(top: commentContainer.topAnchor, left: commentButton.rightAnchor, bottom: commentContainer.bottomAnchor, right: commentContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        commentCount.centerYAnchor.constraint(equalTo: commentButton.centerYAnchor).isActive = true
        commentCount.sizeToFit()
        
        addSubview(commentContainer)
        commentContainer.anchor(top: commentView.topAnchor, left: nil, bottom: commentView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        commentContainer.centerXAnchor.constraint(equalTo: commentView.centerXAnchor).isActive = true
        
    // Bookmarks
        
        bookmarkContainer.addSubview(bookmarkButton)
        bookmarkContainer.addSubview(bookmarkCount)
        
        bookmarkButton.anchor(top: bookmarkContainer.topAnchor, left: bookmarkContainer.leftAnchor, bottom: bookmarkContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        bookmarkButton.widthAnchor.constraint(equalTo: bookmarkButton.heightAnchor, multiplier: 1).isActive = true
        
        bookmarkCount.anchor(top: bookmarkContainer.topAnchor, left: bookmarkButton.rightAnchor, bottom: bookmarkContainer.bottomAnchor, right: bookmarkContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        bookmarkCount.centerYAnchor.constraint(equalTo: bookmarkButton.centerYAnchor).isActive = true
        
        bookmarkCount.sizeToFit()
        
        addSubview(bookmarkContainer)
        bookmarkContainer.anchor(top: bookmarkView.topAnchor, left: nil, bottom: bookmarkView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        bookmarkContainer.centerXAnchor.constraint(equalTo: bookmarkView.centerXAnchor).isActive = true

        
    // Message
        
        messageContainer.addSubview(sendMessageButton)
        messageContainer.addSubview(messageCount)
        
        sendMessageButton.anchor(top: messageContainer.topAnchor, left: messageContainer.leftAnchor, bottom: messageContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        sendMessageButton.widthAnchor.constraint(equalTo: sendMessageButton.heightAnchor, multiplier: 1).isActive = true
        
        messageCount.anchor(top: messageContainer.topAnchor, left: sendMessageButton.rightAnchor, bottom: messageContainer.bottomAnchor, right: messageContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        messageCount.centerYAnchor.constraint(equalTo: sendMessageButton.centerYAnchor).isActive = true
        
        messageCount.text = "10"
        messageCount.sizeToFit()
        
        addSubview(messageContainer)
        messageContainer.anchor(top: messageView.topAnchor, left: nil, bottom: messageView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        messageContainer.centerXAnchor.constraint(equalTo: messageView.centerXAnchor).isActive = true
        
    // Dividers
        
        let dividerColor = UIColor.lightGray
        
        let div1 = UIView()
        div1.backgroundColor = dividerColor
        addSubview(div1)
        div1.anchor(top: actionStackView.topAnchor, left: commentView.leftAnchor, bottom: actionStackView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 1, height: 0)
        div1.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true

        let div2 = UIView()
        div2.backgroundColor = dividerColor
        addSubview(div2)
        div2.anchor(top: actionStackView.topAnchor, left: bookmarkView.leftAnchor, bottom: actionStackView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 1, height: 0)
        div2.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true
        

        let div3 = UIView()
        div3.backgroundColor = dividerColor
        addSubview(div3)
        div3.anchor(top: actionStackView.topAnchor, left: messageView.leftAnchor, bottom: actionStackView.bottomAnchor, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 1, height: 0)
        div3.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true
        
        
        
//        for i in 1 ..< (actionStackView.arrangedSubviews.count - 1){
//            let div = UIView()
//            div.widthAnchor.constraint(equalToConstant: 1).isActive = true
//            div.backgroundColor = .black
//            addSubview(div)
//            div.heightAnchor.constraint(equalTo: actionStackView.heightAnchor, multiplier: 0.4).isActive = true
//            div.centerXAnchor.constraint(equalTo: actionStackView.arrangedSubviews[i].leftAnchor).isActive = true
//            div.centerYAnchor.constraint(equalTo: actionStackView.centerYAnchor).isActive = true
//        }

        
        
    }
//
//    fileprivate func setupActionButtonsTest() {
//
////        let stackView = UIStackView(arrangedSubviews: [likeButton, commentButton, sendMessageButton])
////        stackView.distribution = .fillEqually
////        addSubview(stackView)
////        stackView.anchor(top: locationView.bottomAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 120, height: 40)
//
//
//        addSubview(actionBar)
//        actionBar.anchor(top: locationView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
//
////        addSubview(likeButton)
////        likeButton.anchor(top: actionBar.topAnchor, left: actionBar.leftAnchor, bottom: actionBar.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 8, paddingBottom: 5, paddingRight: 0, width: 30, height: 30)
//
//        addSubview(commentButton)
//        commentButton.anchor(top: actionBar.topAnchor, left: actionBar.leftAnchor, bottom: actionBar.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 2, paddingBottom: 5, paddingRight: 0, width: 30, height: 30)
//
//        addSubview(sendMessageButton)
//        sendMessageButton.anchor(top: actionBar.topAnchor, left: commentButton.rightAnchor, bottom: actionBar.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 2, paddingBottom: 5, paddingRight: 0, width: 30, height: 30)
//
//        addSubview(messageCount)
//        messageCount.anchor(top: actionBar.topAnchor, left: sendMessageButton.rightAnchor, bottom: actionBar.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 2, paddingBottom: 5, paddingRight: 0, width: 30, height: 30)
//
//
//
//        addSubview(upVoteButton)
//        addSubview(downVoteButton)
//        addSubview(voteCount)
//
//        downVoteButton.anchor(top: actionBar.topAnchor, left: nil, bottom: actionBar.bottomAnchor, right: actionBar.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 30, height: 0)
//        downVoteButton.widthAnchor.constraint(equalTo: downVoteButton.heightAnchor, multiplier: 1)
//
//        voteCount.anchor(top: actionBar.topAnchor, left: nil, bottom: actionBar.bottomAnchor, right: downVoteButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        voteCount.sizeToFit()
//
//        upVoteButton.anchor(top: actionBar.topAnchor, left: nil, bottom: actionBar.bottomAnchor, right: voteCount.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        upVoteButton.widthAnchor.constraint(equalTo: upVoteButton.heightAnchor, multiplier: 1)
//
//
////        addSubview(bookmarkCount)
////        bookmarkCount.anchor(top: actionBar.topAnchor, left: nil, bottom: actionBar.bottomAnchor, right: upVoteButton.leftAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 8, width: 0, height: 30)
////        bookmarkCount.sizeToFit()
////        bookmarkLabelConstraint = NSLayoutConstraint(item: self.bookmarkCount, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: self.bookmarkCount.frame.size.width)
////        self.bookmarkCount.addConstraint(bookmarkLabelConstraint!)
////        bookmarkLabel.widthAnchor.constraint(equalToConstant: self.bookmarkLabel.frame.size.width).isActive = true
//
//        // Width anchor is set after bookmark counts are displayed to figure out label width
//        addSubview(bookmarkButton)
//        bookmarkButton.anchor(top: actionBar.topAnchor, left: nil, bottom: actionBar.bottomAnchor, right: upVoteButton.leftAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 2, width: 30, height: 30)
//
////        addSubview(testlabel)
////        testlabel.anchor(top: bookmarkButton.topAnchor, left: bookmarkButton.leftAnchor, bottom: bookmarkButton.bottomAnchor, right: bookmarkButton.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//
//
//
//
//    }
//
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
        popView = UIView(frame: CGRect(x: origin.x, y: origin.y, width: 200, height: 200))
        popView = UIImageView(image: #imageLiteral(resourceName: "heart"))
        popView.contentMode = .scaleToFill
        popView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
        popView.frame.origin.x = origin.x
        popView.frame.origin.y = origin.y * (1/3)
        
        photoImageView.addSubview(popView)
        
            UIView.animate(withDuration: 1.5,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.popView.transform = .identity
                }) { (done) in
                    self.popView.alpha = 0
                }

    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
        photoImageView.cancelImageRequestOperation()
    }
    
    
}

