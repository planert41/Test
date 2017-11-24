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

var defaultPhotoResize = CGSize(width: 500, height: 500)

// Filter Defaults

var FilterSortTimeDefault:[String] = ["Early", "Mid-Day", "Night", "All"]
var FilterSortTimeStart:[Double] = [6,12,18,0]
var FilterSortTimeEnd:[Double] = [12,18,23,23]
var FilterSortDefault:[String] = ["Nearest", "Oldest", "Latest"]

let defaultRange = geoFilterRangeDefault[geoFilterRangeDefault.endIndex - 1]
let defaultGroup = "All"
let defaultSort = FilterSortDefault[FilterSortDefault.endIndex - 1]
let defaultTime =  FilterSortTimeDefault[FilterSortTimeDefault.endIndex - 1]

// Search Bar Defaults


var searchBarPlaceholderText = "Search...."
var searchScopeButtons = ["Posts","Users","Places"]

// Rank Defaults

var defaultRankOptions = ["likes", "bookmarks", "messages"]
var firebaseCountVariable:[String:String] = ["likes":"likeCount", "bookmarks":"bookmarkCount", "messages":"messageCount"]

struct Common {

}
