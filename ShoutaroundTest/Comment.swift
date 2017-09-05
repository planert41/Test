//
//  Comment.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 9/3/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation

struct Comment {
    
    let text: String
    let uid: String
    var user: User
    
    init(user:User, dictionary: [String:Any]) {
        self.user = user
        self.text = dictionary["text"] as? String ?? ""
        self.uid = dictionary["uid"] as? String ?? ""
    }
}
