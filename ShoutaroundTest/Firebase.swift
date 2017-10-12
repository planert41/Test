//
//  Firebase.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/30/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Firebase
import GeoFire


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
            
            let ref = Database.database().reference().child("posts").child(postId)
            
            ref.observeSingleEvent(of: .value, with: {(snapshot) in
                

            guard let dictionary = snapshot.value as? [String: Any] else {return}
                var post = Post(user: user, dictionary: dictionary)
                post.id = postId
                post.creatorUID = user.uid
                
                Database.checkPostForLikes(post: post, completion: { (post) in
                    Database.checkPostForBookmarks(post: post, completion: { (post) in
                        completion(post)
                    })
                })
                
//                Database.database().reference().child("likes").child(uid).child(postId).observeSingleEvent(of: .value, with: { (snapshot) in
//                    
//                    if let value = snapshot.value as? Int, value == 1 {
//                        post.hasLiked = true
//                    } else {
//                        post.hasLiked = false
//                    }
//                    
//                    Database.database().reference().child("bookmarks").child(uid).child(postId).observeSingleEvent(of: .value, with: { (snapshot) in
//                        
//                        let dictionaries = snapshot.value as? [String: Any]
//                        
//                        if let value = dictionaries?["bookmarked"] as? Int, value == 1 {
//                            post.hasBookmarked = true
//                        } else {
//                            post.hasBookmarked = false
//                        }
//                        
//                        completion(post)
//                        
//                    }, withCancel: { (err) in
//                        print("Failed to fetch bookmark info for post:", err)
//                    })
//                    
//                }, withCancel: { (err) in
//                    print("Failed to fetch like info for post:", err)
//                })
            
        }) { (err) in print("Failed to fetchposts:", err) }
        
        }
    }
    
    static func checkPostForLikes(post: Post, completion: @escaping (Post) -> ()){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        var tempPost = post
        
        Database.database().reference().child("likes").child(uid).child(post.id!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let value = snapshot.value as? Int, value == 1 {
                tempPost.hasLiked = true
            } else {
                tempPost.hasLiked = false
            }
            
            completion(tempPost)
        }, withCancel: { (err) in
            print("Failed to fetch bookmark info for post:", err)
        })
    }
    
    static func checkPostForBookmarks(post: Post, completion: @escaping (Post) -> ()){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        var tempPost = post
        Database.database().reference().child("bookmarks").child(uid).child(post.id!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let dictionaries = snapshot.value as? [String: Any]
            
            if let value = dictionaries?["bookmarked"] as? Int, value == 1 {
                tempPost.hasBookmarked = true
            } else {
                tempPost.hasBookmarked = false
            }
            
            completion(tempPost)
        }, withCancel: { (err) in
            print("Failed to fetch like info for post:", err)
        })
    }
    
    static func checkPostForLikesAndBookmarks(post: Post, completion: @escaping (Post) -> ()){
    
    Database.checkPostForLikes(post: post) { (post) in
        Database.checkPostForBookmarks(post: post, completion: { (post) in
            completion(post)
        })
        }
    
    
    }
    
