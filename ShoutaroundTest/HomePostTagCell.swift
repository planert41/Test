//
//  HomePostTagCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/6/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import UIKit

class HomePostTagCell: UICollectionViewCell {
    
    enum CellType {
        case list
        case price
        case type
        case none
    }

    var cellType = CellType.none


    
    
    let cellText: UILabel = {
        
        let iv = UILabel()
        iv.backgroundColor = .clear
        iv.font = UIFont.systemFont(ofSize: 15)
        
        return iv
    }()
    
    var cellInfo: String? = nil
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        switch cellType {
        case .list:
            backgroundColor = .blue
        case .price:
            backgroundColor = .green
        case .type:
            backgroundColor = .orange
        case .none:
            backgroundColor = .white
        }
        
        addSubview(cellText)
        cellText.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        layer.cornerRadius = 5
        layer.masksToBounds = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder error")
    }
    
}
