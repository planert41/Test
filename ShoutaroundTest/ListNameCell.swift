//
//  ListNameCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/10/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

class listNameCell: UICollectionViewCell {
    
    var labelFontSize: CGFloat = 12
    
    var listName: String? = nil {
        didSet{
            guard let listName = listName else {
                return
            }
            let imageSize = CGSize(width: labelFontSize, height: labelFontSize)
            let attributedText = NSMutableAttributedString()
            
            if listName == legitListName {
                
                let listImage = NSTextAttachment()
                listImage.image = #imageLiteral(resourceName: "legit").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
                let listImageString = NSAttributedString(attachment: listImage)
                attributedText.append(listImageString)
                
                let listNameString = NSMutableAttributedString(string: String(describing: listName), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize), NSForegroundColorAttributeName: UIColor.rgb(red: 255, green: 128, blue: 0)])
                
                attributedText.append(listNameString)
                listNameLabel.attributedText = attributedText
            }
                else if listName == bookmarkListName {
                let listImage = NSTextAttachment()
                listImage.image = #imageLiteral(resourceName: "bookmark_filled").withRenderingMode(.alwaysOriginal).resizeImageWith(newSize: imageSize)
                let listImageString = NSAttributedString(attachment: listImage)
                attributedText.append(listImageString)

                let listNameString = NSMutableAttributedString(string: String(describing: listName), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize), NSForegroundColorAttributeName: UIColor.rgb(red: 228, green: 27, blue: 27)])
                
                attributedText.append(listNameString)
                listNameLabel.attributedText = attributedText
            } else {
                
                let listNameString = NSMutableAttributedString(string: String(describing: listName), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: labelFontSize), NSForegroundColorAttributeName: UIColor.mainBlue()])
                listNameLabel.attributedText = listNameString
            }
        }
    }
    
    
    
    let listNameLabel: UILabel = {
        let iv = UILabel()
        iv.backgroundColor = .clear
        iv.textAlignment = NSTextAlignment.center
        return iv
    }()
    
    let sideDivider = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(listNameLabel)
        listNameLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        listNameLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        listNameLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        sideDivider.backgroundColor = UIColor.lightGray
        addSubview(sideDivider)
        sideDivider.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 1, height: 0)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
}
