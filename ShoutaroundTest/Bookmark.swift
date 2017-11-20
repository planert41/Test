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
    
    init(bookmarkDate: Date, post: Post) {
        self.bookmarkDate = bookmarkDate
        self.post = post
    }
}


struct BookmarkId {
    var postId: String
    var bookmarkDate: Date
    
    init (postId: String, fetchedBookmarkDate: Double){
        self.postId = postId
        self.bookmarkDate = Date(timeIntervalSince1970: fetchedBookmarkDate)
    }
}

