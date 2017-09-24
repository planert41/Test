//
//  Firebase.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/30/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Firebase

extension Database{
    
    static func fetchUserWithUID(uid: String, completion: @escaping (User) -> ()) {
        
        print("Fetching uid", uid)
        
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let userDictionary = snapshot.value as? [String:Any] else {return}
            let user = User(uid:uid, dictionary: userDictionary)
            
            completion(user)
            
        }) {(err) in
            print("Failed to fetch user for posts:",err)
        }
    }
    
    
    static func fetchPostWithUIDAndPostID(creatoruid: String, postId: String, completion: @escaping (Post) -> ()) {
        

        Database.fetchUserWithUID(uid: creatoruid) { (user) in
            
            let ref = Database.database().reference().child("posts").child(user.uid).child(postId)
            
            ref.observeSingleEvent(of: .value, with: {(snapshot) in

            guard let dictionary = snapshot.value as? [String: Any] else {return}
                var post = Post(user: user, dictionary: dictionary)
                post.id = postId
                post.creatorUID = user.uid
                
                guard let uid = Auth.auth().currentUser?.uid else {return}
                
                Database.database().reference().child("likes").child(uid).child(postId).observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    if let value = snapshot.value as? Int, value == 1 {
                        post.hasLiked = true
                    } else {
                        post.hasLiked = false
                    }
                    
                    Database.database().reference().child("bookmarks").child(uid).child(postId).observeSingleEvent(of: .value, with: { (snapshot) in
                        
                        let dictionaries = snapshot.value as? [String: Any]
                        
                        if let value = dictionaries?["bookmarked"] as? Int, value == 1 {
                            post.hasBookmarked = true
                        } else {
                            post.hasBookmarked = false
                        }
                        
                        completion(post)
                        
                    }, withCancel: { (err) in
                        print("Failed to fetch bookmark info for post:", err)
                    })
                    
                }, withCancel: { (err) in
                    print("Failed to fetch like info for post:", err)
                })
            
        }) { (err) in print("Failed to fetchposts:", err) }
        
        }
    }

}
