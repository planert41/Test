//
//  Post.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import CoreLocation

struct Post {
    
    let imageUrl: String
    let user: User
    let caption: String
    let emoji: String
    let creationDate: Date
    var id: String?
    var locationGPS: CLLocation?
    var locationName: String
    var locationAdress: String
    var locationGooglePlaceID: String?
    var distance: Double? = nil
    
    var hasLiked: Bool = false
    var hasBookmarked: Bool = false
    var creatorUID: String?
    
    
    init(user: User, dictionary: [String: Any]) {
        
        
        self.user = user
        
        // ?? "" gives default value
        self.imageUrl = dictionary["imageUrl"] as? String ?? ""
        self.caption = dictionary["caption"] as? String ?? ""
        self.emoji = dictionary["emoji"] as? String ?? ""
        
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
        self.locationName = dictionary["locationName"] as? String ?? ""
        self.locationAdress = dictionary["locationAdress"] as? String ?? ""
        self.locationGooglePlaceID = dictionary["googlePlaceID"] as? String ?? ""
        
        let locationGPSText = dictionary["postLocationGPS"] as? String ?? "0,0"
        let locationGPSTextArray = locationGPSText.components(separatedBy: ",")
        
        if locationGPSTextArray.count == 1 {
            self.locationGPS = nil
            self.distance = nil
        } else {
        self.locationGPS = CLLocation(latitude: Double(locationGPSTextArray[0])!, longitude: Double(locationGPSTextArray[1])!)
        
            if UserLocation.currentLocation != nil {
                self.distance = Double((self.locationGPS?.distance(from: UserLocation.currentLocation))!)
            }
        
        }
        


        

    
    }
    
    
    
}
