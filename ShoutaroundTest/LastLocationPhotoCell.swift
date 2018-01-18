//
//  LastLocationPhotoCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/17/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import UIKit


protocol LastLocationPhotoCellDelegate {
    func searchNearby()
    
}
class LastLocationPhotoCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    let button = UIButton()
    var delegate: LastLocationPhotoCellDelegate?
    var label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundView = UIImageView(image: #imageLiteral(resourceName: "button_background"))
        
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.numberOfLines = 0
        label.textAlignment = NSTextAlignment.center
        label.text = "Search Posts Nearby"
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
        
        addSubview(label)
        label.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
    }
    
    func didTap(){
        self.delegate?.searchNearby()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}
