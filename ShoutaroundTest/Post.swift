//
//  Post.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import Firebase

struct PostId {
    
    var id: String
    var creatorUID: String?
    var creationDate: Date?
    var distance: Double? = 99999999
    var postGPS: String? = nil
    var tagTime: Date?
    var emoji: String?
    var likeCount: Int?
    var bookmarkCount: Int?
    var messageCount: Int?
    var sort: Double?
    
    init(id: String, creatorUID: String, fetchedTagTime: Double, fetchedDate: Double, distance: Double?, postGPS: String?, postEmoji: String?) {
        
        self.id = id
        self.creatorUID = creatorUID
        self.creationDate = Date(timeIntervalSince1970: fetchedDate)
        self.tagTime = Date(timeIntervalSince1970: fetchedTagTime)
        self.postGPS = postGPS
        self.emoji = postEmoji
        
    }
}

struct Post {
    
    var image: UIImage?
    var imageUrl: String
    let user: User
    let caption: String
    let creationDate: Date
    var id: String?
    var locationGPS: CLLocation?
    var imageGPS: CLLocation?

    var locationName: String
    var locationAdress: String
    var locationGooglePlaceID: String?
    var distance: Double? = nil
    let tagTime: Date
    

    var creatorUID: String?
    var creatorListId: [String:String]?
    
    var selectedListId: [String:String]?

    var ratingEmoji: String?
    var emoji: String
    var nonRatingEmoji: [String]
    var nonRatingEmojiTags: [String]
    
    var rating: Double?
    var price: String?
    var type: String?
    
    //Social Stats
    var hasLiked: Bool = false
    var hasBookmarked: Bool = false
    var hasMessaged: Bool = false
    var likeCount: Int = 0
    var bookmarkCount:Int = 0
    var messageCount:Int = 0
    var voteCount:Int = 0
    var hasVoted:Int = 0
    
    
    init(user: User, dictionary: [String: Any]) {
        
        
        self.user = user
        
        // ?? "" gives default value
        self.imageUrl = dictionary["imageUrl"] as? String ?? ""
        self.caption = dictionary["caption"] as? String ?? ""
        
        self.rating = dictionary["rating"] as? Double ?? 0
        self.ratingEmoji = dictionary["ratingEmoji"] as? String ?? ""
        self.nonRatingEmoji = dictionary["nonratingEmoji"] as? [String] ?? []
        self.nonRatingEmojiTags = dictionary["nonratingEmojiTags"] as? [String] ?? []
        self.emoji = self.ratingEmoji! + (self.nonRatingEmoji.joined())
        
        let tagSecondsFrom1970 = dictionary["tagTime"] as? Double ?? 0
        self.tagTime = Date(timeIntervalSince1970: tagSecondsFrom1970)
        
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
        self.locationName = dictionary["locationName"] as? String ?? ""
        self.locationAdress = dictionary["locationAdress"] as? String ?? ""
        self.locationGooglePlaceID = dictionary["googlePlaceID"] as? String ?? ""
        self.creatorUID = dictionary["creatorUID"] as? String ?? ""
        
        self.creatorListId = dictionary["lists"] as? [String:String]? ?? nil
        
        if self.creatorUID == Auth.auth().currentUser?.uid {
            self.selectedListId = self.creatorListId
        }
        
        self.likeCount = dictionary["likeCount"] as? Int ?? 0
        self.bookmarkCount = dictionary["bookmarkCount"] as? Int ?? 0
        self.messageCount = dictionary["messageCount"] as? Int ?? 0
        self.voteCount = dictionary["voteCount"] as? Int ?? 0
        
        self.price = dictionary["price"] as? String ?? nil
        self.type = dictionary["type"] as? String ?? nil
        
        
        
        let locationGPSText = dictionary["postLocationGPS"] as? String ?? ""
        let locationGPSTextArray = locationGPSText.components(separatedBy: ",")
        
        if locationGPSTextArray.count == 1 {
            self.locationGPS = nil
            self.distance = nil
        } else {
        self.locationGPS = CLLocation(latitude: Double(locationGPSTextArray[0])!, longitude: Double(locationGPSTextArray[1])!)
        
            if CurrentUser.currentLocation != nil {
                self.distance = Double((self.locationGPS?.distance(from: CurrentUser.currentLocation!))!)
            }
        }
    
        let imageGPSText = dictionary["imageLocationGPS"] as? String ?? ""
        let imageGPSTextArray = imageGPSText.components(separatedBy: ",")
        
        if imageGPSTextArray.count == 1 {
            self.imageGPS = nil
        } else {
            self.imageGPS = CLLocation(latitude: Double(imageGPSTextArray[0])!, longitude: Double(imageGPSTextArray[1])!)
        }
    
    }
    
    func dictionary() -> [String:Any]{
        var createdTime = self.creationDate.timeIntervalSince1970
        
        var uploadedLocationGPSLatitude: String?
        var uploadedlocationGPSLongitude: String?
        var uploadedLocationGPS: String?
        
        if self.locationGPS == nil {
            uploadedLocationGPS = nil
        } else {
            uploadedLocationGPSLatitude = String(format: "%f", (self.locationGPS!.coordinate.latitude))
            uploadedlocationGPSLongitude = String(format: "%f", (self.locationGPS!.coordinate.longitude))
            uploadedLocationGPSLatitude = uploadedLocationGPSLatitude! + "," + uploadedlocationGPSLongitude!
        }
        
        var uploadedImageLocationGPSLatitude: String?
        var uploadedImageLocationGPSLongitude: String?
        var uploadedImageLocationGPS: String?

        if self.imageGPS == nil {
            uploadedImageLocationGPS = nil
        } else {
            uploadedImageLocationGPSLatitude = String(format: "%f", (self.imageGPS!.coordinate.latitude))
            uploadedImageLocationGPSLongitude = String(format: "%f", (self.imageGPS!.coordinate.longitude))
            uploadedImageLocationGPS = uploadedImageLocationGPSLatitude! + "," + uploadedImageLocationGPSLongitude!
        }
        
        let values = ["caption": self.caption,"rating": self.rating, "nonratingEmoji": self.nonRatingEmoji, "nonratingEmojiTags": self.nonRatingEmojiTags, "creationDate": createdTime, "googlePlaceID": self.locationGooglePlaceID, "locationName": self.locationName, "locationAdress": self.locationAdress, "postLocationGPS": uploadedLocationGPSLatitude, "imageLocationGPS": uploadedImageLocationGPS, "creatorUID": self.creatorUID, "price": self.price, "type": self.type, "lists": self.creatorListId] as [String:Any]
        
        return values
    }
    
    
    
}
