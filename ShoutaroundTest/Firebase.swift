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
    
    
    static func fetchCurrentUser(completion:@escaping () ->()){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}

        Database.fetchUserWithUID(uid: uid) { (user) in
            CurrentUser.user = user
            print("Current User: \(CurrentUser.user)")
            
            // Fetch Lists
            Database.fetchListForMultListIds(listUid: CurrentUser.listIds, completion: { (fetchedLists) in
                CurrentUser.lists = fetchedLists
                print("Current User List: \(CurrentUser.lists)")
                completion()
            
            })
        }
        
    }
    

    
    
    
    
    
// Alerts
    static func alert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        var topController = UIApplication.shared.keyWindow!.rootViewController as! UIViewController
        
        while ((topController.presentedViewController) != nil) {
            topController = topController.presentedViewController!;
        }
        topController.present(alert, animated:true, completion:nil)
    }
    
    
// Fetching User Functions
    
    static func fetchUserWithUID(uid: String, completion: @escaping (User) -> ()) {
        
//        Database.updateSocialCounts(uid: uid)
        
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
    
    static func fetchUserWithUsername( username: String, completion: @escaping (User?, Error?) -> ()) {
        
        let myGroup = DispatchGroup()
        var query = Database.database().reference().child("users").queryOrdered(byChild: "username").queryEqual(toValue: username)
        var user: User?
        
        query.observe(.value, with: { (snapshot) in
            
//            print(snapshot)
            guard let queryUsers = snapshot.value as? [String: Any] else {
                completion(nil,nil)
                return}
            queryUsers.forEach({ (key,value) in
                
                myGroup.enter()
                guard let dictionary = value as? [String: Any] else {return}
                
                user = User(uid: key, dictionary: dictionary)
                myGroup.leave()
            })
            myGroup.notify(queue: .main) {
                completion(user!, nil)
            }
        }) { (err) in
            print("Failed to fetch user for Username", err)
            completion(nil, err)
        }
    }
    
// Fetch Bookmark Functions
    
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
    
    
// Create Posts Functions
    
//    Sequence
//    1. Save Post Image: Create Image URL
//    2. Save Post Dictionary with Image URL: create Post ID
//    3. Save Post Location in GeoFire with Post ID
//    4. Save Post ID to User Posts
//    5. Create List if Needed
//    6. Add PostId to List if Needed
    
    static func savePostToDatabase(uploadImage: UIImage?, uploadDictionary:[String:Any]?,uploadLocation: CLLocation?, lists:[List]?, completion:@escaping () ->()){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let uploadImage = uploadImage else {
            print("Save Post: ERROR, No Image")
            return
        }
        guard let uploadDictionary = uploadDictionary else {
            print("Save Post: ERROR, No Upload Dictionary")
            return
        }
        
        let uploadTime = uploadDictionary["creationDate"] as! Double?
        
        // Save Image
        self.saveImageToDatabase(uploadImage: uploadImage) { (imageUrl) in
            
            self.savePostDictionaryToDatabase(imageUrl: imageUrl, uploadDictionary: uploadDictionary, completion: { (postId) in
                
                self.savePostLocationToFirebase(postId: postId, uploadLocation: uploadLocation)
                self.savePostIdForUser(postId: postId, userId: uid, uploadTime: uploadTime)

                // Update Emoji Tags
                if let emojiTags = uploadDictionary["nonratingEmoji"] as! [String]? {
                    for emoji in emojiTags {
                        self.updatePostIdForTag(postId: postId, tag: emoji, add: 1)
                    }
                }

                // Update List
                if lists != nil {
                    if lists!.count > 0 {
                        for list in lists! {
                            self.addPostForList(postId: postId, listId: list.id, postCreationDate: uploadTime)
                        }
                    }
                }
                completion()
            })
        }
    }
    
    static func saveImageToDatabase(uploadImage:UIImage?, completion: @escaping (String) -> ()){
        
        guard let image = uploadImage?.resizeImageWith(newSize: defaultPhotoResize) else {
            self.alert(title: "Upload Post Requirement", message: "Please Insert Picture")
            return }
        guard let uploadData = UIImageJPEGRepresentation(image, 0.5) else {
            self.alert(title: "Upload Post Requirement", message: "Please Insert Picture")
            return}
        
        let imageId = NSUUID().uuidString
        Storage.storage().reference().child("posts").child(imageId).putData(uploadData, metadata: nil) { (metadata, err) in
            if let err = err {
                print("Save Post Image: ERROR", err)
                return
            }
            guard let imageUrl = metadata?.downloadURL()?.absoluteString else {return}
            print("Save Post Image: SUCCESS:",  imageUrl)
            // Returns ImageURL
            completion(imageUrl)
        }
    }
    
    static func savePostDictionaryToDatabase(imageUrl: String, uploadDictionary:[String:Any]?, completion: @escaping (String) -> ()){

        guard let uploadDictionary = uploadDictionary else {
            self.alert(title: "Upload Post Requirement", message: "Please Insert Post Dictionary")
            return
        }
        let userPostRef = Database.database().reference().child("posts")
        let postId = NSUUID().uuidString
        let ref = Database.database().reference().child("posts").child(postId)
        let uploadTime = Date().timeIntervalSince1970
        let uploadTimeDictionary = uploadDictionary["creationDate"]

        guard let uid = Auth.auth().currentUser?.uid else {return}

        var uploadValues = uploadDictionary
        uploadValues["imageUrl"] = imageUrl

        // SAVE POST IN POST DATABASE

        ref.updateChildValues(uploadValues) { (err, ref) in
            if let err = err {
                print("Save Post Dictionary: ERROR", err)
                return}

            print("Save Post Dictionary: SUCCESS")
            Database.spotUpdateSocialCount(creatorUid: uid, socialField: "posts_created", change: 1)
            completion(postId)
//            // Put new post in cache
//            self.uploadnewPostCache(uid: uid,postid: ref.key, dictionary: uploadValues)

        }
    }
    
    static func savePostIdForUser(postId: String?, userId: String?, uploadTime: Double?){
        guard let postId = postId else {
            print("Save User PostID: ERROR, No Post ID")
            return
        }
        guard let userId = userId else {
            print("Save User PostID: ERROR, No User ID")
            return
        }
        guard let uploadTime = uploadTime else {
            print("Save User PostID: ERROR, No Upload Time")
            return
        }
        
        let userPostRef = Database.database().reference().child("userposts").child(userId).child(postId)
        let values = ["creationDate": uploadTime] as [String:Any]
        
        userPostRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Save User PostID: ERROR, \(postId)", err)
                return
            }
            print("Save User PostID: SUCCESS, \(postId)")
        }
    }
    
    
    static func savePostLocationToFirebase(postId: String, uploadLocation: CLLocation?){
        guard let uploadLocation = uploadLocation else {
            print("No Upload Location Saved to Firebase for \(postId)")
            return
        }
        
        let geofireRef = Database.database().reference().child("postlocations")
        guard let geoFire = GeoFire(firebaseRef: geofireRef) else {return}
        
        geoFire.setLocation(uploadLocation, forKey: postId) { (error) in
            if (error != nil) {
                print("An error occured when saving Location \(uploadLocation) for Post \(postId) : \(error)")
            } else {
                print("Saved location successfully! for Post \(postId)")
            }
        }
    }

