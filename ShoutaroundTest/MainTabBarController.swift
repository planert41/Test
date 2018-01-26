//
//  MainTabBarController.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/26/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import Firebase
import Photos
import CoreLocation

class MainTabBarController: UITabBarController, UITabBarControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    

    var imagePicker = UIImagePickerController()
    var selectedPhotoLocation: CLLocation? = nil
    var selectedImage: UIImage? = nil
    var selectedTime: Date? = nil
    var assets = [PHAsset]()
    var selectedTabBarIndex: Int? = nil
    

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let index = viewControllers?.index(of: viewController) else {
            print("Invalid Tab Bar Index")
            return
        }
        
        print("---Tab Bar Selected----\(self.selectedTabBarIndex)")
        
        if index == 0 && index == self.selectedTabBarIndex {
            print("Double Click Home Tab Bar, Refreshing")
            NotificationCenter.default.post(name: HomeController.refreshPostsNotificationName, object: nil)
            // Reselected Home Controller refresh
        }

        if index == 1 && index == self.selectedTabBarIndex {
            print("Double Click Home Tab Bar, Refreshing")
            NotificationCenter.default.post(name: ExploreController.searchRefreshNotificationName, object: nil)
            // Reselected Search Controller refresh
        }
        
        selectedTabBarIndex = index
    }
    
    
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        let index = viewControllers?.index(of: viewController)
        
        if index == 2 {

        _ = UICollectionViewFlowLayout()
        // Add photo function selected
//
//            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//
//            alertController.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (_) in
//                self.presentCamera()
//            }))
//
//            alertController.addAction(UIAlertAction(title: "Photo Roll", style: .default, handler: { (_) in
//                self.presentImagePicker()
//            }))
//
//            alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (_) in
//                self.dismiss(animated: true, completion: nil)
//            }))
//
//            present(alertController, animated: true) {
//                // Works if you tag subview for tabbarcontroller
//                alertController.view.superview?.subviews[1].isUserInteractionEnabled = true
//                let cancelTap = UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:)))
//                alertController.view.superview?.subviews[1].addGestureRecognizer(cancelTap)
//                print(alertController.view.superview?.subviews)
//
//            }
            
            imagePicker.allowsEditing = true
            imagePicker.sourceType = .photoLibrary
            imagePicker.delegate = self
            imagePicker.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            present(imagePicker, animated: true, completion: nil)

            let photoSelectorController = PhotoSelectorControllerDummy()
            let navController = UINavigationController(rootViewController: photoSelectorController)
            
            present(navController, animated: true, completion: nil)
            
            return false
            
        }
        
        return true
    }
    
    func presentImagePicker(){
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        present(imagePicker, animated: true, completion: nil)
    }
    
    func presentCamera(){
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.delegate = self
            imagePicker.sourceType = .camera;
            imagePicker.allowsEditing = true
            present(imagePicker, animated: true, completion: nil)
        } else {
            self.alert(title: "No Camera", message: "Device has no camera")
            presentImagePicker()
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: { () in
            if (picker.sourceType == .photoLibrary) || (picker.sourceType == .camera) {
                
                let image = info[UIImagePickerControllerEditedImage] as! UIImage

//                let image = info[UIImagePickerControllerOriginalImage] as! UIImage
                var url: NSURL = info[UIImagePickerControllerReferenceURL] as! NSURL
                
                self.selectedImage = image
                
                if let URL = info[UIImagePickerControllerReferenceURL] as? URL {
                    let opts = PHFetchOptions()
                    opts.fetchLimit = 1
                    let assets = PHAsset.fetchAssets(withALAssetURLs: [URL], options: opts)
                    let asset = assets[0]
                    
                    print(asset)
                    self.selectedPhotoLocation = asset.location
                    self.selectedTime = asset.creationDate
                    // The location is "asset.location", as a CLLocation
                    
                    //Read Time/Date
                    // ... Other stuff like dismiss omitted
                }
                
                let sharePhotoController = SharePhotoController()
                sharePhotoController.selectedImage = self.selectedImage
                
//                if self.selectedPhotoLocation == nil {
//                    sharePhotoController.selectedImageLocation = CLLocation(latitude: 0, longitude: 0)
//                } else {
//                    sharePhotoController.selectedImageLocation  = self.selectedPhotoLocation                    
//                }
                
                sharePhotoController.selectedImageLocation  = self.selectedPhotoLocation
                sharePhotoController.selectedImageTime  = self.selectedTime
                
                let navController = UINavigationController(rootViewController: sharePhotoController)

                self.present(navController, animated: false, completion: nil)
                
                print("Handle Next")
                
            }
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        self.dismiss(animated: true, completion: nil)
        self.navigationController?.popToRootViewController(animated: true)
        
    }
    
    
     
//    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
//        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
//            imageView.contentMode = .ScaleAspectFit
//            imageView.image = pickedImage
//        }
//        
//        dismissViewControllerAnimated(true, completion: nil)
//    }    
//    
//    let sharePhotoController = SharePhotoController()
//    sharePhotoController.selectedImage = header?.photoImageView.image
//    sharePhotoController.selectedImageLocation  = selectedPhotoLocation
//    navigationController?.pushViewController(sharePhotoController, animated: true)
//    
//    
//    print("Handle Next")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
        
        if Auth.auth().currentUser == nil {
        
            DispatchQueue.main.async {
                let loginController = LoginController()
                let navController = UINavigationController(rootViewController: loginController)
                self.present(navController, animated: true, completion: nil)
            }
            return
        }
        
        fetchCurrentUser()
        setupViewControllers()
    
    }
    
    func fetchCurrentUser() {
        
        // uid using userID if exist, if not, uses current user, if not uses blank
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Fetch Current User: ERROR, No User UID")
            return}
        
        //        1. Pull User Information (Profile Img, Name, status, ListIds, social stats)
        //        2. Pull Lists
        //        3. Pull Social Stat Details (Voted Post Ids, Following, Followers)
        
        Database.fetchUserWithUID(uid: uid) { (user) in
            CurrentUser.user = user
            print("Fetching Current User: \(CurrentUser.user?.username)")
            
            // Fetch Lists
            Database.fetchListForMultListIds(listUid: CurrentUser.listIds, completion: { (fetchedLists) in
                CurrentUser.lists = fetchedLists
                print("Current User List Count: \(CurrentUser.lists.count)")
                Database.checkUserSocialStats(user: CurrentUser.user!, socialField: "lists_created", socialCount: fetchedLists.count)
            })
        }
    }
    

    
    func setupViewControllers() {
        
        // home
        
        let homeNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "home_unselected"), selectedImage: #imageLiteral(resourceName: "home_selected"), rootViewController: HomeController(collectionViewLayout: HomeSortFilterHeaderFlowLayout()))
        
        let searchNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "search_unselected"), selectedImage: #imageLiteral(resourceName: "search_selected"), rootViewController: ExploreController(collectionViewLayout: UICollectionViewFlowLayout()))

        let plusNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "plus_unselected"), selectedImage: #imageLiteral(resourceName: "plus_unselected"))
        
        let tabListController = TabListViewController()
        tabListController.displayUser = CurrentUser.user
        let tabListNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "list_unfilled"), selectedImage: #imageLiteral(resourceName: "list_unfilled"), rootViewController: tabListController)
        
        let layout = StickyHeadersCollectionViewFlowLayout()
        let userProfileController = UserProfileController(collectionViewLayout: layout)
        
        let userProfileNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "profile_unselected"), selectedImage: #imageLiteral(resourceName: "profile_selected"), rootViewController: userProfileController)
        tabBar.tintColor = .black

        viewControllers = [homeNavController, searchNavController, plusNavController, tabListNavController, userProfileNavController]
        
        //modify tab bar item insets
        
        guard let items = tabBar.items else {return}
        
        for item in items {
            item.imageInsets = UIEdgeInsets(top: 4, left: 0, bottom: -4, right: 0)
        }

        
       // viewControllers = [navController, UIViewController()]
    }
    
    
    fileprivate func templateNavController(unselectedImage: UIImage, selectedImage: UIImage, rootViewController: UIViewController = UIViewController()) -> UINavigationController
    {
    
    let viewController = rootViewController
    let navController = UINavigationController(rootViewController: viewController)
        navController.tabBarItem.image = unselectedImage
        navController.tabBarItem.selectedImage = selectedImage
        navController.navigationBar.barTintColor = UIColor.legitColor()
        navController.navigationBar.tintColor = UIColor.white
    
    return navController
    }
    
    
    func updateFirebaseData(){
        let firebaseAlert = UIAlertController(title: "Firebase Update", message: "Do you want to update Firebase Data?", preferredStyle: UIAlertControllerStyle.alert)
        
        firebaseAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            
            let ref = Database.database().reference().child("posts")
            
            ref.observeSingleEvent(of: .value, with: {(snapshot) in
                
                guard let userposts = snapshot.value as? [String:Any]  else {return}
                
                userposts.forEach({ (key,value) in
                    
                    guard let messageDetails = value as? [String: Any] else {return}
                    guard let selectedEmojis = messageDetails["emoji"] as? String else {return}
                    guard let creationDate = messageDetails["creationDate"] as? Double else {return}
                    
                    var fetchedTagDate = messageDetails["tagTime"] as? Double
                    var fetchedRatingEmoji = messageDetails["ratingEmoji"] as? String
                    var fetchedNonratingEmoji = messageDetails["nonRatingEmoji"] as? [String]
                    var fetchedNonratingEmojiTags = messageDetails["nonRatingEmojiTags"] as? [String]
                    var creatorUid = messageDetails["creatorUID"] as? String
                    
                    let tempEmojis = String(selectedEmojis.characters.prefix(1))
                    var selectedEmojisSplit = selectedEmojis.characters.map { String($0) }
                    
                    var newRatingEmoji: String? = nil
                    var newNonratingEmoji: [String]? = nil
                    var newNonratingEmojiTags: [String]? = nil
                    var newTagTime: Double? = nil
                    
                    print("Fetched Rating Emoji: ",fetchedRatingEmoji)
                    print("Fetched NonRating Emoji: ",fetchedNonratingEmoji)
                    print("Selected Emoji splits: ", selectedEmojisSplit)
                    
                    if (fetchedRatingEmoji == nil || fetchedRatingEmoji == "" || fetchedNonratingEmoji == nil) && selectedEmojisSplit != [] {
                        // Replace Rating emoji with First of NR emoji if its rating emoji
                        
                        if String(selectedEmojisSplit[0]).containsRatingEmoji {
                            print("First Emoji Char: ",tempEmojis)
                            newRatingEmoji = String(selectedEmojisSplit[0])
                            newNonratingEmoji = Array(selectedEmojisSplit.dropFirst(1))
                            newNonratingEmojiTags = Array(selectedEmojisSplit.dropFirst(1))
                            
                        } else {
                            newRatingEmoji = fetchedRatingEmoji
                            newNonratingEmoji = selectedEmojisSplit
                            newNonratingEmojiTags = selectedEmojisSplit
                        }
                    } else {
                        newRatingEmoji = fetchedRatingEmoji
                        newNonratingEmoji = fetchedNonratingEmoji
                        newNonratingEmojiTags = fetchedNonratingEmojiTags
                    }
                    
                    print("New R Emoji: ", newRatingEmoji, " New NR Emoji: ", newNonratingEmoji, " New NR Emoji Tags: ", newNonratingEmojiTags)
                    
                    if fetchedTagDate == nil {
                        newTagTime = creationDate
                        print("Update New Tag Time with: ", creationDate)
                    } else {
                        newTagTime = fetchedTagDate!
                    }
                    
                    let values = ["ratingEmoji": newRatingEmoji, "nonratingEmoji": newNonratingEmoji, "nonratingEmojiTags": newNonratingEmojiTags, "tagTime": newTagTime] as [String: Any]
                    
                    
                    print("Updating PostId: ",key," Values: ", values)
//                    Database.updatePostwithPostID(post: key, newDictionaryValues: values)
                    
                    var saveNewRatingEmoji = newRatingEmoji ?? ""
                    var saveNewNonratingEmoji = newNonratingEmoji?.joined() ?? ""
                    
                    let emojiString = String(saveNewRatingEmoji + saveNewNonratingEmoji)
                    
                    // Update User Posts
                    let userPostValues = ["tagTime": newTagTime, "emoji": emojiString] as [String: Any]
                    Database.updateUserPostwithPostID(creatorId: creatorUid!, postId: key, values: userPostValues)
                    
                    
                })
            })
        }))
        
        firebaseAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        self.present(firebaseAlert, animated: true)
    }
    
    
}
