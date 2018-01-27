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
    var posts_created: Int = 0
    var followingCount: Int = 0
    var followersCount: Int = 0
    var votes_received: Int = 0
    var lists_created: Int = 0


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
        self.posts_created = social["posts_created"] as? Int ?? 0
        self.followingCount = social["followingCount"] as? Int ?? 0
        self.followersCount = social["followersCount"] as? Int ?? 0
        self.votes_received = social["votes_received"] as? Int ?? 0
        self.lists_created = social["lists_created"] as? Int ?? 0
    }
    
}

struct CurrentUser {

    // From User Database
    static var username: String?
    static var profileImageUrl: String?
    static var uid : String?
    static var status: String?

    // From Other Database Sources
    static var currentLocation: CLLocation?
    static var followingUids: [String] = []
    static var followerUids: [String] = []
    static var groupUids: [String] = []
    
    static var listIds: [String] = []
    static var lists: [List] = []
    //static var currentLocation: CLLocation? = CLLocation(latitude: 41.9735039, longitude: -87.66775139999999)
    
    // Inbox
    static var inboxThreads: [MessageThread] = []
    
    
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
    
    static func addPostToList(postId: String?, listId: String?){
        guard let postId = postId else {
            print("Add Post To List: ERROR, No Post ID")
            return
        }
        
        guard let listId = listId else {
            print("Add Post To List: ERROR, No List ID")
            return
        }
        
        guard let listIndex = self.lists.index(where: { (list) -> Bool in
            list.id == listId
        }) else {
            print("Add Post To List: ERROR, Can't Find List \(listId) in Current User ListIDs")
            return
        }
        
        var tempList = self.lists[listIndex]
        let createdDate = Date().timeIntervalSince1970

        
        tempList.postIds![postId] = createdDate
        
        // Replace Current User List with updated Post Ids
        self.lists[listIndex] = tempList
        print("Add Post To List: SUCCESS, Added Post: \(postId) to List: \(listId)")

    }
    
    static func removeList(list: List){
        guard let listId = list.id else {
            print("CurrentUser Remove List: ERROR: No List ID")
            return
        }
        self.lists.remove(at: (self.lists.index(where:{$0.id == listId}))!)
        self.listIds.remove(at: (self.listIds.index(where:{$0 == listId}))!)
    }
    
    static func removePostToList(postId: String?, listId: String?){
        guard let postId = postId else {
            print("Remove Post To List: ERROR, No Post ID")
            return
        }
        
        guard let listId = listId else {
            print("Remove Post To List: ERROR, No List ID")
            return
        }
        
        guard let listIndex = self.lists.index(where: { (list) -> Bool in
            list.id == listId
        }) else {
            print("Remove Post To List: ERROR, Can't Find List \(listId) in Current User ListIDs")
            return
        }
        
        self.lists.remove(at: listIndex)
        print("Remove Post To List: SUCCESS, Removed Post: \(postId) to List: \(listId)")
        
    }
    
    
    
    
    
    static func printProperties(){
        let currentUserProperties = Mirror(reflecting: self)
        let properties = currentUserProperties.children
        
        for property in properties {
            print("\(property.label!) = \(property.value)")
        }
    }

    
}
