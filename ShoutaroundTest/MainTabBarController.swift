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
    
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        let index = viewControllers?.index(of: viewController)
        
        if index == 2 {

        _ = UICollectionViewFlowLayout()
        // Add photo function selected
            
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    
            alertController.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (_) in
                self.presentCamera()
            }))
            
            alertController.addAction(UIAlertAction(title: "Photo Roll", style: .default, handler: { (_) in
                self.presentImagePicker()
            }))

            alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (_) in
                self.dismiss(animated: true, completion: nil)
            }))
            
            present(alertController, animated: true) {
                // Works if you tag subview for tabbarcontroller
                alertController.view.superview?.subviews[1].isUserInteractionEnabled = true
                let cancelTap = UITapGestureRecognizer(target: self, action:#selector(self.alertClose(gesture:)))
                alertController.view.superview?.subviews[1].addGestureRecognizer(cancelTap)
                print(alertController.view.superview?.subviews)

            }
            
//            imagePicker.allowsEditing = true
//            imagePicker.sourceType = .photoLibrary
//            imagePicker.delegate = self
//            imagePicker.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
//            present(imagePicker, animated: true, completion: nil)
//
//            let photoSelectorController = PhotoSelectorControllerDummy()
//            let navController = UINavigationController(rootViewController: photoSelectorController)
//            
//            present(navController, animated: true, completion: nil)
            
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
            imagePicker.allowsEditing = false
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
        
        setupViewControllers()
    
    }
    

    
    func setupViewControllers() {
        
        // home
        
        let homeNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "home_unselected"), selectedImage: #imageLiteral(resourceName: "home_selected"), rootViewController: HomeController(collectionViewLayout: UICollectionViewFlowLayout()))
        
        // search
//        let searchNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "search_unselected"), selectedImage: #imageLiteral(resourceName: "search_selected"), rootViewController: UserSearchController(collectionViewLayout: UICollectionViewFlowLayout()))
        let searchNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "search_unselected"), selectedImage: #imageLiteral(resourceName: "search_selected"), rootViewController: ExploreController())
        
        
        let plusNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "plus_unselected"), selectedImage: #imageLiteral(resourceName: "plus_unselected"))
        
        let likeNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "like_unselected"), selectedImage: #imageLiteral(resourceName: "like_selected"), rootViewController:  BookMarkController())
        
        //Bookmark
        
        let bookmarkLayout = UICollectionViewFlowLayout()
        let bookmarkController = BookMarkController()
        let bookmarkNavController = UINavigationController(rootViewController: bookmarkController)
        bookmarkNavController.tabBarItem.image = #imageLiteral(resourceName: "bookmark_ribbon_unfilled").withRenderingMode(.alwaysOriginal)
        bookmarkNavController.tabBarItem.selectedImage = #imageLiteral(resourceName: "bookmark_ribbon_filled").withRenderingMode(.alwaysOriginal)
        
        
        //user profile
        
        let layout = StickyHeadersCollectionViewFlowLayout()
        let userProfileController = UserProfileController(collectionViewLayout: layout)
        let userProfileNavController = UINavigationController(rootViewController: userProfileController)        
        
        userProfileNavController.tabBarItem.image = #imageLiteral(resourceName: "profile_unselected")
        userProfileNavController.tabBarItem.selectedImage = #imageLiteral(resourceName: "profile_selected")
        
        tabBar.tintColor = .black

        viewControllers = [homeNavController, searchNavController, plusNavController, bookmarkNavController, userProfileNavController]
        
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
    
        return navController
    }
    
}
