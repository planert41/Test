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
    
    static func fetchUsers(completion: @escaping ([User]) -> ()) {
        
        var tempUsers: [User] = []
        let myGroup = DispatchGroup()
        let ref = Database.database().reference().child("users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else {return}
            
            dictionaries.forEach({ (key,value) in
                myGroup.enter()
                
                if key == Auth.auth().currentUser?.uid{
                    print("Found Myself, omit from list")
                    myGroup.leave()
                    return
                }
                
                guard let userDictionary = value as? [String: Any] else {return}
                var user = User(uid: key, dictionary: userDictionary)
                
                if CurrentUser.followingUids.contains(key){
                    user.isFollowing = true
                } else {
                    user.isFollowing = false
                }
                tempUsers.append(user)
                myGroup.leave()
                
            })
            
            myGroup.notify(queue: .main) {
                tempUsers.sort(by: { (u1, u2) -> Bool in
                    return u1.username.compare(u2.username) == .orderedAscending
                })
                completion(tempUsers)
            }
        })   { (err) in print ("Failed to fetch users for search", err) }

    }
    
    static func fetchFollowingUserUids(uid: String, completion: @escaping ([String]) -> ()) {
        
        var followingUsers: [String] = []
        
        Database.database().reference().child("following").child(uid).child("following").observeSingleEvent(of: .value, with: { (snapshot) in
            
            let followingUserList = snapshot.value as? [String: Int] ?? [:]
            
            followingUserList.forEach({ (key,value) in
                if value == 1{
                    followingUsers.append(key)
                } else {
                    print("Error: User Id in Following List is not 1")
                    return
                }
            })
            print("User: \(uid) is Following \(followingUsers.count) Users")
            completion(followingUsers)
            
        }) { (error) in
                print("Error fetching following user uids: ", error)
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
        
        Database.database().reference().child("likes").child(post.id!).observeSingleEvent(of: .value, with: { (snapshot) in
            
                let post = snapshot.value as? [String: Any] ?? [:]
                var likes: Dictionary<String, Int>
                likes = post["likes"] as? [String : Int] ?? [:]
                var likeCount = post["likeCount"] as? Int ?? 0
            
        
            if likes[uid] == 1 {
                tempPost.hasLiked = true
            } else {
                tempPost.hasLiked = false
            }
            
            tempPost.likeStats = likeCount
            
            completion(tempPost)
        }, withCancel: { (err) in
            print("Failed to fetch bookmark info for post:", err)
        })
    }
    
    static func checkPostForBookmarks(post: Post, completion: @escaping (Post) -> ()){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        var tempPost = post
        Database.database().reference().child("bookmarks").child(post.id!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let post = snapshot.value as? [String: Any] ?? [:]
            var bookmarks: Dictionary<String, Int>
            bookmarks = post["bookmarks"] as? [String : Int] ?? [:]
            var bookmarkCount = post["bookmarkCount"] as? Int ?? 0
            
            
            if bookmarks[uid] == 1 {
                tempPost.hasBookmarked = true
            } else {
                tempPost.hasBookmarked = false
            }
            
            tempPost.bookmarkStats = bookmarkCount
            
            completion(tempPost)

        }, withCancel: { (err) in
            print("Failed to fetch bookmark info for post:", err)
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
                let tagTime = dictionary?["tagTime"] as? Double ?? 0
                let emoji = dictionary?["emoji"] as? String ?? ""
                
                
                let tempID = PostId.init(id: key, creatorUID: creatoruid, fetchedTagTime: tagTime, fetchedDate: secondsFrom1970, distance: nil, postGPS: nil, postEmoji: emoji)
                fetchedPostIds.append(tempID)
                
                myGroup.leave()
                
            })
            
            myGroup.notify(queue: .main) {
                completion(fetchedPostIds)
            }
        })
    }
    
    static func updateSocialCounts(uid: String!){
        
        let myGroup = DispatchGroup()
        let innerLoop = DispatchGroup()
        
        //Social Data
        var postCount: Int = 0
        var followingCount: Int = 0
        var followerCount: Int = 0
        var bookmarkCount: Int = 0
        var bookmarkedCount: Int = 0
        var likedCount: Int = 0
        
        let likeRef = Database.database().reference().child("likes")
        let bookmarkRef = Database.database().reference().child("bookmarks")
        let followingRef = Database.database().reference().child("following")
        let followerRef = Database.database().reference().child("follower")
        let userPostRef = Database.database().reference().child("userposts")
        let userRef = Database.database().reference().child("users")
        
        myGroup.enter()
        fetchAllPostIDWithCreatorUID(creatoruid: uid) { (postIds) in
            // Fetch All Created Post Ids and loop through to collect social data
            for postId in postIds {

                innerLoop.enter()
                // Check for received likes
                likeRef.child(postId.id).child("likeCount").observeSingleEvent(of: .value, with: { (snapshot) in
                    var postLikeCount = snapshot.value as? Int ?? 0
                    likedCount += postLikeCount
                    print("Current Post \(postId.id), likeCount: \(postLikeCount), CumLikeCount: \(likedCount)")
                    innerLoop.leave()
                })
                
                innerLoop.enter()
                // Check for received bookmarks
                bookmarkRef.child(postId.id).child("bookmarkCount").observeSingleEvent(of: .value, with: { (snapshot) in
                    var postBookmarkCount = snapshot.value as? Int ?? 0
                    bookmarkedCount += postBookmarkCount
                    print("Current Post \(postId.id), bookmarkCount: \(postBookmarkCount), CumBookmarkCount: \(bookmarkedCount)")
                    
                    innerLoop.leave()
                })
            }
            innerLoop.notify(queue: .main) {
                myGroup.leave()
            }
        }
        
        // Check for following count
        myGroup.enter()
        followingRef.child(uid).child("followingCount").observeSingleEvent(of: .value, with: { (snapshot) in
            var userFollowingCount = snapshot.value as? Int ?? 0
            followingCount += max(0,userFollowingCount)
            myGroup.leave()
            
        })
        
        // Check for follower count
        myGroup.enter()
        followerRef.child(uid).child("followingCount").observeSingleEvent(of: .value, with: { (snapshot) in
            var userFollowerCount = snapshot.value as? Int ?? 0
            followerCount += max(0,userFollowerCount)
            myGroup.leave()
        })
        
        // Check for post count
        myGroup.enter()
        userPostRef.child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            var userPosts = snapshot.value as? [String:Any]
            var userPostCount = userPosts?.count ?? 0
            postCount += max(0,userPostCount)
            myGroup.leave()
        })
        
        // Check for bookmarks count
        myGroup.enter()
        userRef.child(uid).child("bookmarks").child("bookmarkCount").observeSingleEvent(of: .value, with: { (snapshot) in
            var userBookmarkCount = snapshot.value as? Int ?? 0
            bookmarkCount += max(0,userBookmarkCount)
            myGroup.leave()
        })
        
        myGroup.notify(queue: .main) {
    
            
            let values = ["postCount": postCount, "followingCount": followingCount, "followerCount": followerCount, "bookmarkCount": bookmarkCount, "bookmarkedCount": bookmarkedCount, "likedCount": likedCount] as [String:Any]
            
            userRef.child(uid).child("social").updateChildValues(values, withCompletionBlock: { (err, ref) in
                if let err = err {
                    print("Failed to save user social data for :",uid, err)
                    return}
                
                    print("Successfully save user social data for : \(uid)", values)
                })
            }
        
    }
    
    
    static func fetchAllBookmarkIdsForUID(uid: String, completion: @escaping ([BookmarkId]) -> ()) {
        
        let myGroup = DispatchGroup()
        var fetchedBookmarkIds = [] as [BookmarkId]
        
        let ref = Database.database().reference().child("users").child(uid).child("bookmarks").child("bookmarks")
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            guard let bookmarks = snapshot.value as? [String: Any] else {return}
            
            bookmarks.forEach({ (key,value) in
                
                myGroup.enter()
                //                print("Key \(key), Value: \(value)")
                guard let dictionary = value as? [String: Any] else {return}
                    
                    let bookmarkTime = dictionary["bookmarkDate"] as? Double ?? 0
                    // Substitute Post Id creation date with bookmark time
                    let tempId = BookmarkId.init(postId: key, fetchedBookmarkDate: bookmarkTime)
                    fetchedBookmarkIds.append(tempId)
                        myGroup.leave()

            })
            
            myGroup.notify(queue: .main) {
                completion(fetchedBookmarkIds)
            }
        })
    }
    
    static func fetchAllBookmarksForUID(uid: String, completion: @escaping ([Bookmark]) -> ()) {

        let myGroup = DispatchGroup()
        
        var tempBookmarks:[Bookmark] = []
        
        Database.fetchAllBookmarkIdsForUID(uid: uid) { (bookmarkIds) in
            
            for bookmarkId in bookmarkIds{
                myGroup.enter()
                Database.fetchPostWithPostID(postId: bookmarkId.postId, completion: { (post, error) in
                    if let error = error {
                        print("Failed to fetch post for bookmarks: ",bookmarkId.postId , error)
                        myGroup.leave()
                        return
                    } else if let post = post {
                        let tempBookmark = Bookmark.init(bookmarkDate: bookmarkId.bookmarkDate, post: post)
                        tempBookmarks.append(tempBookmark)
                        myGroup.leave()
                    } else {
                        print("No Result for PostId: ", bookmarkId.postId)
                        //Delete Bookmark since post is unavailable, Present Delete Alert
                        
                        let deleteAlert = UIAlertController(title: "Delete Bookmark", message: "Post Bookmarked on \(bookmarkId.bookmarkDate) Was Deleted", preferredStyle: UIAlertControllerStyle.alert)
                        
                        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                            // Delete Bookmark in Database
                            Database.handleBookmark(postId: bookmarkId.postId, creatorUid: nil, completion: {
                                
                            })
                        }))
                        
                        UIApplication.shared.keyWindow?.rootViewController?.present(deleteAlert, animated: true, completion: nil)
                        myGroup.leave()
                    }
                    
                })
            }
            
            myGroup.notify(queue: .main) {
                tempBookmarks.sort(by: { (p1, p2) -> Bool in
                    return p1.bookmarkDate.compare(p2.bookmarkDate) == .orderedDescending
                })
                completion(tempBookmarks)
            }
        }
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
                    
