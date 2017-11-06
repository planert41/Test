//
//  Firebase.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/30/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Firebase
import GeoFire

var postCache = [String: Post]()

extension Database{
    
    static func fetchUserWithUID(uid: String, completion: @escaping (User) -> ()) {
        
//        print("Fetching uid", uid)
        
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
    
    static func fetchUserWithUsername( username: String, completion: @escaping (User) -> ()) {
    
        let myGroup = DispatchGroup()
        
        var query = Database.database().reference().child("users").queryOrdered(byChild: "username").queryEqual(toValue: username)
        
        var user: User?
        
        query.observe(.value, with: { (snapshot) in
            
            guard let queryUsers = snapshot.value as? [String: Any] else {return}
            
            queryUsers.forEach({ (key,value) in
                
                myGroup.enter()
                guard let dictionary = value as? [String: Any] else {return}
              
                user = User(uid: key, dictionary: dictionary)
                myGroup.leave()

            })
            myGroup.notify(queue: .main) {
                completion(user!)
            }
        }) { (err) in
            print("Failed to fetch post for Google Place ID", err)
        }
        
        
    }
    
    static func fetchAllPostIDWithCreatorUID(creatoruid: String, completion: @escaping ([PostId]) -> ()) {
        
        let myGroup = DispatchGroup()
        var fetchedPostIds = [] as [PostId]
        
        let ref = Database.database().reference().child("userposts").child(creatoruid)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            guard let userposts = snapshot.value as? [String: Any] else {return}
            
            userposts.forEach({ (key,value) in
                
                myGroup.enter()
                
//                print("Key \(key), Value: \(value)")
                
                let dictionary = value as? [String: Any]
                let secondsFrom1970 = dictionary?["creationDate"] as? Double ?? 0
                
                let tempID = PostId.init(id: key, creatorUID: creatoruid, fetchedDate: secondsFrom1970, distance: nil, postGPS: nil)
                fetchedPostIds.append(tempID)
                
                myGroup.leave()
                
            })
            
            myGroup.notify(queue: .main) {
                completion(fetchedPostIds)
            }
        })
    }
    
    
    static func fetchAllBookmarksWithCreatorUID(creatoruid: String, completion: @escaping ([PostId]) -> ()) {
        
        let myGroup = DispatchGroup()
        var fetchedPostIds = [] as [PostId]
        var count = 0
        
        let ref = Database.database().reference().child("bookmarks").child(creatoruid)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            guard let bookmarks = snapshot.value as? [String: Any] else {return}
            
            bookmarks.forEach({ (key,value) in
                
                myGroup.enter()
                count += 1
                //                print("Key \(key), Value: \(value)")
                guard let dictionary = value as? [String: Any] else {return}
                if let value = dictionary["bookmarked"] as? Int, value == 1 {
                    
                    let bookmarkTime = dictionary["bookmarkTime"] as? Double ?? 0
                    // Substitute Post Id creation date with bookmark time
                    
                    Database.fetchPostIDDetails(postId: key, completion: { (fetchPostId) in
                        let tempID = PostId.init(id: fetchPostId.id, creatorUID: fetchPostId.creatorUID!, fetchedDate: bookmarkTime, distance: nil, postGPS: fetchPostId.postGPS)
                        fetchedPostIds.append(tempID)
                        myGroup.leave()
                        
                    })
                }
            })
            
            myGroup.notify(queue: .main) {
                completion(fetchedPostIds)
            }
        })
    }
    
    
    static func fetchAllPostWithUID(creatoruid: String, completion: @escaping ([Post]) -> ()) {
        
        
        let myGroup = DispatchGroup()
        var fetchedPosts = [] as [Post]
        Database.fetchUserWithUID(uid: creatoruid) { (user) in
            
            let ref = Database.database().reference().child("userposts").child(user.uid)
            
            ref.observeSingleEvent(of: .value, with: {(snapshot) in
                
                guard let userposts = snapshot.value as? [String: Any] else {return}
                
                userposts.forEach({ (key,value) in
                    
                    myGroup.enter()
                    
                    print("Key \(key), Value: \(value)")
                    
                    let dictionary = value as? [String: Any]
                    let secondsFrom1970 = dictionary?["creationDate"] as? Double ?? 0
                    let creationDate = Date(timeIntervalSince1970: secondsFrom1970)
                    print("PostId: ", key,"Creation Date: ", creationDate)
                    
                    
                    
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
    
    static func updatePostwithPostID( postId: String, values: [String:Any]){
        
        Database.database().reference().child("posts").child(postId).updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Fail to Update Post: ", postId, err)
                return
            }
            print("Succesfully Updated Post: ", postId, " with: ", values)

        }
        
    }
    
    static func deletePost(post: Post){
        
        Database.database().reference().child("posts").child(post.id!).removeValue()
        Database.database().reference().child("postlocations").child(post.id!).removeValue()
        Database.database().reference().child("userposts").child(post.creatorUID!).child(post.id!).removeValue()
        Database.database().reference().child("bookmarks").child(post.creatorUID!).child(post.id!).removeValue()
                
        print("Post Delete @ posts, postlocations, userposts, bookmarks: ", post.id)

        var deleteRef = Storage.storage().reference(forURL: post.imageUrl)
        
        deleteRef.delete(completion: { (error) in
            if let error = error {
                print("post image delete error for ", post.imageUrl)
            } else {
                print("Image Delete Success: ", post.imageUrl)
            }
            
        })
        
    }
    
    static func fetchPostWithPostID( postId: String, completion: @escaping (Post) -> ()) {
        
            if let cachedPost = postCache[postId] {
                if cachedPost != nil {
                completion(cachedPost)
                return
                }
            }
        
            let ref = Database.database().reference().child("posts").child(postId)
            
            ref.observeSingleEvent(of: .value, with: {(snapshot) in
                
            guard let dictionary = snapshot.value as? [String: Any] else {return}
                let creatorUID = dictionary["creatorUID"] as? String ?? ""
                
                
                
           Database.fetchUserWithUID(uid: creatorUID, completion: { (user) in
            var post = Post(user: user, dictionary: dictionary)
            post.id = postId
            
           checkPostForLikesAndBookmarks(post: post, completion: { (post) in
                postCache[postId] = post
//                print(post)
                completion(post)
            })
           })
        })
    
    }
    
    static func fetchMessageForUID( userUID: String, completion: @escaping ([Message]) -> ()) {
        
        let myGroup = DispatchGroup()
        var messages = [] as [Message]
        let ref = Database.database().reference().child("messages").child(userUID)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
//            print(snapshot.value)
            guard let userposts = snapshot.value as? [String:Any]  else {return}
            
            userposts.forEach({ (key,value) in
            myGroup.enter()
                
                
            guard let messageDetails = value as? [String: Any] else {return}
            guard let senderUserUID = messageDetails["senderUID"] as? String else {return}
            guard let postID = messageDetails["postUID"] as? String else {return}
                
            Database.fetchUserWithUID(uid: senderUserUID, completion: { (senderUser) in
                
            Database.fetchPostWithPostID(postId: postID, completion: { (post) in
                
                
                let tempMessage = Message.init(uid: key, senderUser: senderUser, sendPost: post, dictionary: messageDetails)
                
                messages.append(tempMessage)
                myGroup.leave()
            })

            })

            })
            
            myGroup.notify(queue: .main) {
                messages.sort(by: { (p1, p2) -> Bool in
                    return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                })
                completion(messages)
            }
            
            })
    }
    
    
    static func fetchAllPostWithLocation(location: CLLocation, distance: Double, completion: @escaping ([Post]) -> ()) {

        var fetchedPosts = [] as [Post]
        
        let myGroup = DispatchGroup()
        let ref = Database.database().reference().child("postlocations")
        let geoFire = GeoFire(firebaseRef: ref)
        let circleQuery = geoFire?.query(at: location, withRadius: distance)
        
            myGroup.enter()
        circleQuery?.observe(.keyEntered, with: { (key, location) in
//            print(key)

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

    static func fetchPostIDDetails(postId: String, completion: @escaping (PostId) -> ()) {
        
        var fetchedPostID: PostId? = nil
        
        let ref = Database.database().reference().child("posts").child(postId)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            guard let dictionary = snapshot.value as? [String: Any] else {return}
            let creatorUID = dictionary["creatorUID"] as? String ?? ""
            let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
            let postGPS = dictionary["postLocationGPS"] as? String ?? ""
            
            let tempID = PostId.init(id: postId, creatorUID: creatorUID, fetchedDate: secondsFrom1970, distance: nil, postGPS: postGPS)
            completion(tempID)
            
        })
    }
    
    
    
    static func fetchAllPostIDWithinLocation(selectedLocation: CLLocation, distance: Double, completion: @escaping ([PostId]) -> ()) {
        
        let myGroup = DispatchGroup()
        var fetchedPostIds = [] as [PostId]
        
        let ref = Database.database().reference().child("postlocations")
        let geoFire = GeoFire(firebaseRef: ref)
        let circleQuery = geoFire?.query(at: selectedLocation, withRadius: distance)
        
        myGroup.enter()
        circleQuery?.observe(.keyEntered, with: { (key, firebaseLocation) in
            print(key)
            
            myGroup.enter()
            
            Database.fetchPostIDDetails(postId: key!, completion: { (fetchPostId) in
                var tempPostId = fetchPostId
                tempPostId.distance = firebaseLocation?.distance(from: selectedLocation)
                fetchedPostIds.append(tempPostId)
                myGroup.leave()
            })
        })
        
        circleQuery?.observeReady({
            myGroup.leave()
        })
        
        myGroup.notify(queue: .main) {
            fetchedPostIds.sort(by: { (p1, p2) -> Bool in
                return (p1.distance! < p2.distance!)
            })
            print("Geofire Fetched Posts: ", fetchedPostIds.count )
            completion(fetchedPostIds)
            
        }
        
    }

}
