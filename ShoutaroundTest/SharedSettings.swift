//
//  CommonSettings.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/20/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit


var DefaultListNonRepeat = 0

var geoFilterImageDefault:[UIImage] = [#imageLiteral(resourceName: "GeoFence"),#imageLiteral(resourceName: "GeoFence"), #imageLiteral(resourceName: "City"), #imageLiteral(resourceName: "City"), #imageLiteral(resourceName: "Globe")]
var geoFilterRangeDefault:[String] = ["1", "3", "5", "25", "50", "100"]

var rankRangeDefaultOptions :[String] = ["Global","1", "3", "5", "25", "50", "100"]
var globalRangeDefault: String = "Global"
var defaultGeoWaitTime: Double = 0.5

var defaultPhotoResize = CGSize(width: 500, height: 500)
var defaultEmptyGPSName: String = "No Location"

var legitListName: String = "Legit"
var bookmarkListName: String = "Bookmarks"
var emptyBookmarkList = List.init(id: nil, name: "Bookmarks", publicList: 0)
var emptyLegitList = List.init(id: nil, name: "Legit", publicList: 1)
var defaultListNames:[String] = ["Bookmarks", "Legit"]

// Upload Defaults
var UploadPostTypeDefault:[String] = ["Brunch", "Lunch", "Dinner", "Late", "Coffee"]
var UploadPostPriceDefault:[String] = ["$5", "$10", "$20", "$35", "$50", "$$$"]

// Home Header Sort Defaults
var HeaderSortOptions:[String] = ["Recent", "Nearest", "Trending"]
let HeaderSortDefault:String = HeaderSortOptions[0]

// Location Header Sort - 
var LocationSortOptions:[String] = ["Recent", "Rating", "Trending"]

// Rank Defaults
var defaultRankOptions = ["Recent", "Votes", "Lists", "Messages"]
var defaultRank = defaultRankOptions[0]


// Filter Defaults

var FilterRatingDefault:[Int] = [1,2,3,4,5,6,7]
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
var searchScopeButtons = ["Emojis","Users","Places"]





var firebaseCountVariable:[String:String] = ["likes":"likeCount", "Messages":"messageCount", "Lists": "listCount", "Votes": "voteCount"]
var firebaseFieldVariable:[String:String] = [ "Votes": "post_votes", "Messages":"post_messages", "Lists": "post_lists", ]


struct RatingColors {
    static func ratingColor (rating: Double?) -> UIColor {
        
        guard let rating = rating else {
            return UIColor.white
        }
        
        if rating == 0 {
            return UIColor.white    }
        else if rating <= Double(1) {
            return UIColor.rgb(red: 227, green: 27, blue: 35)   }
        else if rating <= Double(2) {
            return UIColor.rgb(red: 227, green: 27, blue: 35).withAlphaComponent(0.55)  }
        else if rating <= Double(3) {
            return UIColor.rgb(red: 255, green: 173, blue: 0).withAlphaComponent(0.55)  }
        else if rating <= Double(4) {
            return UIColor.rgb(red: 255, green: 173, blue: 0)   }
        else if rating <= Double(5) {
            return UIColor.rgb(red: 252, green: 227, blue: 0).withAlphaComponent(0.55)  }
        else if rating <= Double(6) {
            return UIColor.rgb(red: 252, green: 227, blue: 0)   }
        else if rating <= Double(7) {
            return UIColor.rgb(red: 91, green: 197, blue: 51)    }
        else {
            return UIColor.clear
        }
    }
}


struct Common {

}
