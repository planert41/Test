//
//  Message.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/19/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import Firebase

struct Message {
    let postId: String
    let messageID: String
    let senderUID: String
    let senderMessage : String
    let creationDate: Date
    let senderUser: User?
    let sendPost: Post?
    
    
    init(uid: String, senderUser: User?, sendPost: Post?, dictionary: [String:Any]) {
        
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
        self.postId = dictionary["postUID"] as? String ?? ""
        self.senderUID = dictionary["senderUID"] as? String ?? ""
        self.senderMessage = dictionary["message"] as? String ?? ""
        self.messageID = uid as? String ?? ""
        self.senderUser = senderUser as? User ?? nil
        self.sendPost = sendPost as? Post ?? nil
    }
    
}

struct MessageThread {
    let threadID: String
    let creatorUID: String
    let postId: String
    var messageDictionaries: [String: Any]? = [:]
    var threadUsers: [String] = []
    var threadUserUids: [String] = []
    let creationDate: Date
    var lastCheckDate: Date? = nil
    
    init(threadID: String, dictionary: [String:Any]) {
        
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
        
        self.threadID = threadID as? String ?? ""
        self.creatorUID = dictionary["creatorUID"] as? String ?? ""
        self.postId = dictionary["postUID"] as? String ?? ""
        
        let fetchedUsers = dictionary["users"] as? [String: String] ?? [:]
        for (key,value) in fetchedUsers {
            self.threadUsers.append(value)
            self.threadUserUids.append(key)
        }
        
        // Set Messages
//        print("fetch Message Dic: ", dictionary["messages"])
        self.messageDictionaries = dictionary["messages"] as? [String:Any]
//        print("input Message Dic: ", messageDictionaries)
    }
}

struct MessageTest {
    let messageID: String
    let senderUID: String
    let message : String
    let creationDate: Date
    var senderUser: User? = nil
    
    init(messageID: String, dictionary: [String:Any]) {
        
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
        self.messageID = messageID as? String ?? ""
        self.senderUID = dictionary["creatorUID"] as? String ?? ""
        self.message = dictionary["message"] as? String ?? ""

    }
}
