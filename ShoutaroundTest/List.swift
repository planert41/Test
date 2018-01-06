//
//  List.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/5/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Firebase


struct List {
    var id: String? = nil
    var name: String
    var creationDate: Date = Date()
    var postIds: [String:Any]? = [:]
    var isSelected: Bool = false
    var creatorUID: String?
    
    init(id: String?, name: String){
        self.id = id
        self.name = name
        self.creationDate = Date()
        self.creatorUID = Auth.auth().currentUser?.uid
    }
    
    init(id: String?, dictionary: [String: Any]){
        self.id = id
        self.name = dictionary["name"] as? String ?? ""
        let fetchedDate = dictionary["createdDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: fetchedDate)
        self.postIds = dictionary["posts"] as? [String:Any] ?? [:]
        self.creatorUID = dictionary["creatorUID"] as? String ?? ""
    }
    
}