// Edit Posts Function
    static func editPostToDatabase(imageUrl: String?, postId: String?, uploadDictionary:[String:Any]?,uploadLocation: CLLocation?, prevPost: Post?, completion:@escaping () ->()){
    
        //    1. Update Post Dictionary
        //    2. Update Post Geofire Location
        //    3. Update Emoji Tags
        //    4. Create List if Needed
        //    5. Add PostId to List if Needed
        
        guard let imageUrl = imageUrl else {
            print("Update Post: ERROR, No Image URL")
            return
        }
        
        guard let postId = postId else {
            print("Update Post: ERROR, No Post ID")
            return
        }
        
        guard let uploadDictionary = uploadDictionary else {
            print("Update Post: ERROR, No Post ID")
            return
        }
        
        guard let prevPost = prevPost else {
            print("Update Post: ERROR, No Previous Post")
            return
        }
        
        let userPostRef = Database.database().reference().child("posts").child(postId)
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        var uploadValues = uploadDictionary
        uploadValues["imageUrl"] = imageUrl


        // SAVE EDITED POST IN POST DATABASE
        userPostRef.updateChildValues(uploadValues) { (err, ref) in
            if let err = err {
                print("Update Post Dictionary: ERROR: \(postId)", err)
                return}
            
            print("Update Post Dictionary: SUCCESS: \(postId)")
        }
        
        // UPDATE LOCATION IN GEOFIRE
        savePostLocationToFirebase(postId: postId, uploadLocation: uploadLocation)
        
        // UPDATE EMOJI TAGS
        // Delete Preivous Emojis
        self.DeleteTagsForPost(post: prevPost)
        
        // Update Emoji Tags
        if let emojiTags = uploadDictionary["nonratingEmoji"] as! [String]? {
            for emoji in emojiTags {
                self.updatePostIdForTag(postId: postId, tag: emoji, add: 1)
            }
        }
        
        // UPDATE LISTS
        
        // Find Deleted List
        let currentList = uploadValues["lists"] as! [String:String]? ?? [:]
        let previousList = prevPost.creatorListId as! [String:String]? ?? [:]
        var deletedList: [String] = []
        var addedList: [String] = []
        let postCreationTime = uploadValues["creationDate"] as! Double?


        
        for (listId,listName) in previousList {
            if currentList[listId] != nil {
                // Is in current list ignore
            } else {
                deletedList.append(listId)
            }
        }
        
        
        for (listId,listName) in currentList {
            if previousList[listId] != nil {
                // Is in previous list ignore
            } else {
                addedList.append(listId)
            }
        }
        
        for list in deletedList {
            Database.DeletePostForList(postId: postId, listId: list, postCreationDate: postCreationTime)
        }
        
        for list in addedList {
            Database.addPostForList(postId: postId, listId: list, postCreationDate: postCreationTime)
        }
        
        
        // Replace Post Cache
        var tempPost = Post.init(user: CurrentUser.user!, dictionary: uploadValues)
        tempPost.id = postId
        postCache[postId] = tempPost
        completion()
    
    }
    

    
