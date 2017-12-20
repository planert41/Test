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
    
    func isEmptyOrWhitespace() -> Bool {
        
        if(self.isEmpty) {
            return true
        }
        
        return (self.trimmingCharacters(in: .whitespaces).isEmpty)
    }    
    
    
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
    
    var removeDuplicates: String {
        var set = Set<Character>()
        return String(characters.filter{ set.insert($0).inserted })
    }
    
    func indicesOf(string: String) -> [Int] {
        var indices = [Int]()
        var searchStartIndex = self.startIndex

        while searchStartIndex < self.endIndex,
            let range = self.range(of: string, range: searchStartIndex..<self.endIndex),
            !range.isEmpty
        {
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }

        return indices
    }
    
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return self[Range(start ..< end)]
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
    
    func alert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func alertClose(gesture: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
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
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
}

class RightButtonPaddedUILabel: UILabel {
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top: 0, left: 10, bottom: 0, right: 30)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
}

extension UIImage{
    
    func resizeImageWith(newSize: CGSize) -> UIImage {
        
        let horizontalRatio = newSize.width / size.width
        let verticalRatio = newSize.height / size.height
        
        let ratio = max(horizontalRatio, verticalRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
        draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        
        UIColor.clear.setFill()
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    
}

