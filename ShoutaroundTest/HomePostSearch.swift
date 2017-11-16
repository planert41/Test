//
//  HomePostSearch.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/17/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import GooglePlaces

protocol HomePostSearchDelegate {
    func filterCaptionSelected(searchedText: String?)
    
}

class HomePostSearch : UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    
    var selectedScope = 0
    var searchTerm: String? = nil

    // Emojis - Pulls in Default Emojis and Emojis filtered by searchText
    let EmojiCellId = "EmojiCellId"
    var filteredEmojis:[Emoji] = []
    
    // Users
    let UserCellId = "UserCellId"
    var allUsers = [User]()
    var filteredUsers = [User]()
    
    // Google Locations
    let LocationCellId = "LocationCellId"
    var placesClient = GMSPlacesClient()
    var googleLocations: [String] = []
    var googleLocationsId: [String] = []
    
    var isFiltering: Bool = false {
        didSet{
            self.tableView.reloadData()
        }
    }
    var delegate: HomePostSearchDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        tableView.register(EmojiCell.self, forCellReuseIdentifier: EmojiCellId)
        tableView.register(UserCell.self, forCellReuseIdentifier: UserCellId)
        tableView.register(LocationCell.self, forCellReuseIdentifier: LocationCellId)
        
        // Emojis are loaded in the emoji dictionary
        
        // Load Users
        Database.fetchUsers { (fetchedUsers) in
            self.allUsers = fetchedUsers
            self.filteredUsers = self.allUsers
        }
        
        // Google Locations are only loaded when Locations are selected
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Emojis
        if self.selectedScope == 0 {
            if isFiltering {
                return filteredEmojis.count
            }   else {
                return defaultEmojis.count
            }
        }
        
        // Users
        else if self.selectedScope == 1 {
            if isFiltering {
                return filteredUsers.count
            } else {
                return allUsers.count
            }
        }
        
        // Google Locations
        else if self.selectedScope == 2 {
            if isFiltering {
                return googleLocations.count
            } else {
                return 0
            }
        }
        
        else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Emojis
        if self.selectedScope == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! EmojiCell
            
            if isFiltering{
                cell.emoji = filteredEmojis[indexPath.row]
            } else {
                cell.emoji = defaultEmojis[indexPath.row]
            }
            return cell
        }
        // Users
        
        else if self.selectedScope == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: UserCellId, for: indexPath) as! UserCell
            if isFiltering{
                cell.user = filteredUsers[indexPath.row]
            } else {
                cell.user = allUsers[indexPath.row]
            }
            return cell
        }
        
        // Locations
        
        else if self.selectedScope == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: LocationCellId, for: indexPath) as! LocationCell
                cell.location = googleLocations[indexPath.row]
            return cell
        }
            
        // Null
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! EmojiCell
            return cell
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var emojiSelected: Emoji?
        
        if isFiltering {
            emojiSelected = filteredEmojis[indexPath.row]
        } else {
            emojiSelected = defaultEmojis[indexPath.row]
        }
        
        let filterText = emojiSelected?.emoji
        self.delegate?.filterCaptionSelected(searchedText: filterText)
        
        self.dismiss(animated: true) { 
        }

    }
    
    
    func filterContentForSearchText(_ searchText: String) {
        // Filter for Emojis and Users
        
        // Emojis
        if self.selectedScope == 0 {
            filteredEmojis = allEmojis.filter({( emoji : Emoji) -> Bool in
                return emoji.emoji.lowercased().contains(searchText.lowercased()) || (emoji.name?.contains(searchText.lowercased()))! })
            filteredEmojis.sort { (p1, p2) -> Bool in
            ((p1.name?.hasPrefix(searchText.lowercased()))! ? 0 : 1) < ((p2.name?.hasPrefix(searchText.lowercased()))! ? 0 : 1)
            }
        }
        
        // Users
        else if self.selectedScope == 1 {
            filteredUsers = self.allUsers.filter { (user) -> Bool in
                return user.username.lowercased().contains(searchText.lowercased())
            }
        }
        self.tableView.reloadData()
    }
    
    func clearGoogleLocations(){
        googleLocations = []
        googleLocationsId = []
    }
    
    func placeAutocomplete(searchString: String) {
        
        
        let myGroup = DispatchGroup()
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
        placesClient.autocompleteQuery(searchString, bounds: nil, filter: filter, callback: {(results, error) -> Void in
            if let error = error {
                print("Autocomplete error \(error)")
                return
            }
            self.clearGoogleLocations()
            if let results = results {
                for result in results {
                    myGroup.enter()
                    print(result)
                    self.googleLocations.append(result.attributedFullText.string)
                    self.googleLocationsId.append(result.placeID!)
                    myGroup.leave()
                }
            }
            
            myGroup.notify(queue: .main) {
            print("Google Search Results: ", self.googleLocations)
            self.tableView.reloadData()
            }
        })
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        // Updates Search Results as searchbar is populated
        let searchBar = searchController.searchBar
        if (searchBar.text?.isEmpty)! {
            // Displays Default Search Results even if search bar is empty
            self.isFiltering = false
            searchController.searchResultsController?.view.isHidden = false
        }
        
        self.isFiltering = searchController.isActive && !(searchBar.text?.isEmpty)!
        
        if self.isFiltering {
            if self.selectedScope == 0 || self.selectedScope == 1 {
                filterContentForSearchText(searchBar.text!)
            } else if self.selectedScope == 2 {
                self.placeAutocomplete(searchString: searchBar.text!)
            }
        }
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchBar.text?.isEmpty)! {
            self.searchTerm = nil
            self.isFiltering = false
        } else {
            self.isFiltering = true
            self.searchTerm = searchText
        }
    }
  
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.delegate?.filterCaptionSelected(searchedText: searchBar.text)
        self.dismiss(animated: true) {
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.delegate?.filterCaptionSelected(searchedText: searchBar.text)
        self.dismiss(animated: true) {
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print("Selected Scope is: ", selectedScope)
        self.selectedScope = selectedScope
        
        if selectedScope == 0 || selectedScope == 1 {
            if self.isFiltering && self.searchTerm != nil {
                filterContentForSearchText(self.searchTerm!)
            }
        }
        else if selectedScope == 2 {
            if self.isFiltering && self.searchTerm != nil {
                self.placeAutocomplete(searchString: self.searchTerm!)
            }
        }
        self.tableView.reloadData()
    }
    
    
    
}