// Fetch Posts Functions

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
                let emoji = dictionary?["emoji"] as? String ?? ""
                
                let tempID = PostId.init(id: key, creatorUID: creatoruid, sort: nil)
                fetchedPostIds.append(tempID)
                myGroup.leave()
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
                    let dictionary = value as? [String: Any]
                    let secondsFrom1970 = dictionary?["creationDate"] as? Double ?? 0
                    let creationDate = Date(timeIntervalSince1970: secondsFrom1970)
                    //                    print("PostId: ", key,"Creation Date: ", creationDate)
                    //                    print(user.uid, key)
                    Database.fetchPostWithUIDAndPostID(creatoruid: user.uid, postId: key, completion: { (post) in
                        
                        Database.checkPostForSocial(post: post, completion: { (post) in
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

                    Database.checkPostForSocial(post: post, completion: { (post) in
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
    
    static func fetchPostWithPostID( postId: String, completion: @escaping (Post?, Error?) -> ()) {
        
        if let cachedPost = postCache[postId] {
            if cachedPost != nil {
//                print("Using post cache for \(postId)")
                var tempCachePost = cachedPost
                
                completion(tempCachePost, nil)
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
                
                checkPostForSocial(post: post, completion: { (post) in
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
//            let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
//            let postGPS = dictionary["postLocationGPS"] as? String ?? ""
//            let tagTime = dictionary["tagTime"] as? Double ?? 0
//            let emoji = dictionary["emoji"] as? String ?? ""
            
            
            let tempID = PostId.init(id: postId, creatorUID: creatorUID, sort: nil)
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
                tempPostId.sort = firebaseLocation?.distance(from: selectedLocation)
                fetchedPostIds.append(tempPostId)
                myGroup.leave()
            })
        })
        
        circleQuery?.observeReady({
            myGroup.leave()
        })
        
        myGroup.notify(queue: .main) {
            
            fetchedPostIds.sort(by: { (p1, p2) -> Bool in
                return (p1.sort! < p2.sort!)
            })
            print("Geofire Fetched Posts: \(fetchedPostIds.count)" )
            completion(fetchedPostIds)
        }
    }
    
    static func fetchPostIDBySocialRank(firebaseRank: String, fetchLimit: Int, completion: @escaping ([PostId]?) -> ()) {
        
        let myGroup = DispatchGroup()
        var fetchedPostIds = [] as [PostId]
        guard let firebaseCountVariable = firebaseCountVariable[firebaseRank] else {
            print("Fetch Post Id by Social Rank: ERROR, Invalid Firebase Count for \(firebaseRank)")
            return
        }
        guard let firebaseField = firebaseFieldVariable[firebaseRank] else {
            print("Fetch Post Id by Social Rank: ERROR, Invalid Firebase Field for \(firebaseRank)")
            return
        }
        
        
        print("Query Firebase by \(firebaseRank) : \(firebaseCountVariable)")

        var query = Database.database().reference().child(firebaseField).queryOrdered(byChild: "sort").queryLimited(toLast: UInt(fetchLimit))
        query.observe(.value, with: { (snapshot) in
            guard let postIds = snapshot.value as? [String:Any] else {return}
            
            
            postIds.forEach({ (key,value) in
                
                let details = value as? [String:Any]
                var varCount = details?[firebaseCountVariable] as! Int
                var varSort = details?["sort"] as! Double
                
                var tempPostId = PostId.init(id: key, creatorUID: " ", sort: varSort)
                fetchedPostIds.append(tempPostId)

            })
            
            // Sort Fetched Post Ids
            fetchedPostIds.sort(by: { (p1, p2) -> Bool in
                return (p1.sort! > p2.sort!)
            })
            
            completion(fetchedPostIds)

        }) { (error) in
            print("Fetch Post Id by Social Rank: ERROR, \(error)")
            completion(nil)
        }
    }
    
    static func fetchAllPostIDWithTag(emojiTag: String, completion: @escaping ([PostId]?) -> ()) {
        
        let myGroup = DispatchGroup()
        var fetchedPostIds = [] as [PostId]
        
        let ref = Database.database().reference().child("post_tags").child(emojiTag)

        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let tag = snapshot.value as? [String: Any] else {
                print("Fetch Post for EmojiTag \(emojiTag): Nil Results")
                completion(nil)
                return}
            guard let taggedPosts = tag["posts"] as? [String] else {return}
            
            taggedPosts.forEach({ (key) in
                myGroup.enter()
                let tempID = PostId.init(id: key, creatorUID: nil, sort: nil)
                fetchedPostIds.append(tempID)
                myGroup.leave()
            })
            
            myGroup.notify(queue: .main) {
                completion(fetchedPostIds)
            }
        }){ (error) in
            print(error)
            completion(nil)
        }
    }
    
    
    
    static func fetchAllPosts(fetchedPostIds: [PostId], completion: @escaping ([Post])-> ()){
        
        let thisGroup = DispatchGroup()
        var fetchedPostsTemp: [Post] = []
        
        for postId in fetchedPostIds {
            thisGroup.enter()
            Database.fetchPostWithPostID(postId: postId.id, completion: { (post, error) in
                if let error = error {
                    print("Fetch Post: ERROR: \(postId)", error)
                }
                
                guard let post = post else {
                    print("Fetch Post: ERROR: No Post for \(postId)", error)
                    thisGroup.leave()
                    return
                }
                
                var tempPost = post
                
                fetchedPostsTemp.append(tempPost)
                thisGroup.leave()
            })
        }
        
        thisGroup.notify(queue: .main) {
            print("Fetched All Posts: ", fetchedPostsTemp.count)
            completion(fetchedPostsTemp)
        }
    }
    
    
    
// Social Stat Updates
    
    static func checkPostForVotes(post: Post, completion: @escaping (Post) -> ()){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        var tempPost = post
        
        Database.database().reference().child("post_votes").child(post.id!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let post = snapshot.value as? [String: Any] ?? [:]
            var votes: Dictionary<String, Int>
            votes = post["votes"] as? [String : Int] ?? [:]
            var voteCount = post["voteCount"] as? Int ?? 0
            
            if let curVote = votes[uid] {
                tempPost.hasVoted = curVote
            }
            
            if tempPost.voteCount != voteCount {
                // Calculated Bookmark Count Different from Database
                tempPost.voteCount = voteCount
                updateSocialCountsForPost(postId: tempPost.id, socialVariable: "voteCount", newCount: voteCount)
            }
            
            
            completion(tempPost)
        }, withCancel: { (err) in
            print("Failed to fetch bookmark info for post:", err)
        })
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
            
            if tempPost.likeCount != likeCount {
                // Calculated Bookmark Count Different from Database
                tempPost.likeCount = likeCount
                updateSocialCountsForPost(postId: tempPost.id, socialVariable: "likeCount", newCount: likeCount)
            }
            
            
            completion(tempPost)
        }, withCancel: { (err) in
            print("Failed to fetch bookmark info for post:", err)
        })
    }
    
    static func checkPostForLists(post: Post, completion: @escaping (Post) -> ()){
        var tempSelectedListIds: [String:String] = [:]
        var tempPost = post
        guard let postId = post.id else {
            print("Check Post for Lists: ERROR, No Post Ids")
            return
        }
        
        if CurrentUser.lists.count > 0 {
            for list in CurrentUser.lists {
                if list.postIds![postId] != nil {
                    tempSelectedListIds[list.id!] = list.name
                }
            }
            tempPost.selectedListId = tempSelectedListIds
        }
        
        if tempSelectedListIds.count > 0 {
            tempPost.hasBookmarked = true
        } else {
            tempPost.hasBookmarked = false
        }

        completion(tempPost)
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
            
            if tempPost.listCount != bookmarkCount {
                // Calculated Bookmark Count Different from Database
                tempPost.listCount = bookmarkCount
                updateSocialCountsForPost(postId: tempPost.id, socialVariable: "bookmarkCount", newCount: bookmarkCount)
            }
            
            completion(tempPost)
            
        }, withCancel: { (err) in
            print("Failed to fetch bookmark info for post:", err)
        })
    }
    
    static func checkPostForMessages(post: Post, completion: @escaping (Post) -> ()){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        var tempPost = post
        Database.database().reference().child("post_messages").child(post.id!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let post = snapshot.value as? [String: Any] ?? [:]
            var messages: Dictionary<String, Int>
            messages = post["bookmarks"] as? [String : Int] ?? [:]
            var messageCount = post["messageCount"] as? Int ?? 0

            if tempPost.messageCount != messageCount {
                // Calculated Bookmark Count Different from Database
                tempPost.messageCount = messageCount
                updateSocialCountsForPost(postId: tempPost.id, socialVariable: "messageCount", newCount: messageCount)
            }
            
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
    
    static func checkPostForSocial(post: Post, completion: @escaping (Post) -> ()){
        
        Database.checkPostForVotes(post: post) { (post) in
            Database.checkPostForLists(post: post, completion: { (post) in
                Database.checkPostForMessages(post: post, completion: { (post) in
                    completion(post)
                })
            })
        }
    }
    
    
    
    static func updateSocialCountsForPost(postId: String!, socialVariable: String!, newCount: Int!){
        
        let values = [socialVariable: newCount] as [String:Any]
        
        Database.database().reference().child("posts").child(postId).updateChildValues(values, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Failed to save user social data for :",postId, err)
                return}
            
            print("Successfully update \(socialVariable) to \(newCount) for \(postId)")
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
//                    print("Current Post \(postId.id), likeCount: \(postLikeCount), CumLikeCount: \(likedCount)")
                    innerLoop.leave()
                })
                
                innerLoop.enter()
                // Check for received bookmarks
                bookmarkRef.child(postId.id).child("bookmarkCount").observeSingleEvent(of: .value, with: { (snapshot) in
                    var postBookmarkCount = snapshot.value as? Int ?? 0
                    bookmarkedCount += postBookmarkCount
//                    print("Current Post \(postId.id), bookmarkCount: \(postBookmarkCount), CumBookmarkCount: \(bookmarkedCount)")
                    
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
    
// Upload/Update Post
    
    static func updatePostwithPostID( post: Post, newDictionaryValues: [String:Any]){
        
        Database.database().reference().child("posts").child(post.id!).updateChildValues(newDictionaryValues) { (err, ref) in
            if let err = err {
                print("Fail to Update Post: ", post.id, err)
                return
            }
            print("Succesfully Updated Post: ", post.id, " with: ", newDictionaryValues)
            
            // Update Post Cache
            var tempPost = Post.init(user: post.user, dictionary: newDictionaryValues)
            tempPost.id = post.id
            postCache[post.id!] = tempPost
            
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
    
    static func AddTagsForPost(post: Post){
        guard let postId = post.id else {
            print("Update Tags For Post: Error, no Post Id")
            return
        }
        
        if post.nonRatingEmoji.count == 0 {
            print("Update Tags For Post: Error, no Emojis for \(postId)")
            return
        }
        
        for emoji in post.nonRatingEmoji {
            Database.updatePostIdForTag(postId: postId, tag: emoji, add: 1)
        }
    }
    
    static func DeleteTagsForPost(post: Post){
        guard let postId = post.id else {
            print("Update Tags For Post: Error, no Post Id")
            return
        }
        
        if post.nonRatingEmoji.count == 0 {
            print("Update Tags For Post: Error, no Emojis for \(postId)")
            return
        }
        
        for emoji in post.nonRatingEmoji {
            Database.updatePostIdForTag(postId: postId, tag: emoji, add: -1)
        }
    }
    
    static func updatePostIdForTag(postId: String?, tag: String?, add: Int){
        guard let postId = postId else {
            print("Update Tags For Post: Error, no Post Id")
            return}
        
        guard let tag = tag else {
            print("Update Tags For Post: Error, no Tag")
            return}
        
        if !(tag.containsOnlyEmoji) {
            print("Update Tags For Post: Error, not Emoji Tag")
            return}
        
        if !(add == 1 || add == -1) {
            print("Update Tags For Post: Error, not Valid Add Function")
            return}
        
        let tagRef = Database.database().reference().child("post_tags").child(tag)
        tagRef.runTransactionBlock({ (currentData) -> TransactionResult in
            var tags = currentData.value as? [String : AnyObject] ?? [:]
            var posts = tags["posts"] as? [String] ?? []
            var postCount = tags["postCount"] as? Int ?? 0
            
            if add == 1 {
                // Add postid to Tag
                if let index = posts.index(of: postId) {
                    // Post Id already exist
                    print("Add Post to Tag: Error, PostId already exist")
                    return TransactionResult.abort()
                } else {
                    // Post Id doesn't exist, add postId
                    posts.append(postId)
                    postCount += 1
                }
            }
            
            else if add == -1 {
                // Delete Post Id from Tag
                if let index = posts.index(of: postId) {
                    posts.remove(at: index)
                    postCount -= 1
                } else {
                    // Post Id doesn't exist, No Delete
                    print("Delete Post from Tag: Error, PostId does not exist")
                    return TransactionResult.abort()
                }
            }
            
            tags["posts"] = posts as AnyObject?
            tags["postCount"] = max(0,postCount) as AnyObject?
            
            
            currentData.value = tags
            print("Update Post to Tag: Success \(postId) to \(tag) : \(add)")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print("Update Post to Tag: Error: ", postId, tag, add, error.localizedDescription)
            }
        }
    }
    
    
    static func deletePost(post: Post){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        Database.database().reference().child("posts").child(post.id!).removeValue()
        Database.database().reference().child("postlocations").child(post.id!).removeValue()
        Database.database().reference().child("userposts").child(post.creatorUID!).child(post.id!).removeValue()
        Database.database().reference().child("comments").child(post.id!).removeValue()

        Database.database().reference().child("post_lists").child(post.id!).removeValue()
        Database.database().reference().child("post_messages").child(post.id!).removeValue()
        Database.database().reference().child("post_votes").child(post.id!).removeValue()
        
        // Remove emoji tags
        self.DeleteTagsForPost(post: post)
        
        // Remove from cache
        postCache.removeValue(forKey: post.id!)
        Database.spotUpdateSocialCount(creatorUid: uid, socialField: "posts_created", change: -1)
        
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
    
//    static func fetchMessageForUID( userUID: String, completion: @escaping ([Message]) -> ()) {
//        
//        let myGroup = DispatchGroup()
//        var messages = [] as [Message]
//        let ref = Database.database().reference().child("messages").child(userUID)
//        
//        ref.observeSingleEvent(of: .value, with: {(snapshot) in
//            
////            print(snapshot.value)
//            guard let userposts = snapshot.value as? [String:Any]  else {return}
//            
//            userposts.forEach({ (key,value) in
//            myGroup.enter()
//                
//                
//            guard let messageDetails = value as? [String: Any] else {return}
//            guard let senderUserUID = messageDetails["senderUID"] as? String else {return}
//            guard let postID = messageDetails["postUID"] as? String else {return}
//                
//            Database.fetchUserWithUID(uid: senderUserUID, completion: { (senderUser) in
//                
//            Database.fetchPostWithPostID(postId: postID, completion: { (post, error) in
//                
//                if let error = error {
//                  print(error)
//                    return
//                }
//                
//                let tempMessage = Message.init(uid: key, senderUser: senderUser, sendPost: post, dictionary: messageDetails)
//                
//                messages.append(tempMessage)
//                myGroup.leave()
//            })
//            })
//            })
//            
//            myGroup.notify(queue: .main) {
//                messages.sort(by: { (p1, p2) -> Bool in
//                    return p1.creationDate.compare(p2.creationDate) == .orderedDescending
//                })
//                completion(messages)
//            }
//            
//            })
//    }
//    
    static func fetchMessageThreadsForUID( userUID: String, completion: @escaping ([MessageThread]) -> ()) {
        
        let myGroup = DispatchGroup()
        var messageThreadIds = [] as [String]
        var messageThreads = [] as [MessageThread]
        let ref = Database.database().reference().child("inbox").child(userUID)
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            guard let userposts = snapshot.value as? [String:Any]  else {return}
            
            userposts.forEach({ (key, lastTime) in
                
                myGroup.enter()
                
                self.fetchMessageThread(threadId: key, completion: { (messageThread) in
                    var tempThread = messageThread
                    let lastReadTime = lastTime as? Double ?? 0
                    tempThread.lastCheckDate = Date(timeIntervalSince1970: lastReadTime)
                    messageThreads.append(tempThread)
                    myGroup.leave()
                })
            })
            
            myGroup.notify(queue: .main) {
                completion(messageThreads)
            }
        })
    }
    
    static func fetchMessageThread( threadId: String, completion: @escaping (MessageThread) -> ()) {
        let ref = Database.database().reference().child("messageThreads").child(threadId)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let threadDictionary = snapshot.value as? [String: Any] else {return}
            
            let tempThread = MessageThread.init(threadID: threadId, dictionary: threadDictionary)
            completion(tempThread)
        }) { (error) in
                print("Error fetching message thread: \(threadId)", error)
        }
    }
    
    // List
    
    static func createList(uploadList: List){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        if uploadList.id == nil {
            print("Create List: ERROR, No List ID")
            return
        }
        
        guard let listId = uploadList.id else {return}
        
        // Update New List in Current User Cache
        CurrentUser.addList(list: uploadList)
        
        // Create List Object
        
        let listRef = Database.database().reference().child("lists").child(listId)
        let createdDate = Date().timeIntervalSince1970
        let listName = uploadList.name
        
        let values = ["name": listName, "createdDate": createdDate, "creatorUID": uid] as [String:Any]
        
        listRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Create List Object: ERROR: \(listId):\(listName)", err)
                return
            }
            print("Create List Object: Success: \(listId):\(listName)")
            
        // Create List Id in User
            let userRef = Database.database().reference().child("users").child(uid).child("lists")
            let values = [listId: createdDate] as [String:Any]
            userRef.updateChildValues(values) { (err, ref) in
                if let err = err {
                    print("Create List ID with User: ERROR: \(listId):\(listName), User: \(uid)", err)
                    return
                }
            
                print("Create List ID with User: SUCCESS: \(listId):\(listName), User: \(uid)")
                Database.spotUpdateSocialCount(creatorUid: uid, socialField: "lists_created", change: 1)
            }
        }
        
    }
    
    static func deleteList(uploadList: List){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        guard let listId = uploadList.id else {
            print("Delete List: ERROR, No List ID")
            return
        }
        
        if defaultListNames.contains(listId) {
            print("Delete Default List Name Error")
            return
        }
        
        // Delete List in Current User Cache
        CurrentUser.removeList(list: uploadList)
    
        Database.database().reference().child("lists").child(listId).removeValue()
        print("Delete List Oject: Success \(uploadList.name)")
        
        Database.database().reference().child("users").child(uid).child("lists").child(listId).removeValue()
        print("Delete List Oject: Success: \(uploadList.name), User: \(uid)")
        
        Database.spotUpdateSocialCount(creatorUid: uid, socialField: "lists_created", change: -1)

        
    }
    
    static func addPostForList(postId: String, listId: String?, postCreationDate: Double?){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let listId = listId else {
            print("Add Post to List: ERROR, No List ID")
            return
        }
        
        let listAddDate = Date().timeIntervalSince1970
        let listRef = Database.database().reference().child("lists").child(listId).child("posts")
        let values = [postId: listAddDate] as [String:Any]
        
        // Add Post to List
        listRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to save post \(postId) to List \(listId)", err)
                return
            }
            print("Successfully save post \(postId) to List \(listId)")
        }
        
        
        // Update Current User List
        if let listIndex = CurrentUser.lists.index(where: { (currentList) -> Bool in
            currentList.id == listId
        }) {
            CurrentUser.lists[listIndex].postIds![postId] = listAddDate
        }
        
        // Add to Post Lists
        let postListRef = Database.database().reference().child("post_lists").child(postId)

        postListRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            
            var post = currentData.value as? [String : AnyObject] ?? [:]
            var lists: Dictionary<String, Double>
            lists = post["lists"] as? [String : Double] ?? [:]
            var listCount = post["listCount"] as? Int ?? 0
            var postDate = post["creationDate"] as? Double ?? 0
            
            // Add List to Post List
            listCount += 1
            lists[listId] = listAddDate
            
            // Handle/Update Post Creation Date
            if let postCreationDate = postCreationDate {
                if postDate != postCreationDate {
                    postDate = postCreationDate
                }
            }
            
            post["listCount"] = listCount as AnyObject?
            post["lists"] = lists as AnyObject?
            post["creationDate"] = postDate as AnyObject?
            
            // Enables firebase sort by count adjusted by recency
            let  uploadTime = Date().timeIntervalSince1970/1000000000000000
            post["sort"] = (Double(listCount) + uploadTime) as AnyObject
            
            // Set value and report transaction success
            currentData.value = post
            print("Post_Lists Add: Success, \(postId):\(listId):\(lists[postId])")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
