//
//  PhotoSelectorControllerDummy.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/20/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import Photos

class PhotoSelectorControllerDummy: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var locations = [CLLocation]()
    var selectedPhotoLocation: CLLocation?
    let imagePicker = UIImagePickerController()
    var selectedImage: UIImage?
    var assets = [PHAsset]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        present(imagePicker, animated: true, completion: nil)
        
    
    }
    
    override func viewDidAppear(_ animated: Bool) {

//        imagePicker.allowsEditing = false
//        imagePicker.sourceType = .photoLibrary
//        imagePicker.delegate = self
//        present(imagePicker, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: { () in
            if (picker.sourceType == .photoLibrary) {
                
                
                let image = info[UIImagePickerControllerOriginalImage] as! UIImage
                var url: NSURL = info[UIImagePickerControllerReferenceURL] as! NSURL
                
                self.selectedImage = image
                
                if let URL = info[UIImagePickerControllerReferenceURL] as? URL {
                    let opts = PHFetchOptions()
                    opts.fetchLimit = 1
                    let assets = PHAsset.fetchAssets(withALAssetURLs: [URL], options: opts)
                    let asset = assets[0]
                    self.selectedPhotoLocation = asset.location
                    // The location is "asset.location", as a CLLocation
                    
                    // ... Other stuff like dismiss omitted
                }
                
                let sharePhotoController = SharePhotoController()
                sharePhotoController.selectedImage = self.selectedImage
                sharePhotoController.selectedImageLocation  = self.selectedPhotoLocation
                self.navigationController?.pushViewController(sharePhotoController, animated: true)
                
                
                print("Handle Next")
                
            }
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {

        self.dismiss(animated: true, completion: nil)
        self.navigationController?.popToRootViewController(animated: true)
        
    }

    
    
    
    
}
