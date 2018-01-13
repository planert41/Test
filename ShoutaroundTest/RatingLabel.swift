//
//  RatingLabel.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/21/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

class RatingLabel: UILabel {

    var rating: Double = 0 {
        didSet{
            self.setRatingView()
        }
    }
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        self.layer.cornerRadius = self.frame.width/2
        self.layer.masksToBounds = true
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.darkGray.cgColor
        self.textAlignment = NSTextAlignment.center
        
        self.font = UIFont.systemFont(ofSize: 14)
        self.textColor = UIColor.darkGray
        setRatingView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        // decode clientName and time if you want
        super.init(coder: aDecoder)
    }
    
    func setRatingView(){
        let cellRating = self.rating
        
        if cellRating == 0 {
            self.text = "0"
            self.textColor = UIColor.darkGray
        } else {
            self.text = String(cellRating)
            self.textColor = UIColor.black
        }

        // Add image as background
//        var img: UIImage = #imageLiteral(resourceName: "7rating")
//        var imgSize: CGSize = self.frame.size
//        UIGraphicsBeginImageContext(imgSize)
//        img.draw(in: CGRect(x: 0, y: 0, width: imgSize.width, height: imgSize.height))
//        var newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
//        UIGraphicsEndImageContext();
//        self.backgroundColor = UIColor(patternImage: newImage).withAlphaComponent(0.5)

        
        if cellRating == 0 {
            self.backgroundColor = UIColor.white
        } else if cellRating <= Double(1) {
            self.backgroundColor = UIColor.rgb(red: 227, green: 27, blue: 35)
        } else if cellRating <= Double(2) {
            self.backgroundColor = UIColor.rgb(red: 227, green: 27, blue: 35).withAlphaComponent(0.55)
        } else if cellRating <= Double(3) {
            self.backgroundColor = UIColor.rgb(red: 255, green: 173, blue: 0).withAlphaComponent(0.55)
        } else if cellRating <= Double(4) {
            self.backgroundColor = UIColor.rgb(red: 255, green: 173, blue: 0)
        } else if cellRating <= Double(5) {
            self.backgroundColor = UIColor.rgb(red: 252, green: 227, blue: 0).withAlphaComponent(0.55)
        } else if cellRating <= Double(6) {
            self.backgroundColor = UIColor.rgb(red: 252, green: 227, blue: 0)
        } else if cellRating <= Double(7) {
            self.backgroundColor = UIColor.rgb(red: 91, green: 197, blue: 51)
        }
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}


class RatingStringLabel: UILabel {
    
    var rating: Double = 0 {
        didSet{
            self.setRatingView()
        }
    }
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        self.layer.cornerRadius = self.frame.width/2
        self.layer.masksToBounds = true
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.darkGray.cgColor
        self.textAlignment = NSTextAlignment.center
        
        self.font = UIFont.systemFont(ofSize: 14)
        self.textColor = UIColor.darkGray
        setRatingView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        // decode clientName and time if you want
        super.init(coder: aDecoder)
    }
    
    func setRatingView(){
        let cellRating = self.rating
        
        if cellRating == 0 {
            self.text = "0"
            self.textColor = UIColor.darkGray
        } else {
            self.text = String(cellRating)
            self.textColor = UIColor.black
        }
        
        // Add image as background
        //        var img: UIImage = #imageLiteral(resourceName: "7rating")
        //        var imgSize: CGSize = self.frame.size
        //        UIGraphicsBeginImageContext(imgSize)
        //        img.draw(in: CGRect(x: 0, y: 0, width: imgSize.width, height: imgSize.height))
        //        var newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        //        UIGraphicsEndImageContext();
        //        self.backgroundColor = UIColor(patternImage: newImage).withAlphaComponent(0.5)
        
        
        if cellRating == 0 {
            self.backgroundColor = UIColor.white
        } else if cellRating <= Double(1) {
            self.backgroundColor = UIColor.rgb(red: 227, green: 27, blue: 35)
        } else if cellRating <= Double(2) {
            self.backgroundColor = UIColor.rgb(red: 227, green: 27, blue: 35).withAlphaComponent(0.55)
        } else if cellRating <= Double(3) {
            self.backgroundColor = UIColor.rgb(red: 255, green: 173, blue: 0).withAlphaComponent(0.55)
        } else if cellRating <= Double(4) {
            self.backgroundColor = UIColor.rgb(red: 255, green: 173, blue: 0)
        } else if cellRating <= Double(5) {
            self.backgroundColor = UIColor.rgb(red: 252, green: 227, blue: 0).withAlphaComponent(0.55)
        } else if cellRating <= Double(6) {
            self.backgroundColor = UIColor.rgb(red: 252, green: 227, blue: 0)
        } else if cellRating <= Double(7) {
            self.backgroundColor = UIColor.rgb(red: 91, green: 197, blue: 51)
        }
    }
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
}