//    static func fetchAllPostIDWithUID(creatoruid: String, completion: @escaping ([String]) -> ()) {
//            let myGroup = DispatchGroup()
//            let ref = Database.database().reference().child("userposts").child(creatoruid)
//        
//            ref.observeSingleEvent(of: .value, with: {(snapshot) in
//            
//            guard let userposts = snapshot.value as? [String: Any] else {return}
//            var tempPostUIDs = [] as [String]
//            userposts.forEach({ (key,value) in
//                myGroup.enter()
//                tempPostUIDs.append(key)
//                myGroup.leave()
//                })
//                
//                myGroup.notify(queue: .main) {
//                    print(tempPostUIDs)
//                    completion(tempPostUIDs)
//                }
//            })
//        }
    
    static func fetchAllPostWithUID(creatoruid: String, completion: @escaping ([Post]) -> ()) {
        
        
        let myGroup = DispatchGroup()
        var fetchedPosts = [] as [Post]
        Database.fetchUserWithUID(uid: creatoruid) { (user) in
            
            let ref = Database.database().reference().child("userposts").child(user.uid)
            
            ref.observeSingleEvent(of: .value, with: {(snapshot) in
                
                guard let userposts = snapshot.value as? [String: Any] else {return}
                
                userposts.forEach({ (key,value) in
                    
                    myGroup.enter()
                    
                    //ƒ            print("Key \(key), Value: \(value)")
                    
                    print(user.uid, key)
                    Database.fetchPostWithUIDAndPostID(creatoruid: user.uid, postId: key, completion: { (post) in
                        
                    Database.checkPostForLikesAndBookmarks(post: post, completion: { (post) in
                        fetchedPosts.append(post)
                        fetchedPosts.sort(by: { (p1, p2) -> Bool in
                            return p1.creationDate.compare(p2.creationDate) == .orderedDescending })
                        myGroup.leave()
                        
                    })

                    })
                    
                })
                
                myGroup.notify(queue: .main) {
                    completion(fetchedPosts)
                }
                
            })
            { (err) in print("Failed to fetch user postids", err)}
        }
    }
    
    static func fetchAllPostWithGooglePlaceID(googlePlaceId: String, completion: @escaping ([Post]) -> ()) {
        
        let myGroup = DispatchGroup()
        
        var query = Database.database().reference().child("posts").queryOrdered(byChild: "googlePlaceID").queryEqual(toValue: googlePlaceId)
        
        var fetchedPosts = [] as [Post]
        
        query.observe(.value, with: { (snapshot) in
           
            guard let locationPosts = snapshot.value as? [String: Any] else {return}
            
            
            locationPosts.forEach({ (key,value) in
                
            myGroup.enter()

            guard let dictionary = value as? [String: Any] else {return}
            let creatorUID = dictionary["creatorUID"] as? String ?? ""
            
            Database.fetchUserWithUID(uid: creatorUID) { (user) in
            
            var post = Post(user: user, dictionary: dictionary)
            post.id = key
            

                Database.checkPostForLikesAndBookmarks(post: post, completion: { (post) in
                    fetchedPosts.append(post)
                    fetchedPosts.sort(by: { (p1, p2) -> Bool in
                        return p1.creationDate.compare(p2.creationDate) == .orderedDescending })
                    myGroup.leave()
                })
            }

            })
            
            myGroup.notify(queue: .main) {
                completion(fetchedPosts)
            }
            
            
        }) { (err) in
            print("Failed to fetch post for Google Place ID", err)
        }

    }
    
    static func fetchPostWithPostID( postId: String, completion: @escaping (Post) -> ()) {
        
        
            let ref = Database.database().reference().child("posts").child(postId)
            
            ref.observeSingleEvent(of: .value, with: {(snapshot) in
                
            guard let dictionary = snapshot.value as? [String: Any] else {return}
                let creatorUID = dictionary["creatorUID"] as? String ?? ""
                
                
                
           Database.fetchUserWithUID(uid: creatorUID, completion: { (user) in
            var post = Post(user: user, dictionary: dictionary)
            post.id = postId
            
           checkPostForLikesAndBookmarks(post: post, completion: { (post) in
                completion(post)
            })
           })
        })
    
    }
    
    static func fetchAllPostWithLocation(location: CLLocation, distance: Double, completion: @escaping ([Post]) -> ()) {

        let myGroup = DispatchGroup()
        let ref = Database.database().reference().child("postlocations")
        let geoFire = GeoFire(firebaseRef: ref)
        var fetchedPosts = [] as [Post]

        let circleQuery = geoFire?.query(at: location, withRadius: distance)
        
            myGroup.enter()
        circleQuery?.observe(.keyEntered, with: { (key, location) in
            print(key)

            myGroup.enter()
            Database.fetchPostWithPostID(postId: key!, completion: { (post) in
                print(post)
                fetchedPosts.append(post)
                myGroup.leave()
            })
            
        })
        
        circleQuery?.observeReady({
                myGroup.leave()
        })
        
        
        myGroup.notify(queue: .main) {
            fetchedPosts.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
            })
            completion(fetchedPosts)
        }

    }

}
