//
//  UploadListCell.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/24/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

class UploadListCell: UITableViewCell {

    var list: List? {
        didSet{
            self.listNameLabel.text = list?.name
        }
    }
    
    let listNameLabel: UILabel = {
        let label = UILabel()
        label.text = "List Name"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        addSubview(listNameLabel)
        listNameLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
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
        
        // update UI
        accessoryType = selected ? .checkmark : .none
        backgroundColor = selected ? UIColor.mainBlue() : UIColor.white
    }

}
