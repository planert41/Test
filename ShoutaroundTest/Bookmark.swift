//
//  Bookmark.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 11/1/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation

struct Bookmark {
    
    var bookmarkDate: Date
    var post: Post
    var bookmarkCreatorUid: String
    
    init(bookmarkCreatorUid: String, fetchedDate: Double, post: Post) {
        self.bookmarkDate = Date(timeIntervalSince1970: fetchedDate)
        self.post = post
        self.bookmarkCreatorUid = bookmarkCreatorUid
    }
}
