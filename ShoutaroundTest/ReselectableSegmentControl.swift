//
//  ReselectableSegmentControl.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/22/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

class ReselectableSegmentedControl: UISegmentedControl {
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let previousSelectedSegmentIndex = self.selectedSegmentIndex
        
        super.touchesEnded(touches, with: event)
        
        if previousSelectedSegmentIndex == self.selectedSegmentIndex {
            let touch = touches.first!
            let touchLocation = touch.location(in: self)
            if bounds.contains(touchLocation) {
                self.sendActions(for: .valueChanged)
            }
        }
    }
    
    
}
