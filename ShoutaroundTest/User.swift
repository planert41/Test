//
//  User.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/30/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import CoreLocation

struct User {
    let username: String
    let profileImageUrl: String
    let uid : String
    let status: String?
    
    init(uid: String, dictionary: [String:Any]) {
        self.username = dictionary["username"] as? String ?? ""
        self.profileImageUrl = dictionary["profileImageUrl"] as? String ?? ""
        self.uid = uid
        self.status = dictionary["status"] as? String ?? ""
    }
    
}

struct CurrentUser {
    
    static var username: String?
    static var profileImageUrl: String?
    static var uid : String?
    static var currentLocation: CLLocation?
    static var status: String?
    
    //static var currentLocation: CLLocation? = CLLocation(latitude: 41.9735039, longitude: -87.66775139999999)
    
}
