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
import Spring


protocol HomePostCellDelegate {
    func didTapBookmark(post:Post)
    func didTapComment(post:Post)
    func didTapUser(post:Post)
    func didTapLocation(post:Post)
    func didTapMessage(post:Post)
    func refreshPost(post:Post)
    
    func userOptionPost(post:Post)

    func displaySelectedEmoji(emoji: String, emojitag: String)
    func didTapExtraTag(tagName: String, tagId: String, post: Post)

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
            
            setupEmojiLabels()
 
            guard let profileImageUrl = post?.user.profileImageUrl else {return}
            
            userProfileImageView.loadImage(urlString: profileImageUrl)
            setupExtraTags()
            setupLegitIcon()

            captionLabel.text = post?.caption
            setupAttributedLocationName()
            setupAttributedCaption()
            setupAttributedSocialCount()
            
            captionBubble.text = post?.caption
            captionBubble.sizeToFit()
            
            // Distance
            if post?.distance != nil && post?.locationGPS?.coordinate.longitude != 0 && post?.locationGPS?.coordinate.latitude != 0 {
                
                guard let postdistance = post?.distance else {return}
                let distanceInKM = postdistance/1000
                let locationDistance = Measurement.init(value: distanceInKM, unit: UnitLength.kilometers)
                
                if distanceInKM < 100 {
                    locationDistanceLabel.text =  CurrentUser.distanceFormatter.string(from: locationDistance)
                }  else if distanceInKM < 300 {
                    locationDistanceLabel.text =  "🚗"+CurrentUser.distanceFormatter.string(from: locationDistance)
                }  else if distanceInKM >= 300 {
                    locationDistanceLabel.text =  "✈️"+CurrentUser.distanceFormatter.string(from: locationDistance)
                }
            } else {
                locationDistanceLabel.text = ""
            }
            locationDistanceLabel.adjustsFontSizeToFitWidth = true
            locationDistanceLabel.sizeToFit()
            
            // Options Button
            
            if post?.creatorUID == Auth.auth().currentUser?.uid {
                optionsButton.isHidden = false
            } else {
                optionsButton.isHidden = true
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
        
        if post.listCount > 0 {
            self.listCount.text = String( post.listCount)
        } else {
            self.listCount.text = ""
        }
        
        if post.voteCount != 0 {
            self.voteCount.text = String( post.voteCount)
        } else {
            self.voteCount.text = ""
        }
        
        // Resizes bookmark label to fit new count
        bookmarkLabelConstraint?.constant = self.listCount.frame.size.width
//        self.layoutIfNeeded()
        
    }
    
    fileprivate func setupAttributedCaption(){
        
        guard let post = self.post else {return}
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d YYYY, h:mm a"
        let timeAgoDisplay = formatter.string(from: post.creationDate)
        
        let attributedText = NSAttributedString(string: timeAgoDisplay, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12),NSForegroundColorAttributeName: UIColor.gray])
        
        self.postDateLabel.attributedText = attributedText

        
