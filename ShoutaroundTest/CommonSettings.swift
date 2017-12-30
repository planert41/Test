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
var defaultEmptyGPSName: String = "No Location"

var emptyBookmarkList = List.init(id: nil, name: "Bookmarks")
var emptyLegitList = List.init(id: nil, name: "Legit")
var defaultListNames:[String] = ["Bookmarks", "Legit"]

// Upload Defaults
var UploadPostTypeDefault:[String] = ["Breakfast", "Lunch", "Dinner", "Snack"]
var UploadPostPriceDefault:[String] = ["$5", "$10", "$20", "$35", "$50", "$$$"]

// Header Sort Defaults
var HeaderSortOptions:[String] = ["Recent", "Nearest", "Trending"]
let HeaderSortDefault:String = HeaderSortOptions[0]



// Filter Defaults

var FilterSortTimeDefault:[String] = ["Breakfast", "Lunch", "Dinner", "All"]
var FilterSortTimeStart:[Double] = [6,12,18,0]
var FilterSortTimeEnd:[Double] = [12,18,23,23]
var FilterSortDefault:[String] = ["Nearest", "Oldest", "Recent"]

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
