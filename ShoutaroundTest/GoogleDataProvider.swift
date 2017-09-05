//
//  GoogleDataProvider.swift
//  Main_2
//
//  Created by Wei Zou Ang on 7/2/16.
//  Copyright © 2016 Wei Zou Ang. All rights reserved.
//

//
//  GoogleDataProvider.swift
//  Feed Me
//
/*
 * Copyright (c) 2015 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import Foundation
import CoreLocation
import SwiftyJSON

class GoogleDataProvider {
    var photoCache = [String:UIImage]()
    var placesTask: URLSessionDataTask?
    var session: URLSession {
        return URLSession.shared
    }
    
    func fetchPlacesNearCoordinate(_ coordinate: CLLocation, radius: Double, types:[String], completion: @escaping (([GooglePlace]) -> Void)) -> ()
    {
        var urlString = "http://localhost:10000/maps/api/place/nearbysearch/json?location=\(coordinate.coordinate.latitude),\(coordinate.coordinate.longitude)&radius=\(radius)&rankby=prominence&sensor=true"
        let typesString = types.count > 0 ? types.joined(separator: "|") : "food"
        urlString += "&types=\(typesString)"
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if let task = placesTask, task.taskIdentifier > 0 && task.state == .running {
            task.cancel()
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        placesTask = session.dataTask(with: URL(string: urlString)!, completionHandler: {data, response, error in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            var placesArray = [GooglePlace]()
            if let aData = data {
                let json = JSON(data:aData, options:JSONSerialization.ReadingOptions.mutableContainers, error:nil)
                if let results = json["results"].arrayObject as? [[String : AnyObject]] {
                    for rawPlace in results {
                        let place = GooglePlace(dictionary: rawPlace, acceptedTypes: types)
                        placesArray.append(place)
                        if let reference = place.photoReference {
                            self.fetchPhotoFromReference(reference) { image in
                                place.photo = image
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                completion(placesArray)
            }
        })
        placesTask?.resume()
    }
    
    
    func fetchPhotoFromReference(_ reference: String, completion: @escaping ((UIImage?) -> Void)) -> () {
        if let photo = photoCache[reference] as UIImage? {
            completion(photo)
        } else {
            let urlString = "http://localhost:10000/maps/api/place/photo?maxwidth=200&photoreference=\(reference)"
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            session.downloadTask(with: URL(string: urlString)!, completionHandler: {url, response, error in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if let url = url {
                    let downloadedPhoto = UIImage(data: try! Data(contentsOf: url))
                    self.photoCache[reference] = downloadedPhoto
                    DispatchQueue.main.async {
                        completion(downloadedPhoto)
                    }
                }
                else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }) .resume()
        }
    }
}