//        let attributedText = NSMutableAttributedString(string: post.user.username, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
//
//        attributedText.append(NSAttributedString(string: " \(post.caption)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)]))
//
//        attributedText.append(NSAttributedString(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 4)]))
//        let timeAgoDisplay = post.creationDate.timeAgoDisplay()
//        attributedText.append(NSAttributedString(string: timeAgoDisplay, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12),NSForegroundColorAttributeName: UIColor.gray]))
//        self.captionLabel.attributedText = attributedText
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
    
    lazy var legitIcon: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "legit").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(openLegitList), for: .touchUpInside)
        return button
    }()
    
    func openLegitList(){
        print("Open Legit List")
    }
    
    // Non Rating Emoji Labels
    var nonRatingEmojiLabelArray:[UILabel] = []
    lazy var nonRatingEmojiLabel1 = UILabel()
    lazy var nonRatingEmojiLabel2 = UILabel()
    lazy var nonRatingEmojiLabel3 = UILabel()
    lazy var nonRatingEmojiLabel4 = UILabel()
    lazy var nonRatingEmojiLabel5 = UILabel()

    
    func setupEmojiLabels(){
        
        guard let post = post else {return}
        
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
//        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(locationTap))
//        uv.addGestureRecognizer(locationTapGesture)
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
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = UIColor.black
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let locationDistanceLabel: UILabel = {
        let label = UILabel()
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
    
    
    let captionView: SpringView = {
        let view = SpringView()
        view.layer.backgroundColor = UIColor.lightGray.cgColor.copy(alpha: 0.5)
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    let captionBubble: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textAlignment = NSTextAlignment.center
        label.numberOfLines = 0
        return label
    }()

    var starRatingLabel: RatingLabel?
    var starRatingLabelHeight: NSLayoutConstraint?
    
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
    
    // Extra Tags
    
    let extraTagView: UIView = {
        let uv = UIView()
        uv.backgroundColor = UIColor.clear
        return uv
    }()
    
    let extraTagFontSize: CGFloat = 13
    let extraTagViewHeightSize: CGFloat = 25
    var extraTagViewHeight:NSLayoutConstraint?
    
    var extraTagsNameArray: [String] = []
    var extraTagsIdArray: [String] = []
    var userTagsNameArray: [String] = []
    var userTagsIdArray: [String] = []
    var creatorTagsNameArray: [String] = []
    var creatorTagsIdArray: [String] = []
    
    var extraTagsArray:[UIButton] = []
    lazy var extraTagLabel1 = UIButton()
    lazy var extraTagLabel2 = UIButton()
    lazy var extraTagLabel3 = UIButton()
    lazy var extraTagLabel4 = UIButton()
    lazy var extraTagLabel5 = UIButton()
    lazy var extraTagLabel6 = UIButton()
    
    func extraTagselected(_ sender: UIButton){
        guard let post = post else {return}
        let listTag = sender.tag
        
        var selectedListName = self.extraTagsNameArray[listTag]
        var selectedListId = self.extraTagsIdArray[listTag]
        
        print("Selected Creator Tag: \(selectedListName), \(selectedListId)")
        delegate?.didTapExtraTag(tagName: selectedListName, tagId: selectedListId, post: post)
    }
    
    
    func setupExtraTags() {

        // Refresh Tags
        extraTagsNameArray.removeAll()
        extraTagsIdArray.removeAll()
        userTagsNameArray.removeAll()
        userTagsIdArray.removeAll()
        creatorTagsNameArray.removeAll()
        creatorTagsIdArray.removeAll()
        
    // Reset Extra Tags
        extraTagsArray = [extraTagLabel1, extraTagLabel2, extraTagLabel3, extraTagLabel4,extraTagLabel5,extraTagLabel6]
        
        for label in self.extraTagsArray {
            label.setTitle(nil, for: .normal)
            label.setImage(nil, for: .normal)
            label.layer.borderWidth = 0
            label.removeFromSuperview()
        }
        
        
    // User Created Tags
        
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
                    } else if userTagsNameArray.count == 1 && userListCount! == 2{
                        userTagsNameArray.append(list.value)
                        userTagsIdArray.append(list.key)
                    } else if userTagsNameArray.count == 1 && userListCount! > 2{
                        userTagsNameArray.append("\(userListCount! - 1)")
                        userTagsIdArray.append("userLists")
                    }
                }
            }
            
            // Add User Tags to Extra Tags
            extraTagsNameArray = userTagsNameArray
            extraTagsIdArray = userTagsIdArray
            
        }
        
        
        
    // Creator Created Tags
        if post?.creatorListId != nil {
            var listCount = post?.creatorListId?.count
            
            // Add Legit List
            for list in (post?.creatorListId)! {
                if list.value == legitListName {
                    creatorTagsNameArray.append(list.value)
                    creatorTagsIdArray.append(list.key)
                }
            }
            
            // Add Other List
            for list in (post?.creatorListId)! {
                if list.value != legitListName && list.value != bookmarkListName {
                    if creatorTagsNameArray.count < 2 {
                        creatorTagsNameArray.append(list.value)
                        creatorTagsIdArray.append(list.key)
                    } else if creatorTagsNameArray.count == 2 && listCount! == 3 {
                        creatorTagsNameArray.append(list.value)
                        creatorTagsIdArray.append(list.key)
                    } else if creatorTagsNameArray.count == 2 && listCount! > 3 {
                        creatorTagsNameArray.append("\(listCount! - 2)")
                        creatorTagsIdArray.append("creatorLists")
                    }
                }
            }
        }
        
    // Creator Price Tag
        if post?.price != nil {
            creatorTagsNameArray.append((post?.price)!)
            creatorTagsIdArray.append("price")
        }
        
        extraTagsNameArray = extraTagsNameArray + creatorTagsNameArray
        extraTagsIdArray = extraTagsIdArray + creatorTagsIdArray
        


        // Creator Tag Button Label
        if extraTagsNameArray.count > 0 {
            for (index, listName) in (self.extraTagsNameArray.enumerated()) {
                
                extraTagsArray[index].tag = index
                extraTagsArray[index].setTitle(extraTagsNameArray[index], for: .normal)
                extraTagsArray[index].titleLabel?.font = UIFont.boldSystemFont(ofSize: extraTagFontSize)
                extraTagsArray[index].titleLabel?.textAlignment = NSTextAlignment.center
                extraTagsArray[index].layer.borderWidth = 1
                extraTagsArray[index].layer.backgroundColor = UIColor.white.cgColor
                extraTagsArray[index].layer.borderColor = UIColor.white.cgColor
                extraTagsArray[index].layer.cornerRadius = 5
                extraTagsArray[index].layer.masksToBounds = true
                extraTagsArray[index].contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
                extraTagsArray[index].addTarget(self, action: #selector(extraTagselected(_:)), for: .touchUpInside)

                
                if extraTagsNameArray[index] == bookmarkListName {
                    extraTagsArray[index].setImage(#imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal), for: .normal)
                    extraTagsArray[index].setTitle(nil, for: .normal)
                    extraTagsArray[index].setTitleColor(UIColor.white, for: .normal)
                    extraTagsArray[index].layer.backgroundColor = UIColor.white.cgColor
                }
                    
                else if extraTagsNameArray[index] == legitListName {
                    extraTagsArray[index].setTitleColor(UIColor.white, for: .normal)
                    extraTagsArray[index].setImage(#imageLiteral(resourceName: "legit").withRenderingMode(.alwaysOriginal), for: .normal)
                    extraTagsArray[index].layer.backgroundColor = UIColor.legitColor().cgColor
                }

                else if extraTagsIdArray[index] == "price" {
                    extraTagsArray[index].setTitleColor(UIColor.white, for: .normal)
                    extraTagsArray[index].layer.backgroundColor = UIColor.legitColor().cgColor
                }
                    
                else {
                    if index < userTagsNameArray.count {
                        // User Tags
                        extraTagsArray[index].setTitle(extraTagsNameArray[index].truncate(length: 10) + "!", for: .normal)
                        extraTagsArray[index].setTitleColor(UIColor.white, for: .normal)
                        extraTagsArray[index].layer.backgroundColor = UIColor(hexColor: "FE5F55").cgColor
                    } else {
                        // Creator Tags
                        extraTagsArray[index].setTitle(extraTagsNameArray[index].truncate(length: 10) + "!", for: .normal)
                        extraTagsArray[index].setTitleColor(UIColor.white, for: .normal)
                        extraTagsArray[index].layer.backgroundColor = UIColor.legitColor().cgColor
                    }
                }
                
                extraTagsArray[index].layer.borderWidth = 1

        // Add Tags to View
                let displayButton = extraTagsArray[index]
                self.addSubview(displayButton)
                
                if index == 0{
                    displayButton.anchor(top: extraTagView.topAnchor, left: extraTagView.leftAnchor, bottom: extraTagView.bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 10, paddingBottom: 1, paddingRight: 0, width: 0, height: 0)
                } else {
                    displayButton.anchor(top: extraTagView.topAnchor, left: extraTagsArray[index - 1].rightAnchor, bottom: extraTagView.bottomAnchor, right: nil, paddingTop: 1, paddingLeft: 6, paddingBottom: 1, paddingRight: 0, width: 0, height: 0)
                }
            }
        }
        
        if extraTagsNameArray.count == 0 {
            extraTagViewHeight?.constant = 0
        } else {
            extraTagViewHeight?.constant = extraTagViewHeightSize
        }
    }
    
    func setupLegitIcon(){
        
        self.legitIcon.isHidden = false

        if extraTagsNameArray.contains(legitListName){
            // Check for Legit
            self.legitIcon.setImage(#imageLiteral(resourceName: "legit_icon").withRenderingMode(.alwaysOriginal), for: .normal)
            self.legitIcon.contentMode = .scaleAspectFit
        }
        
        else if extraTagsNameArray.contains(bookmarkListName){
            // Check for Legit
//            self.legitIcon.setImage(#imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal), for: .normal)
        }
    
        else if (post?.rating) != nil && post?.rating != 0 {
            guard let postRating = self.post?.rating else {return}
            if postRating >= 6.0 {
                self.legitIcon.setImage(#imageLiteral(resourceName: "starfilled").withRenderingMode(.alwaysOriginal), for: .normal)
            }
            else if postRating <= 2.0 {
                self.legitIcon.setImage(#imageLiteral(resourceName: "lowrating").withRenderingMode(.alwaysOriginal), for: .normal)
            }
        } else {
            self.legitIcon.isHidden = true
        }
       
        //Override
        self.legitIcon.isHidden = true

    }
 
    func displayCaptionBubble(){
        
//        print(self.post)
        
        guard let post = self.post else {return}
        
        let attributedString = NSMutableAttributedString(string: post.caption, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 30)])
        
        let rating = NSAttributedString(string: String(describing: post.rating!), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 30), NSForegroundColorAttributeName: RatingColors.ratingColor(rating: post.rating)])
        
        if post.rating! > 0 {
            attributedString.append(rating)
        }
        
        captionBubble.attributedText = attributedString
        captionBubble.sizeToFit()
        
        if (captionBubble.attributedText?.length)! > 1 {
        
        self.addSubview(captionView)
        captionView.anchor(top: photoImageView.topAnchor, left: photoImageView.leftAnchor, bottom: nil, right: photoImageView.rightAnchor, paddingTop: 30, paddingLeft: 30, paddingBottom: 0, paddingRight: 30, width: 0, height: 0)
        
        captionView.addSubview(captionBubble)
        captionBubble.anchor(top: captionView.topAnchor, left: captionView.leftAnchor, bottom: captionView.bottomAnchor, right: captionView.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10, width: 0, height: 0)

        
        captionView.force = 0.5
        captionView.duration = 0.5
        captionView.animation = "zoomIn"
        captionView.curve = "spring"
        
        // Display only if there is caption
        
            captionView.animateNext {
                self.captionView.animation = "fadeOut"
                self.captionView.delay = 3
                self.captionView.animate()
            }
        }
    }
    
    func hideCaptionBubble(){
        
        self.captionView.removeFromSuperview()

    }

    func fadeViewInThenOut(inputView : UIView, delay: TimeInterval) {
        
        inputView.alpha = 1
        inputView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)

        let animationDuration = 0.0
        
        // Fade in the view
        UIView.animate(withDuration: animationDuration,delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak inputView] in
                    
                       inputView?.transform = .identity

        }) { (Bool) -> Void in
            
            // After the animation completes, fade out the view after a delay
            
            UIView.animate(withDuration: animationDuration, delay: delay, options: .curveEaseInOut, animations: { () -> Void in
                inputView.alpha = 0
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
        addSubview(bookmarkButton)
//        addSubview(starRatingLabel)
        addSubview(legitIcon)
        
        headerView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)

// Setup Non Rating Emojis
        
        nonRatingEmojiLabelArray = [nonRatingEmojiLabel1, nonRatingEmojiLabel2, nonRatingEmojiLabel3, nonRatingEmojiLabel4, nonRatingEmojiLabel5]
        
        for (index,label) in nonRatingEmojiLabelArray.enumerated(){
            
            label.tag = index
            label.text = "Emojis"
            label.font = UIFont.boldSystemFont(ofSize: 25)
            label.textAlignment = NSTextAlignment.right
            label.backgroundColor = UIColor.clear
            label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(nonRatingEmojiSelected(_:))))
            label.isUserInteractionEnabled = true
            
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
        
        addSubview(locationDistanceLabel)
        locationDistanceLabel.anchor(top: nil, left: nil, bottom: userProfileImageView.bottomAnchor, right: userProfileImageView.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 2, paddingRight: 8, width: 0, height: 0)
        locationDistanceLabel.sizeToFit()
        
        usernameLabel.anchor(top: userProfileImageView.topAnchor, left: nil, bottom: locationDistanceLabel.topAnchor, right: userProfileImageView.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        
        usernameLabel.textAlignment = .right

        legitIcon.anchor(top: nil, left: nil, bottom: nil, right: usernameLabel.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 2, width: 25, height: 25)
        legitIcon.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor).isActive = true
        legitIcon.isHidden = true
        

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

        addSubview(actionBar)
        actionBar.anchor(top: photoImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)

        setupActionButtons()


        // Location View
        
        addSubview(locationView)
        locationView.anchor(top: actionBar.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 25)
        //        locationView.backgroundColor = UIColor.yellow
        
        addSubview(locationLabel)
        locationLabel.anchor(top: locationView.topAnchor, left: leftAnchor, bottom: locationView.bottomAnchor, right: nil, paddingTop: 3, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(locationTap))
        locationLabel.addGestureRecognizer(locationTapGesture)
        

        
//        Setup Extra Tags

        addSubview(extraTagView)
        extraTagView.anchor(top: locationView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        extraTagViewHeight = NSLayoutConstraint(item: extraTagView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1, constant: extraTagViewHeightSize)
        extraTagViewHeight?.isActive = true
        extraTagsArray = [extraTagLabel1, extraTagLabel2, extraTagLabel3, extraTagLabel4,extraTagLabel5,extraTagLabel6]
        
        addSubview(postDateLabel)
        postDateLabel.anchor(top: extraTagView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 20)
        
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
//        button.setImage(#imageLiteral(resourceName: "message").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage(#imageLiteral(resourceName: "send2").withRenderingMode(.alwaysOriginal), for: .normal)

        button.addTarget(self, action: #selector(handleMessage), for: .touchUpInside)
        return button
        
    }()
    
    func handleMessage(){
        guard let post = post else {return}
        delegate?.didTapMessage(post: post)
        
    }

    
    let listCount: UILabel = {
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
        
        Database.handleVote(post: post, creatorUid: creatorId, vote: 1) {
            
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
        
        Database.handleVote(post: post, creatorUid: creatorId, vote: -1) {
            
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
        
        upVoteButton.anchor(top: voteView.topAnchor, left: nil, bottom: voteView.bottomAnchor, right: voteView.rightAnchor, paddingTop: 5, paddingLeft: 0, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        upVoteButton.widthAnchor.constraint(equalTo: upVoteButton.heightAnchor, multiplier: 1).isActive = true
        
        downVoteButton.anchor(top: voteView.topAnchor, left: voteView.leftAnchor, bottom: voteView.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 0, height: 0)
        downVoteButton.widthAnchor.constraint(equalTo: downVoteButton.heightAnchor, multiplier: 1).isActive = true

        voteCount.anchor(top: voteView.topAnchor, left: downVoteButton.rightAnchor, bottom: voteView.bottomAnchor, right: upVoteButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
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
        bookmarkContainer.addSubview(listCount)
        
        bookmarkButton.anchor(top: bookmarkContainer.topAnchor, left: bookmarkContainer.leftAnchor, bottom: bookmarkContainer.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        bookmarkButton.widthAnchor.constraint(equalTo: bookmarkButton.heightAnchor, multiplier: 1).isActive = true
        
        listCount.anchor(top: bookmarkContainer.topAnchor, left: bookmarkButton.rightAnchor, bottom: bookmarkContainer.bottomAnchor, right: bookmarkContainer.rightAnchor, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listCount.centerYAnchor.constraint(equalTo: bookmarkButton.centerYAnchor).isActive = true
        
        listCount.sizeToFit()
        
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


