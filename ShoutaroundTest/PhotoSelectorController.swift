//
//  PhotoSelectorController.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/27/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import Photos
import CoreLocation


class PhotoSelectorController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    let cellID = "cellId"
    let headerID = "headerId"
    
    var images = [UIImage]()
    var selectedImage: UIImage?
    var assets = [PHAsset]()
    var locations = [CLLocation]()
    var selectedPhotoLocation: CLLocation?
    

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = .yellow
        setupNavigationButtons()
        
        collectionView?.register(PhotoSelectorCell.self, forCellWithReuseIdentifier: cellID)
        
        collectionView?.register(PhotoSelectorHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerID)
        
        
        fetchPhotos()

        
    }
    
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.selectedImage = images[indexPath.item]
        self.collectionView?.reloadData()
        self.selectedPhotoLocation = locations[indexPath.item]
        print(self.selectedPhotoLocation)
        
        let indexPath = IndexPath(item: 0, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)

        
    }

    
    fileprivate func assetFetchOptions() -> PHFetchOptions {
       
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 30
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchOptions.sortDescriptors = [sortDescriptor]
        return fetchOptions
        
    }
    
    fileprivate func fetchPhotos(){
        

        let allPhotos = PHAsset.fetchAssets(with: .image, options: assetFetchOptions())
     
    // Moves Process to Background
        
        DispatchQueue.global(qos: .background).async{
            
            allPhotos.enumerateObjects(using: { (asset, count, stop) in
                
                let imageManager = PHImageManager.default()
                let targetSize = CGSize(width: 200, height: 200)
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                var location: CLLocation
                
                
                if let location = asset.location as? CLLocation {
                        self.locations.append(location)
                } else {
                    location = CLLocation(latitude: 0, longitude: 0)
                    self.locations.append(location)

                }
                
                
                if self.selectedPhotoLocation == nil {
                    self.selectedPhotoLocation = self.locations.first
                }
                
                
                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { (image, info) in
 
                    
                    if let image = image {
                        
                        self.images.append(image)
                        self.assets.append(asset)


                        
                        
                        if self.selectedImage == nil {
                            self.selectedImage = image
                        }
                        
                
                    }
                    
                    // Reload collection view after # of pics match total num of pics
                    
                    if count == allPhotos.count - 1 {
                        
                        // Has to get back on main thread to make things faster
                        
                        DispatchQueue.main.async {
                        self.collectionView?.reloadData()
                        }
                    }
                    
                    
                })
                
            })
            
        }
        

        
    }
    

    var header: PhotoSelectorHeader?
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerID, for: indexPath) as! PhotoSelectorHeader
        
        self.header = header
        header.photoImageView.image = selectedImage
        
        if let selectedImage = selectedImage {
        
            if let index = self.images.index(of: selectedImage) {
            
                let selectedAsset = self.assets[index]
                
                let imageManager = PHImageManager.default()
                let targetSize = CGSize(width: 600, height: 600)
                
                
                imageManager.requestImage(for: selectedAsset, targetSize: targetSize, contentMode: .default, options: nil, resultHandler: { (image, info) in
                    
                header.photoImageView.image  = image
                    
                })
            
            }
        }
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let width = view.frame.width
        return CGSize(width: width, height: width)
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! PhotoSelectorCell
        
        cell.photoImageView.image = images[indexPath.item]


        
        return cell
    
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 3)/4
        let height = view.frame.height
        
        return CGSize(width: width, height: width)
    }

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    
    
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    fileprivate func setupNavigationButtons() {
        navigationController?.navigationBar.tintColor = .black
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
         navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(handleNext))
        
        
    }
    
    func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    func handleNext() {
        
        let sharePhotoController = SharePhotoController()
        sharePhotoController.selectedImage = header?.photoImageView.image
        sharePhotoController.selectedImageLocation  = selectedPhotoLocation
        navigationController?.pushViewController(sharePhotoController, animated: true)
        
        
        print("Handle Next")
    }



}
