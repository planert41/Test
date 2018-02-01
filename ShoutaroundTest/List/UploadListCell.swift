//
//  UploadListCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/24/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
//import SwiftIcons

class UploadListCell: UITableViewCell {

    var isLegit: Bool = false
    var isBookmark: Bool = false
    var isPublic: Bool = true
    var isListManage: Bool = false
    
    var list: List? {
        didSet{
//            self.listNameLabel.text = "\((list?.name)!) (\((list?.postIds?.count)!))"
            
            if self.list?.name == legitListName{
                self.isLegit = true
            } else {
                self.isLegit = false
            }
            
            if self.list?.name == bookmarkListName{
                self.isBookmark = true
            } else {
                self.isBookmark = false
            }
            
            if self.list?.publicList == 1{
                self.isPublic = true
            } else {
                self.isPublic = false
            }
        
            let attributedText = NSMutableAttributedString(string: (list?.name)!, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
            self.listNameLabel.attributedText = attributedText
            
            
            if (list?.postIds?.count)! > 0 {
                var textColor: UIColor = UIColor.legitColor()
                if self.isPublic {
                    textColor = UIColor.legitColor()
                } else {
                    textColor = UIColor(hex: "FF1654")
                }
                
                let attributedCount = NSMutableAttributedString(string: " \((list?.postIds?.count)!)", attributes: [NSFontAttributeName: UIFont(font: .noteworthyBold, size: 15), NSForegroundColorAttributeName: textColor])
                listPostCountLabel.attributedText = attributedCount
            }
        
        
        
        
        }
    }
    
    let listNameLabel: UILabel = {
        let label = UILabel()
        label.text = "List Name"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    let listPostCountLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        addSubview(listPostCountLabel)
        listPostCountLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 30, height: 0)
        
        addSubview(listNameLabel)
        listNameLabel.anchor(top: topAnchor, left: listPostCountLabel.rightAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        listNameLabel.sizeToFit()
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        if isListManage {
            if isLegit {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image = #imageLiteral(resourceName: "legit")
                accessoryView = imageView
            }
                
            else if isBookmark {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image = #imageLiteral(resourceName: "bookmark_filled")
                accessoryView = imageView
            }
            else if !isPublic {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image = #imageLiteral(resourceName: "private")
                accessoryView = imageView
            }
            else {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image =  nil
                accessoryView = imageView
            }
            backgroundColor = UIColor.white
        }
        else {
        // update UI
            if isLegit {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image = selected ? #imageLiteral(resourceName: "legit") : #imageLiteral(resourceName: "legit")
//                imageView.image = selected ? #imageLiteral(resourceName: "bookmark_selected") : #imageLiteral(resourceName: "bookmark_unselected")
                accessoryView = imageView
            }
            
            else if isBookmark {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image = selected ? #imageLiteral(resourceName: "bookmark_filled") : #imageLiteral(resourceName: "bookmark_filled")
                accessoryView = imageView
            }
            else if !isPublic {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image = selected ? #imageLiteral(resourceName: "private") : #imageLiteral(resourceName: "private_unfilled")
                accessoryView = imageView
            }
                
            else {
                var imageView : UIImageView
                imageView  = UIImageView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.image = selected ? #imageLiteral(resourceName: "checkmark") : nil
                accessoryView = imageView
            }
            backgroundColor = selected ? UIColor.legitColor().withAlphaComponent(0.5) : UIColor.white
        }
    }

}
