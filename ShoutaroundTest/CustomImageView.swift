//
//  CustomImageView.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit

var imageCache = [String: UIImage]()

class CustomImageView: UIImageView {
    
    var lastURLToLoadImage: String?
    
    
    func loadImage(urlString: String) {
        guard let url = URL(string: urlString) else {return}
        let urlRequest = URLRequest(url: url)
        
        self.setImageWith(urlRequest, placeholderImage: nil, success: { (request, response, image) in
            let photoImage = image?.resizeImageWith(newSize: defaultPhotoResize)
            self.image = photoImage
            imageCache[url.absoluteString] = photoImage
            
        }, failure: { (request, response, error) in
            if let error = error {
                print("Error fetching photo from URL: \(error)")
            }
        })
    }

//    func loadImageOLD(urlString: String) {
//        
//        lastURLToLoadImage = urlString
//        
//        self.image = nil
//        
//        if let cachedImage = imageCache[urlString] {
//            
//            self.image = cachedImage
//            return
//        }
//        
//        guard let url = URL(string: urlString) else {return}
//        
//        URLSession.shared.dataTask(with: url) { (data, response, err) in
//            if let err = err {
//                print("Failed to fetch post image:", err)
//                return
//            }
//            
//            if url.absoluteString != self.lastURLToLoadImage {
//                return
//            }
//            
//            guard let imageData = data else {return}
//            let photoImage = UIImage(data: imageData)?.resizeImageWith(newSize: defaultPhotoResize)
//            imageCache[url.absoluteString] = photoImage
//            
//            DispatchQueue.main.async {
//                self.image = photoImage
//            }
//            
//            }.resume()
//    }

    
}
