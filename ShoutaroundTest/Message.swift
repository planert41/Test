//
//  Message.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/19/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
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
