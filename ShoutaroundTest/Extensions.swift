//
//  Extensions.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/24/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase

extension UIColor {
    
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
    
    static func mainBlue() -> UIColor {
        return UIColor.rgb(red: 17, green: 154, blue: 237)
    }
    
}

extension UIView{
    
    func anchor(top: NSLayoutYAxisAnchor?, left:NSLayoutXAxisAnchor?, bottom:NSLayoutYAxisAnchor?, right:NSLayoutXAxisAnchor?,  paddingTop: CGFloat, paddingLeft: CGFloat, paddingBottom: CGFloat, paddingRight:CGFloat , width: CGFloat, height: CGFloat) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        
        if let top = top {
            
            self.topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
            
        }
        
        if let left = left {
            
            self.leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
            
        }
        
        if let bottom = bottom {
            
            self.bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
            
        }
        
        
        if let right = right {
            
            self.rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
            
        }
        
        if width != 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
            
        }
        
        if height != 0 {
            heightAnchor.constraint(equalToConstant: height).isActive = true
            
        }
        
        
    }
    
    
}

extension Date {
    func timeAgoDisplay() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        let month = 4 * week
        
        let quotient: Int
        let unit: String
        if secondsAgo < minute {
            quotient = secondsAgo
            unit = "second"
        } else if secondsAgo < hour {
            quotient = secondsAgo / minute
            unit = "min"
        } else if secondsAgo < day {
            quotient = secondsAgo / hour
            unit = "hour"
        } else if secondsAgo < week {
            quotient = secondsAgo / day
            unit = "day"
        } else if secondsAgo < month {
            quotient = secondsAgo / week
            unit = "week"
        } else {
            quotient = secondsAgo / month
            unit = "month"
        }
        
        return "\(quotient) \(unit)\(quotient == 1 ? "" : "s") ago"
        
    }
}

extension Dictionary where Value: Equatable {
    func key(forValue value: Value) -> Key? {
        return first { $0.1 == value }?.0
    }
}


extension String {
    /**
     Truncates the string to the specified length number of characters and appends an optional trailing string if longer.
     
     - Parameter length: A `String`.
     - Parameter trailing: A `String` that will be appended after the truncation.
     
     - Returns: A `String` object.
     */
    func truncate(length: Int, trailing: String = "…") -> String {
        if self.characters.count > length {
            return String(self.characters.prefix(length)) + trailing
        } else {
            return self
        }
    }
    
            func removingWhitespaces() -> String {
            return components(separatedBy: .whitespaces).joined()
        }
    
}

extension Int {
    func format(f: String) -> String {
        return String(format: "%\(f)d", self)
    }
}

extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}


extension UICollectionViewController {
    
    func fetchCurrentUser() {
        
        // uid using userID if exist, if not, uses current user, if not uses blank
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        //        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        
        Database.fetchUserWithUID(uid: uid) { (user) in
            
            CurrentUser.uid = uid
            CurrentUser.username = user.username
            CurrentUser.profileImageUrl = user.profileImageUrl
            print(CurrentUser())
            
        }
        
    }
    
}

extension UIViewController {
    
    func alert(message: String) {
        
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
}



class PaddedTextField: UITextField {
    
    let padding = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 15);
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
}

class PaddedUILabel: UILabel {
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 15)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
}



