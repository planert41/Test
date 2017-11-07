//
//  LocationLabels.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/17/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

class LocationLabel: UILabel {
    
    override func drawText(in rect: CGRect) {
        let insets: UIEdgeInsets = UIEdgeInsets(top: 0  , left: 10, bottom: 0, right: 5)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
}
