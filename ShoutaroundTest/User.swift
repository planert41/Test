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
    var isFollowing: Bool? = false
    
    //Social Data
    var postCount: Int = 0
    var followingCount: Int = 0
    var followerCount: Int = 0
    var bookmarkCount: Int = 0
    var bookmarkedCount: Int = 0
    var likedCount: Int = 0
    
    
    init(uid: String, dictionary: [String:Any]) {
        self.username = dictionary["username"] as? String ?? ""
        self.profileImageUrl = dictionary["profileImageUrl"] as? String ?? ""
        self.uid = uid
        self.status = dictionary["status"] as? String ?? ""
        
        let social = dictionary["social"] as? [String:Int] ?? [:]
        self.postCount = social["postCount"] as? Int ?? 0
        self.followingCount = social["followingCount"] as? Int ?? 0
        self.followerCount = social["followerCount"] as? Int ?? 0
        self.bookmarkCount = social["bookmarkCount"] as? Int ?? 0
        self.bookmarkedCount = social["bookmarkedCount"] as? Int ?? 0
        self.likedCount = social["likedCount"] as? Int ?? 0
    }
    
}

struct CurrentUser {
    
    static var username: String?
    static var profileImageUrl: String?
    static var uid : String?
    static var currentLocation: CLLocation?
    static var status: String?
    static var followingUids: [String] = []
    static var groupUids: [String] = []
    static var user: User?
    
    //static var currentLocation: CLLocation? = CLLocation(latitude: 41.9735039, longitude: -87.66775139999999)
    
}
