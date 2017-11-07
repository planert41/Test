//
//  CommonSettings.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/20/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit


 var geoFilterImageDefault:[UIImage] = [#imageLiteral(resourceName: "GeoFence"),#imageLiteral(resourceName: "GeoFence"), #imageLiteral(resourceName: "City"), #imageLiteral(resourceName: "City"), #imageLiteral(resourceName: "Globe")]

 var geoFilterRangeDefault:[String] = ["5", "25", "100","250", "All"]

var FilterSortTimeDefault:[String] = ["Early", "Mid-Day", "Night", "All"]
var FilterSortTimeStart:[Double] = [6,12,18,0]
var FilterSortTimeEnd:[Double] = [12,18,23,23]


var FilterSortDefault:[String] = ["Nearest", "Oldest", "Latest"]

var defaultPhotoResize = CGSize(width: 500, height: 500)

var searchBarPlaceholderText = "Search...."