//                    print("Key \(key), Value: \(value)")
                    
                    let dictionary = value as? [String: Any]
                    let secondsFrom1970 = dictionary?["creationDate"] as? Double ?? 0
                    let creationDate = Date(timeIntervalSince1970: secondsFrom1970)
//                    print("PostId: ", key,"Creation Date: ", creationDate)
                    
                    
                    
//                    print(user.uid, key)
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
    
    static func updateUserPostwithPostID(creatorId: String, postId: String, values: [String:Any]){
        
        Database.database().reference().child("userposts").child(creatorId).child(postId).updateChildValues(values) { (err, ref) in
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
        
        // Remove from cache
        postCache.removeValue(forKey: post.id!)
        
        
        // Bookmarked post is deleted when user fetches for post but it isn't there
//        Database.database().reference().child("bookmarks").child(post.creatorUID!).child(post.id!).removeValue()
        
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
    
    static func fetchPostWithPostID( postId: String, completion: @escaping (Post?, Error?) -> ()) {
        
            if let cachedPost = postCache[postId] {
                if cachedPost != nil {
                completion(cachedPost, nil)
                return
                }
            }
        
            let ref = Database.database().reference().child("posts").child(postId)
            
            ref.observeSingleEvent(of: .value, with: {(snapshot) in
                
            guard let dictionary = snapshot.value as? [String: Any] else {
                print("No dictionary for post id: ", postId)
                completion(nil,nil)
                return
                }
                let creatorUID = dictionary["creatorUID"] as? String ?? ""
                
                
                
           Database.fetchUserWithUID(uid: creatorUID, completion: { (user) in
            var post = Post(user: user, dictionary: dictionary)
            post.id = postId
            
           checkPostForLikesAndBookmarks(post: post, completion: { (post) in
                postCache[postId] = post
//                print(post)
                completion(post, nil)
            })
           })
            }) {(err) in
                print("Failed to fetch post for postid:",err)
                completion(nil, err)
        }
        
    
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
                
            Database.fetchPostWithPostID(postId: postID, completion: { (post, error) in
                
                if let error = error {
                  print(error)
                    return
                }
                
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
        circleQuery?.observe(.keyEntered, with: { (key, firebaselocation) in
//            print(key)

            myGroup.enter()
            Database.fetchPostWithPostID(postId: key!, completion: { (post, error) in
//                print(post)
                if let error = error {
                    print(error)
                    return
                }
                
                guard let post = post else {return}
                var tempPost = post
                tempPost.distance = tempPost.locationGPS?.distance(from: location)
//                print(tempPost.distance, ": ", tempPost.caption, " : ", location, " : ", tempPost.locationGPS)
                fetchedPosts.append(tempPost)
                myGroup.leave()
            })
        })
        
        circleQuery?.observeReady({
                myGroup.leave()
        })
        
        myGroup.notify(queue: .main) {
            fetchedPosts.sort(by: { (p1, p2) -> Bool in
                return (p1.distance! < p2.distance!)
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
            let tagTime = dictionary["tagTime"] as? Double ?? 0
            let emoji = dictionary["emoji"] as? String ?? ""
            
            
            let tempID = PostId.init(id: postId, creatorUID: creatorUID, fetchedTagTime: tagTime, fetchedDate: secondsFrom1970, distance: nil, postGPS: postGPS, postEmoji: emoji)
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
//            print(key)
            
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
            print("Geofire Fetched Posts: \(fetchedPostIds.count)" )
            completion(fetchedPostIds)
            
        }
        
    }
    
    // Social Functions
    
    static func handleLike(postId: String!, creatorUid: String!, completion: @escaping () -> Void){
        
        let ref = Database.database().reference().child("likes").child(postId)
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var post = currentData.value as? [String : AnyObject] ?? [:]
                var likes: Dictionary<String, Int>
                likes = post["likes"] as? [String : Int] ?? [:]
                var likeCount = post["likeCount"] as? Int ?? 0
                if let _ = likes[uid] {
                    // Unstar the post and remove self from stars
                    likeCount -= 1
                    likes.removeValue(forKey: uid)
                    updateSocialCount(creatorUid: uid, receiverUid: creatorUid, action: "like", change: -1)
                    
                } else {
                    // Star the post and add self to stars
                    likeCount += 1
                    likes[uid] = 1
                    updateSocialCount(creatorUid: uid, receiverUid: creatorUid, action: "like", change: 1)
                    
                }
                post["likeCount"] = likeCount as AnyObject?
                post["likes"] = likes as AnyObject?
                
                // Set value and report transaction success
                currentData.value = post
                print("Successfully Update Like in Likes \(postId):\(uid):\(likes[uid])")
                return TransactionResult.success(withValue: currentData)

        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                // Completion after updating Likes
                completion()
            }
        }
        
    }
    
    static func handleBookmark(postId: String!, creatorUid: String!, completion: @escaping () -> Void){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = Database.database().reference().child("bookmarks").child(postId)
        
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                var post = currentData.value as? [String : AnyObject] ?? [:]
                var bookmarks: Dictionary<String, Int>
                bookmarks = post["bookmarks"] as? [String : Int] ?? [:]
                var bookmarkCount = post["bookmarkCount"] as? Int ?? 0
                if let _ = bookmarks[uid] {
                    // Unstar the post and remove self from stars
                    bookmarkCount -= 1
                    bookmarks.removeValue(forKey: uid)
                    updateSocialCount(creatorUid: uid, receiverUid: creatorUid, action: "bookmark", change: -1)
                    
                } else {
                    // Star the post and add self to stars
                    bookmarkCount += 1
                    bookmarks[uid] = 1
                    updateSocialCount(creatorUid: uid, receiverUid: creatorUid, action: "bookmark", change: -1)
                    
                }
            
                post["bookmarkCount"] = bookmarkCount as AnyObject?
                post["bookmarks"] = bookmarks as AnyObject?
            
                // Set value and report transaction success
                currentData.value = post
                print("Successfully Update Bookmark for \(postId):\(uid):\(bookmarks[uid])")
                return TransactionResult.success(withValue: currentData)

        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                // No Error Handle Bookmarking in User
                handleUserBookmark(postId: postId)
                completion()
            }
        }
    }
    
    static func handleUserBookmark(postId: String!){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = Database.database().reference().child("users").child(uid).child("bookmarks")
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]
            var bookmarkCount = user["bookmarkCount"] as? Int ?? 0
            var bookmarks = user["bookmarks"] as? [String : AnyObject] ?? [:]
            
            if let _ = bookmarks[postId] {
                // Remove Bookmark
                bookmarkCount -= 1
                bookmarks.removeValue(forKey: postId)
            } else {
                // Add Bookmark
                let bookmarkTime = Date().timeIntervalSince1970
                let values = ["bookmarkDate": bookmarkTime] as [String : AnyObject]
                bookmarkCount += 1
                bookmarks[postId] = values as AnyObject
            }
            
            user["bookmarkCount"] = bookmarkCount as AnyObject?
            user["bookmarks"] = bookmarks as AnyObject?
            
            // Set value and report transaction success
            currentData.value = user
            print("Successfully Update Bookmark in User \(uid) for Post: \(postId)")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
    }
    
    static func handleFollowing(userUid: String!, completion: @escaping () -> Void){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = Database.database().reference().child("following").child(uid)

        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]
            var following: Dictionary<String, Int>
            following = user["following"] as? [String : Int] ?? [:]
            var followingCount = user["followingCount"] as? Int ?? 0
            if let _ = following[userUid] {
                // Unfollow User
                followingCount -= 1
                following.removeValue(forKey: userUid)
            } else {
                // Follow User
                followingCount += 1
                following[userUid] = 1
            }
            user["followingCount"] = followingCount as AnyObject?
            user["following"] = following as AnyObject?
            
            // Set value and report transaction success
            currentData.value = user
            print("Successfully Update \(uid) following: \(userUid): \(following[userUid])")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                handleFollower(followedUid: userUid)
                completion()
            }
        }
    }
    
    static func handleFollower(followedUid: String!){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = Database.database().reference().child("follower").child(followedUid)
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]
            var followers: Dictionary<String, Int>
            followers = user["followers"] as? [String : Int] ?? [:]
            var followerCount = user["followerCount"] as? Int ?? 0
            if let _ = followers[uid] {
                // Unstar the post and remove self from stars
                followerCount -= 1
                followers.removeValue(forKey: uid)
            } else {
                // Star the post and add self to stars
                followerCount += 1
                followers[uid] = 1
            }
            user["followerCount"] = followerCount as AnyObject?
            user["follower"] = followers as AnyObject?
            
            // Set value and report transaction success
            currentData.value = user
            print("Successfully Update Followers in \(followedUid) for \(uid) following \(user[uid])")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    static func updateSocialCount(creatorUid: String!, receiverUid: String?, action: String!, change: Int!){
        
        guard let receiverUid = receiverUid else {
            print("No Receiver Uid Error")
            return}
        
        let creatorRef = Database.database().reference().child("users").child(creatorUid).child("social")
        let receiveRef = Database.database().reference().child("users").child(receiverUid).child("social")
        
        var creatorField: String! = ""
        var receiveField: String! = ""
        
        if action == "like"{
            creatorField = "likeCount"
            receiveField = "likedCount"
        } else if action == "bookmark" {
            creatorField = "bookmarkCount"
            receiveField = "bookmarkedCount"
        } else if action == "follow" {
            creatorField = "followingCount"
            receiveField = "followedCount"
        } else if action == "post" {
            creatorField = "postCount"
            receiveField = "postCount"
        } else {
            print("Invalid Social Action")
            return
        }
        
        // Update creator social count
        
        creatorRef.runTransactionBlock({ (currentData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]
            var count = user[creatorField] as? Int ?? 0
            count = max(0, count + change)
            user[creatorField] = count as AnyObject?
            
            currentData.value = user
            print("Successfully Update \(creatorField) for creator : \(creatorUid) by: \(change), New Count: \(count)")
            return TransactionResult.success(withValue: currentData)

        }) { (error, committed, snapshot) in
            if let error = error {
                print("Creator Social Update Error: ", creatorUid, error.localizedDescription)
            }
        }
        
        // Update receiver social count (Not applicable if post was created
        if action != "post" {
            receiveRef.runTransactionBlock({ (currentData) -> TransactionResult in
                var user = currentData.value as? [String : AnyObject] ?? [:]
                var count = user[receiveField] as? Int ?? 0
                count = max(0, count + change)
                user[receiveField] = count as AnyObject?
                
                currentData.value = user
                print("Successfully Update \(receiveField) for receiver : \(receiverUid) by: \(change), New Count: \(count)")
                return TransactionResult.success(withValue: currentData)
                
            }) { (error, committed, snapshot) in
                if let error = error {
                    print("Receiver Social Update Error: ", creatorUid, error.localizedDescription)
                }
            }
        }
    }
    
    
}