//                var post = snapshot?.value as? [String : AnyObject] ?? [:]
//                var votes = post["votes"] as? [String : Int] ?? [:]
//                spotUpdateSocialCount(creatorUid: uid, receiverUid: creatorUid, action: "vote", change: voteChange)
                // Completion after updating Likes
//                completion()
            }
        }
        
        
        
    }
    
    static func DeletePostForList(postId: String, listId: String?, postCreationDate: Double?){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let listId = listId else {
            print("Delete Post in List: ERROR, No List ID")
            return}
        Database.database().reference().child("lists").child(listId).child("posts").child(postId).removeValue()
        print("Delete PostId: Success : \(postId) from ListId: \(listId)")
        
        // Update Current User List
        if let listIndex = CurrentUser.lists.index(where: { (currentList) -> Bool in
            currentList.id == listId
        }) {
            if let postIndex = CurrentUser.lists[listIndex].postIds?.index(forKey: postId){
            CurrentUser.lists[listIndex].postIds?.remove(at: postIndex)
            }
        }
        
        // Delete From Post Lists
        let postListRef = Database.database().reference().child("post_lists").child(postId)
        
        postListRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            
            var post = currentData.value as? [String : AnyObject] ?? [:]
            var lists: Dictionary<String, Double>
            lists = post["lists"] as? [String : Double] ?? [:]
            var listCount = post["listCount"] as? Int ?? 0
            var postDate = post["creationDate"] as? Double ?? 0
            
            // Add List to Post List
            if let deleteIndex = lists.index(forKey: listId) {
                listCount += -1
                lists.remove(at: deleteIndex)
            } else {
                print("Post_Lists Delete: ERROR, Can't Find Deleted ListId in Post?")
            }
            
            // Handle/Update Post Creation Date
            if let postCreationDate = postCreationDate {
                if postDate != postCreationDate {
                    postDate = postCreationDate
                }
            }
            
            post["listCount"] = listCount as AnyObject?
            post["lists"] = lists as AnyObject?
            post["creationDate"] = postDate as AnyObject?
            
            // Enables firebase sort by count adjusted by recency
            let  uploadTime = Date().timeIntervalSince1970/1000000000000000
            post["sort"] = (Double(listCount) + uploadTime) as AnyObject
            
            // Set value and report transaction success
            currentData.value = post
            print("Post_Lists Delete: Success, \(postId):\(listId):\(lists[postId])")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                //                var post = snapshot?.value as? [String : AnyObject] ?? [:]
                //                var votes = post["votes"] as? [String : Int] ?? [:]
                //                spotUpdateSocialCount(creatorUid: uid, receiverUid: creatorUid, action: "vote", change: voteChange)
                // Completion after updating Likes
                //                completion()
            }
        }
        
        
        
    }
    
    static func fetchListForMultListIds(listUid: [String]?, completion: @escaping ([List]) -> ()){
        
        guard let listUid = listUid else {
            print("Fetch Lists: ERROR, No List Ids")
            return
        }
        
        if listUid.count == 0 {
            print("Fetch Lists: ERROR, No List Ids")
            completion([])
        }
        
        let myGroup = DispatchGroup()
        var fetchedLists = [] as [List]
        
        listUid.forEach { (key) in
            myGroup.enter()
            self.fetchListforSingleListId(listId: key, completion: { (fetchedList) in
                if let fetchedList = fetchedList {
                    fetchedLists.append(fetchedList)
                }
                myGroup.leave()
            })
        }
        
        myGroup.notify(queue: .main) {
            fetchedLists.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedAscending
            })
            completion(fetchedLists)
        }
    }
    
    static func fetchListforSingleListId(listId: String, completion: @escaping(List?) -> ()){
        let ref = Database.database().reference().child("lists").child(listId)
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let listDictionary = snapshot.value as? [String: Any] else {return}
            
            let fetchedList = List.init(id: listId, dictionary: listDictionary)
            completion(fetchedList)
        }){ (error) in
            print("Fetch List ID: ERROR, \(listId)", error)
            completion(nil)
        }
    }
    
    static func updateListforPost(post: Post?, newList: [String:String]?, prevList:[String:String]?, completion:@escaping () ->()){
        
        // Find Deleted List
        let currentList = newList as! [String:String]? ?? [:]
        let previousList = prevList as! [String:String]? ?? [:]
        var deletedList: [String] = []
        var addedList: [String] = []
        let postCreationTime = post?.creationDate.timeIntervalSince1970
        
        guard let postId = post?.id else {
            print("Update List for Post: ERROR, No PostID")
            return
        }
        
        for (listId,listName) in previousList {
            if currentList[listId] != nil {
                // Is in current list ignore
            } else {
                deletedList.append(listId)
            }
        }
        
        
        for (listId,listName) in currentList {
            if previousList[listId] != nil {
                // Is in previous list ignore
            } else {
                addedList.append(listId)
            }
        }
        
        for list in deletedList {
            Database.DeletePostForList(postId: postId, listId: list, postCreationDate: postCreationTime)
        }
        
        for list in addedList {
            Database.addPostForList(postId: postId, listId: list, postCreationDate: postCreationTime)
        }
        
        // Replace Post Cache
        var tempPost = post
        tempPost?.selectedListId = newList
        postCache[postId] = tempPost
        completion()
        
    }
    
    static func checkUpdateListDetailsWithPost(listName: String, listId: String, post: Post, completion: @escaping (List?) ->()){
        
        var tempPost = post
        var tempPostDictionary = tempPost.dictionary()
        
        // Check if list exists
        Database.fetchListforSingleListId(listId: listId) { (list) in
            if list == nil {
                print("List \(listId): \(listName) does not exist anymore")
                
                // Update Post Details and Remove List
                if let deleteIndex = tempPost.creatorListId?.index(forKey: listId) {
                    var updatePostListIds = tempPost.creatorListId?.remove(at: deleteIndex)
                    tempPostDictionary["lists"] = updatePostListIds
                    print("Deleting \(listId) list from \(tempPost.id) Post")
                    Database.updatePostwithPostID(post: post, newDictionaryValues: tempPostDictionary)
                }
                completion(nil)
            } else {
                // List Exists
                
                    if list?.name != listName {
                    // Update Post Details if List Name has Changes
                        var tempList = tempPostDictionary["lists"] as! [String:String]
                        tempList[listId] = list?.name
                        tempPostDictionary["lists"] = tempList
                        print("Updating \(listId) list Name from \(listName) to \(list?.name) for Post \(post.id)")
                        Database.updatePostwithPostID(post: post, newDictionaryValues: tempPostDictionary)
                    }
                
                completion(list)
            }
        }
    }
    
    // Messages
    static func updateMessageThread(threadKey: String, creatorUid: String, creatorUsername: String, receiveUid: [String: String]?, message: String) {
        
        // Create User Message within Thread
        let threadRef = Database.database().reference().child("messageThreads").child(threadKey)
        let threadMessageRef = threadRef.child("messages").childByAutoId()
        let inboxRef = Database.database().reference().child("inbox")
        let uploadTime = Date().timeIntervalSince1970
        let descTime = Date()
        
        // Create Message in Message Thread
        let values = ["creatorUID": creatorUid, "message": message, "creationDate": uploadTime] as [String:Any]
        
        threadMessageRef.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Error saving \(creatorUid) message: \(message) : in Thread \(threadKey) at \(descTime)")
                return
            }
            print("Success saving \(creatorUid) message: \(message) : in Thread \(threadKey) at \(descTime)")
        })
        
        // Update Users in Thread and Inbox
        var allUsers: [String: String] = [:]
        if let receiveUid = receiveUid {
            allUsers = receiveUid
            allUsers[creatorUid] = creatorUsername
        } else {
            allUsers[creatorUid] = creatorUsername
        }
        
        threadRef.child("users").updateChildValues(allUsers, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Error Updating Users \(allUsers) in Thread \(threadKey)")
                return
            }
            print("Success Updating Users \(allUsers) in Thread \(threadKey)")
        })
        
        // Loop Through Users
        var threadUpload = [threadKey:uploadTime]
        for (user, username) in allUsers {
            inboxRef.child(user).updateChildValues(threadUpload, withCompletionBlock: { (err, ref) in
                if let err = err {
                    print("Error Updating Inbox for User \(user), Thread \(threadKey)")
                    return
                }
                print("Success Updating Inbox for User \(user), Thread \(threadKey)")
            })
        }
    }

    static func respondMessageThread(threadKey: String, creatorUid: String, message: String) {
        
        // Create User Message within Thread
        let threadRef = Database.database().reference().child("messageThreads").child(threadKey)
        let threadMessageRef = threadRef.child("messages").childByAutoId()
        let inboxRef = Database.database().reference().child("inbox")
        let uploadTime = Date().timeIntervalSince1970
        let descTime = Date()
        
        // Create Message in Message Thread
        let values = ["creatorUID": creatorUid, "message": message, "creationDate": uploadTime] as [String:Any]
        
        threadMessageRef.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Error saving \(creatorUid) message: \(message) : in Thread \(threadKey) at \(descTime)")
                return
            }
            print("Success saving \(creatorUid) message: \(message) : in Thread \(threadKey) at \(descTime)")
        })
    }
    
    
    
    
    // Social Functions
    
    static func handleVote(post: Post!, creatorUid: String!, vote: Int!, completion: @escaping () -> Void){

        guard let postId = post.id else {return}
        let postCreationDate = post.creationDate.timeIntervalSince1970
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = Database.database().reference().child("post_votes").child(postId)
        var voteChange = 0 as Int
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            
            var post = currentData.value as? [String : AnyObject] ?? [:]
            var votes: Dictionary<String, Int>
            votes = post["votes"] as? [String : Int] ?? [:]
            var voteCount = post["voteCount"] as? Int ?? 0
            var postDate = post["creationDate"] as? Double ?? 0
            
        // Handle Change Vote
            if let curVote = votes[uid] {
                // Has Current Vote
                if curVote == vote {
                    // Deselect Current Vote
                    votes[uid] = 0
                    voteChange = -vote
                } else {
                    // Override Current Vote
                    votes[uid] = vote
                    voteChange = (vote - curVote)
                }
            } else {
                // Make New Vote
                votes[uid] = vote
                voteChange = vote
            }
            
        // Handle Creation Date
            if postDate != postCreationDate {
                postDate = postCreationDate
            }
            
            voteCount += voteChange
            post["voteCount"] = voteCount as AnyObject?
            post["votes"] = votes as AnyObject?
            post["creationDate"] = postDate as AnyObject?
            
            // Enables firebase sort by count adjusted by recency
            let  uploadTime = Date().timeIntervalSince1970/1000000000000000
            post["sort"] = (Double(voteCount) + uploadTime) as AnyObject
            
            // Set value and report transaction success
            currentData.value = post
            print("Successfully Update Like in Likes \(postId):\(uid):\(votes[uid])")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                var post = snapshot?.value as? [String : AnyObject] ?? [:]
                var votes = post["votes"] as? [String : Int] ?? [:]
                spotUpdateSocialCount(creatorUid: creatorUid, socialField: "votes_received", change: voteChange)
                // Completion after updating Likes
                completion()
            }
        }
        
    }
    
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
                } else {
                    // Star the post and add self to stars
                    likeCount += 1
                    likes[uid] = 1
                }
                post["likeCount"] = likeCount as AnyObject?
                post["likes"] = likes as AnyObject?
            
            // Enables firebase sort by count and recent upload time
                let  uploadTime = Date().timeIntervalSince1970/1000000000000000
                post["sort"] = (Double(likeCount) + uploadTime) as AnyObject
                
                // Set value and report transaction success
                currentData.value = post
                print("Successfully Update Like in Likes \(postId):\(uid):\(likes[uid])")
                return TransactionResult.success(withValue: currentData)

        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                var post = snapshot?.value as? [String : AnyObject] ?? [:]
                var likes = post["likes"] as? [String : Int] ?? [:]
                if let _ = likes[uid] {
//                    spotUpdateSocialCount(creatorUid: uid, receiverUid: creatorUid, action: "like", change: 1)
                } else {
//                    spotUpdateSocialCount(creatorUid: uid, receiverUid: creatorUid, action: "like", change: -1)
                }
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
                    
                } else {
                    // Star the post and add self to stars
                    bookmarkCount += 1
                    bookmarks[uid] = 1
                    
                }
            
                post["bookmarkCount"] = bookmarkCount as AnyObject?
                post["bookmarks"] = bookmarks as AnyObject?

            // Enables firebase sort by count and recent upload time
                let  uploadTime = Date().timeIntervalSince1970/1000000000000000
                post["sort"] = (Double(bookmarkCount) + uploadTime) as AnyObject
            
            
                // Set value and report transaction success
                currentData.value = post
                print("Successfully Update Bookmark for \(postId):\(uid):\(bookmarks[uid])")
                return TransactionResult.success(withValue: currentData)

        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                var post = snapshot?.value as? [String : AnyObject] ?? [:]
                var bookmarks = post["bookmarks"] as? [String : Int] ?? [:]

                if let _ = bookmarks[uid] {
//                    spotUpdateSocialCount(creatorUid: uid, receiverUid: creatorUid, action: "bookmark", change: 1)
                } else {
//                    spotUpdateSocialCount(creatorUid: uid, receiverUid: creatorUid, action: "bookmark", change: -1)
                }
                
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
                if let deleteIndex = following.index(forKey: userUid) {
                    following.remove(at: deleteIndex)
                    followingCount -= 1
                } else {
                    print("Unfollow: ERROR: \(uid) not following \(userUid)")
                }
            } else {
                if following[userUid] == 1 || following[userUid] != nil {
                    print("Following: ERROR: \(uid) already following \(userUid)")
                } else {
                // Follow User
                    followingCount += 1
                    following[userUid] = 1
                }
            }
            user["followingCount"] = followingCount as AnyObject?
            user["following"] = following as AnyObject?
            
            // Set value and report transaction success
            currentData.value = user
            print("Update Following: Success, \(uid) following: \(userUid): \(following[userUid])")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                var user = snapshot?.value as? [String : AnyObject] ?? [:]
                var following: Dictionary<String, Int>
                following = user["following"] as? [String : Int] ?? [:]
                var followedValue: Int? = following[userUid]
                
                handleFollower(followedUid: userUid, followedValue: followedValue){
                    if followedValue == 1 {
                        self.spotUpdateSocialCount(creatorUid: uid, socialField: "followingCount", change: 1)
                        self.spotUpdateSocialCount(creatorUid: userUid, socialField: "followerCount", change: 1)
                    } else {
                        self.spotUpdateSocialCount(creatorUid: uid, socialField: "followingCount", change: -1)
                        self.spotUpdateSocialCount(creatorUid: userUid, socialField: "followerCount", change: -1)
                    }
                }
                completion()
            }
        }
    }
    
    static func handleFollower(followedUid: String!, followedValue: Int?,  completion: @escaping() ->()){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = Database.database().reference().child("follower").child(followedUid)
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]
            var followers: Dictionary<String, Int>
            followers = user["followers"] as? [String : Int] ?? [:]
            var followerCount = user["followerCount"] as? Int ?? 0
            
            if followedValue == 1 {
                // User gained a new follower
                if followers[uid] == 1 {
                    print("Add Follower: ERROR, /(followedUid) already has \(uid) follower")
                } else {
                    followerCount += 1
                    followers[uid] = 1
                }
            } else {
                // User lost a follower
                if followers[uid] == 1 {
                    if let deleteIndex = followers.index(forKey: uid){
                        followers.remove(at: deleteIndex)
                        followerCount -= 1
                    } else {
                        print("Unfollow Error, /(followedUid) not followed by \(uid)")
                    }
                } else {
                    print("Unfollow Error, /(followedUid) not followed by \(uid)")
                }
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
            } else {
               completion()
            }
        }
    }

    static func spotUpdateSocialCount(creatorUid: String!, socialField: String!, change: Int!){
        
        // votes_received
        // followingCount, followersCount
        // posts_created, lists_created
        
        
        let creatorRef = Database.database().reference().child("users").child(creatorUid).child("social")
        creatorRef.runTransactionBlock({ (currentData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]
            var count = user[socialField] as? Int ?? 0
            
            if socialField != "votes_received"{
                // Allow Negative Votes
                count = count + change
            } else {
                count = max(0,count + change)
            }
            
            user[socialField] = count as AnyObject?
            
            currentData.value = user
            print("Update \(socialField!) for creator : \(creatorUid!) by: \(change!), New Count: \(count)")
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print("Creator Social Update Error: ", creatorUid, error.localizedDescription)
            }
        }
        
    }
    
    static func checkUserSocialStats(user: User, socialField: String, socialCount: Int){
        if socialField == "posts_created"{
            if user.posts_created != socialCount {
                let change = socialCount - user.posts_created
                Database.spotUpdateSocialCount(creatorUid: user.uid, socialField: "posts_created", change: change)
            }
        }
            
        else if socialField == "followingCount"{
            if user.followingCount != socialCount {
                let change = socialCount - user.followingCount
                Database.spotUpdateSocialCount(creatorUid: user.uid, socialField: "followingCount", change: change)
            }
        }
            
        else if socialField == "followersCount"{
            if user.followersCount != socialCount {
                let change = socialCount - user.followersCount
                Database.spotUpdateSocialCount(creatorUid: user.uid, socialField: "followersCount", change: change)
            }
        }
            
        else if socialField == "lists_created"{
            if user.lists_created != socialCount {
                let change = socialCount - user.lists_created
                Database.spotUpdateSocialCount(creatorUid: user.uid, socialField: "lists_created", change: change)
            }
        }
            
        else if socialField == "votes_received"{
            if user.votes_received != socialCount {
                let change = socialCount - user.votes_received
                Database.spotUpdateSocialCount(creatorUid: user.uid, socialField: "votes_received", change: change)
            }
        }
    }
    
    
    static func spotUpdateSocialCountOLD(creatorUid: String!, receiverUid: String?, action: String!, change: Int!){
        
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
            receiveField = "followerCount"
        } else if action == "post" {
            creatorField = "postCount"
            receiveField = "postCount"
        } else if action == "vote" {
            creatorField = "voteCount"
            receiveField = "votedCount"
        } else {
            print("Invalid Social Action")
            return
        }
        
        // Update creator social count - Not Keeping track of producing likes
        
        if action != "like"{
            creatorRef.runTransactionBlock({ (currentData) -> TransactionResult in
            var user = currentData.value as? [String : AnyObject] ?? [:]
            var count = user[creatorField] as? Int ?? 0
            count = count + change
            user[creatorField] = count as AnyObject?
            
            currentData.value = user
            print("Update \(creatorField!) for creator : \(creatorUid!) by: \(change!), New Count: \(count)")
            return TransactionResult.success(withValue: currentData)

            }) { (error, committed, snapshot) in
                if let error = error {
                print("Creator Social Update Error: ", creatorUid, error.localizedDescription)
                }
            }
        }
        
        // Update receiver social count  - Not applicable if post was created
        if action != "post" {
            receiveRef.runTransactionBlock({ (currentData) -> TransactionResult in
                var user = currentData.value as? [String : AnyObject] ?? [:]
                var count = user[receiveField] as? Int ?? 0
                count = count + change
                user[receiveField] = count as AnyObject?
                
                currentData.value = user
                print("Update \(receiveField!) for receiver : \(receiverUid) by: \(change!), New Count: \(count)")
                return TransactionResult.success(withValue: currentData)
                
            }) { (error, committed, snapshot) in
                if let error = error {
                    print("Receiver Social Update Error: ", creatorUid, error.localizedDescription)
                }
            }
        }
    }
    
    static func filterPosts(inputPosts: [Post]?, filterCaption: String?, filterRange: String?, filterLocation: CLLocation?, filterMinRating: Double?, filterType: String?, filterMaxPrice: String?, completion: @escaping ([Post]?) -> ()){
        
        guard let inputPosts = inputPosts else {
            print("Filter Posts: ERROR, No Post")
            completion(nil)
            return
        }
        
        var tempPosts = inputPosts
        
        // Filter Caption
        if filterCaption != nil && filterCaption != "" {
            guard let searchedText = filterCaption?.lowercased() else {return}
            
            var preFilterPosts = inputPosts
            
            // Determine Search Terms
            var searchTerms: [String] = [searchedText]
            
            // Split Search Terms into Individual Words
            var splitSearchTerms = searchedText.components(separatedBy: " ")
            if (splitSearchTerms.count) > 1 {
                searchTerms += splitSearchTerms
            }
            
            // Find Emojis for Search Word and individual words
            var emojiTerms: [String] = []
            for string in searchTerms {
                if let emoji = ReverseEmojiDictionary[string] {
                    emojiTerms.append(emoji)
                }
            }
            if emojiTerms.count > 0 {
                searchTerms += emojiTerms
            }
            
            var tempPosts: [Post] = []
            
            for post in preFilterPosts {
                var allCaption = post.caption.lowercased() + " " + post.emoji + " " + post.nonRatingEmojiTags.joined(separator: " ") + " " + post.locationName
                // Loops through all search terms until one is found in all caption
                for searchWord in searchTerms {
                    if allCaption.lowercased().contains(searchWord){
                        tempPosts.append(post)
                        // If it finds a matching word it adds it to tempPost and breaks
                        break
                    }
                }
            }
            
            print("Filtered Post By Caption: \(searchedText): \(tempPosts.count)")
            
        }
        
        
//        // Filter Caption
//        if filterCaption != nil && filterCaption != "" {
//            guard let searchedText = filterCaption else {return}
//
//            var preFilterPosts = inputPosts
//            var searchTerms = filterCaption?.components(separatedBy: " ")
//
//            tempPosts = tempPosts.filter { (post) -> Bool in
//                let searchedEmoji = ReverseEmojiDictionary[searchedText.lowercased()] ?? ""
//
//                return post.caption.lowercased().contains(searchedText.lowercased())
//                    || post.emoji.contains(searchedText.lowercased())
//                    || post.nonRatingEmojiTags.joined(separator: " ").lowercased().contains(searchedText.lowercased())
//                    || post.nonRatingEmojiTags.joined(separator: " ").lowercased().contains(searchedEmoji)
//                    || post.locationName.lowercased().contains(searchedText.lowercased())
//                    || post.locationAdress.lowercased().contains(searchedText.lowercased())
//            }
//            print("Filtered Post By Caption: \(searchedText): \(tempPosts.count)")
//
//        }
        
        // Distances are updated in fetchallposts as they are filtered by distance
        
        // Filter Range
        if filterLocation != nil && filterRange != nil {
            tempPosts = tempPosts.filter { (post) -> Bool in
                var filterDistance:Double = 99999999
                if post.distance != nil {
                    filterDistance = post.distance!
                }
                return filterDistance <= (Double(filterRange!)! * 1000)
            }
            print("Filtered Post By Range: \(filterRange) AT \(filterLocation): \(tempPosts.count)")
        }
        
        // Filter Rating
        if filterMinRating != 0 && filterMinRating != nil {
            tempPosts = tempPosts.filter { (post) -> Bool in
                var filterRating:Double = 0
                if post.rating != nil {
                    filterRating = post.rating!
                }
                return filterRating >= filterMinRating!
            }
            print("Filtered Post By Min Rating: \(filterMinRating): \(tempPosts.count)")
        }
        
        // Filter Type
        if filterType != nil {
            tempPosts = tempPosts.filter { (post) -> Bool in
                return post.type == filterType
            }
            print("Filtered Post By Post Type: \(filterType): \(tempPosts.count)")
        }
        
        // Filter Max Price
        if filterMaxPrice != nil {
            let maxPriceIndex = UploadPostPriceDefault.index(of: filterMaxPrice!)
            let filterMaxPrice = UploadPostPriceDefault[0...maxPriceIndex!]
            
            tempPosts = tempPosts.filter { (post) -> Bool in
                var filterPrice:String = "0"
                if post.price != nil {
                    filterPrice = post.price!
                }
                return filterMaxPrice.contains(filterPrice)
            }
            print("Filtered Post By Max Price: \(filterMaxPrice): \(tempPosts.count)")
        }
        
        completion(tempPosts)
    }
    
    static func sortPosts(inputPosts: [Post]?, selectedSort: String?, selectedLocation: CLLocation?, completion: @escaping ([Post]?) -> ()){
        guard let inputPosts = inputPosts else {
            print("Sort Posts: ERROR, No Post")
            completion(nil)
            return
        }
        
        var tempPosts = inputPosts
        
        print("Sort Posts: \(selectedSort!)")
        
        // Recent
        if selectedSort == HeaderSortOptions[0] {
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
            })
            completion(tempPosts)
        }
            
            // Nearest
        else if selectedSort == HeaderSortOptions[1] {
                // Distances are updated in fetchallposts as they are filtered by distance
            
            guard let selectedLocation = selectedLocation else {
                print("Sort Nearest: ERROR, No Location")
                completion(nil)
                return
            }
                //Update Posts for distances
                for (index,post) in tempPosts.enumerated() {
                    var tempPost = post
                    if tempPost.locationGPS == nil || tempPost.locationGPS == CLLocation(latitude: 0, longitude: 0) {
                        print("Sort Nearest: No GPS Location for \(tempPost.id), default Distance")
                        tempPost.distance = 999999999
                    } else {
                        tempPost.distance = Double((tempPost.locationGPS?.distance(from: selectedLocation))!)
                    }
                    tempPosts[index] = tempPost
                }

                tempPosts.sort(by: { (p1, p2) -> Bool in
                    return (p1.distance! < p2.distance!)
                })
                completion(tempPosts)
        }
            
            //Trending
        else if selectedSort == HeaderSortOptions[2] {
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return (p1.voteCount > p2.voteCount)
            })
            completion(tempPosts)
        }
            
            
            // Ratings
        else if selectedSort == LocationSortOptions[1] {
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return (p1.rating! > p2.rating!)
            })
            completion(tempPosts)
        }
            
            // Votes
        else if selectedSort == defaultRankOptions[0] {
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return (p1.voteCount > p2.voteCount)
            })
            completion(tempPosts)
        }
            
            // Bookmarks
        else if selectedSort == defaultRankOptions[1] {
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return (p1.listCount > p2.listCount)
            })
            completion(tempPosts)
        }
            
            // Message
        else if selectedSort == defaultRankOptions[1] {
            tempPosts.sort(by: { (p1, p2) -> Bool in
                return (p1.messageCount > p2.messageCount)
            })
            completion(tempPosts)
        }
            
            
            // ERROR - Invalid Sort
        else {
            print("Fetched Post Sort: ERROR, Invalid Sort")
            completion(tempPosts)
        }
        
    }
    
     static func translateToEmojiArray(stringInput: String?, completion: @escaping ([String]?) -> ()){
        guard let tempSearchText = stringInput else {
            print("Translate Emoji: ERROR, No String")
            return
        }
        if tempSearchText.isEmptyOrWhitespace(){
            print("Translate Emoji: ERROR, All Blank Spaces")
            return
        }
        
        var emojiString = tempSearchText.removeDuplicates.emojis ?? []
        var otherString = tempSearchText.emojilessString.components(separatedBy: " ")
        
        // Check other string for single emoji translates
        var emojiTranslateTemp: [String] = []
        var emojiTranslate: [String] = []
        
        for str in otherString {
            if let foundEmoji = ReverseEmojiDictionary[str.lowercased()] {
                emojiTranslateTemp.append(foundEmoji)
            }
        }
        
        // Check other string for 2 word combo emoji translates
        var stringCount = otherString.count ?? 0
        if stringCount > 1 {
            for i in (0...(stringCount-1)-1) {
                let doubleword = otherString[i] + " " + otherString[i+1]
                if let foundEmoji = ReverseEmojiDictionary[doubleword.lowercased()] {
                    emojiTranslateTemp.append(foundEmoji)
                }
            }
        }
        
        // Remove Dups from other string translations
        if emojiTranslateTemp.count > 0 {
            for i in (0...emojiTranslateTemp.count-1){
                if let _ = emojiTranslate.index(of: emojiTranslateTemp[i]){
                    print("Contains dup emoji \(emojiTranslateTemp[i])")
                } else {
                    emojiTranslate.append(emojiTranslateTemp[i])
                }
            }
        }
        
        let finalOutput = emojiString + emojiTranslate
        print("Emoji Translate: \(stringInput) TO: \(finalOutput)")
        completion(finalOutput)
    }
    
    
    
}
