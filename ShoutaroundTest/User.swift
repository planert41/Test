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
    // Keep empty set so that arrays can be easily appended instead of handling null
    var listIds: [String] = []
    
    var isFollowing: Bool? = false
    var status: String?
    
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
        
        //lists
        let lists = dictionary["lists"] as? [String:Any] ?? [:]
        for (listId, values) in lists {
            self.listIds.append(listId)
        }
        
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

    // From User Database
    static var username: String?
    static var profileImageUrl: String?
    static var uid : String?
    static var listIds: [String] = []
    static var status: String?

    // From Other Database Sources
    static var currentLocation: CLLocation?
    static var followingUids: [String] = []
    static var followerUids: [String] = []
    static var groupUids: [String] = []
    
    static var lists: [List] = []
    //static var currentLocation: CLLocation? = CLLocation(latitude: 41.9735039, longitude: -87.66775139999999)
    
    static var user: User? {
        didSet{
            self.username = user?.username
            self.uid = user?.uid
            self.profileImageUrl = user?.profileImageUrl
            self.listIds = (user?.listIds)!
        }
    }
    
    static func addList(list: List){
        guard let listId = list.id else {
            print("CurrentUser Add List: ERROR: No List ID")
            return
        }
        self.listIds.append(listId)
        self.lists.append(list)
    }
    
    static func removeList(list: List){
        guard let listId = list.id else {
            print("CurrentUser Remove List: ERROR: No List ID")
            return
        }
        self.lists.remove(at: (self.lists.index(where:{$0.id == listId}))!)
        self.listIds.remove(at: (self.listIds.index(where:{$0 == listId}))!)
    }
    
    static func printProperties(){
        let currentUserProperties = Mirror(reflecting: self)
        let properties = currentUserProperties.children
        
        for property in properties {
            print("\(property.label!) = \(property.value)")
        }
    }

    
}
