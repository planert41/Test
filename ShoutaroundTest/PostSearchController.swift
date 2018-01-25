//
//  PostSearchController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/15/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
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

protocol PostSearchControllerDelegate {
    func filterCaptionSelected(searchedText: String?)
    func userSelected(uid: String?)
    func locationSelected(googlePlaceId: String?, googlePlaceName: String?, googlePlaceLocation: CLLocation?, googlePlaceType: [String]?)
}

class testSearchBar: UISearchBar {
    
    override init(frame: CGRect) {
        super.init(frame:frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

class PostSearchController : UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate, GMSAutocompleteTableDataSourceDelegate {
    
    var selectedScope = 0 {
        didSet{
            self.tableView.reloadData()
        }
    }
    var searchTerm: String? = nil
    
    // Emojis - Pulls in Default Emojis and Emojis filtered by searchText
    let EmojiCellId = "EmojiCellId"
    var filteredEmojis:[Emoji] = []
    
    // Users
    let UserCellId = "UserCellId"
    var allUsers = [User]()
    var filteredUsers = [User]()
    
    // Google Locations
    var tableDataSource: GMSAutocompleteTableDataSource?
    var selectedGoogleId: String? = nil
    var selectedGoogleLocationName: String? = nil
    var selectedGoogleLocation: CLLocation? = nil
    var selectedGoogleLocationType: [String]? = nil
    
    
    var googleLocations: [String] = []
    var googleLocationsId: [String] = []
    
    var isFiltering: Bool = false {
        didSet{
            self.tableView.reloadData()
        }
    }
    var delegate: PostSearchControllerDelegate?
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchBar = UISearchBar()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        tableView.backgroundColor = UIColor.white
        tableView.register(EmojiCell.self, forCellReuseIdentifier: EmojiCellId)
        tableView.register(UserCell.self, forCellReuseIdentifier: UserCellId)

        setupSearchController()
        
        
        // Emojis are loaded in the emoji dictionary
        
        // Load Users
        Database.fetchUsers { (fetchedUsers) in
            self.allUsers = fetchedUsers
            self.filteredUsers = self.allUsers
        }
        
        // Google Locations are only loaded when Locations are selected
        
        tableDataSource = GMSAutocompleteTableDataSource()
        tableDataSource?.delegate = self
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        
        
    }
    
    
    func setupSearchController(){
//        navigationController?.navigationBar.barTintColor = UIColor.white
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchBar = searchController.searchBar
        searchBar.scopeButtonTitles = searchScopeButtons
        searchBar.showsScopeBar = true
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.placeholder =  searchBarPlaceholderText
//        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.white
//        searchBar.backgroundColor = UIColor.legitColor()
        definesPresentationContext = true
        
        for s in searchBar.subviews[0].subviews {
            if s is UITextField {
                s.layer.borderWidth = 0.5
                s.layer.borderColor = UIColor.gray.cgColor
                s.layer.cornerRadius = 10
                s.layer.backgroundColor = UIColor.white.cgColor
            }
        }

        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling  = false
        } else {
            self.tableView.tableHeaderView = searchBar
        }
        
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
            
            // Google Locations - Data source changes to Google AutoComplete
            
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
            
            // Google Locations - Data source changes to Google AutoComplete
            
            
            // Null
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! EmojiCell
            return cell
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Emoji Selected
        if selectedScope == 0 {
            var emojiSelected: Emoji?
            if isFiltering {
                emojiSelected = filteredEmojis[indexPath.row]
            } else {
                emojiSelected = defaultEmojis[indexPath.row]
            }
            let filterText = emojiSelected?.emoji
            self.delegate?.filterCaptionSelected(searchedText: filterText)
            
            self.navigationController?.popViewController(animated: true)
        }
        
        // User Selected
        if selectedScope == 1 {
            var userSelected: User?
            if isFiltering {
                userSelected = filteredUsers[indexPath.row]
            } else {
                userSelected = allUsers[indexPath.row]
            }
            delegate?.userSelected(uid: userSelected?.uid)
//            self.navigationController?.popViewController(animated: true)
        }
        
        // Location Selected is handled by Google Autocomplete below
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
                tableDataSource?.sourceTextHasChanged(searchBar.text!)
            }
        }
    }
    
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.searchBar.sizeToFit()
        return true
    }

    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        self.searchBar.sizeToFit()
        return true
    }

    override func viewWillDisappear(_ animated: Bool) {
//      Remove Searchbar scope during transition
        self.searchBar.isHidden = true
//        navigationController?.navigationBar.barTintColor = UIColor.legitColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
//      Show Searchbar scope during transition
        self.searchBar.isHidden = false
//        navigationController?.navigationBar.barTintColor = UIColor.legitColor()


    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.searchController.searchBar.becomeFirstResponder()
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
        if !(searchBar.text?.isEmptyOrWhitespace())! {
            self.delegate?.filterCaptionSelected(searchedText: searchBar.text)
        } else {
            self.delegate?.filterCaptionSelected(searchedText: nil)
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if !(searchBar.text?.isEmptyOrWhitespace())! {
            self.delegate?.filterCaptionSelected(searchedText: searchBar.text)
        } else {
            self.delegate?.filterCaptionSelected(searchedText: nil)
        }
        searchBar.resignFirstResponder()

    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print("Selected Scope is: ", selectedScope)
        self.selectedScope = selectedScope
        
        if selectedScope == 0 || selectedScope == 1 {
            self.tableView.dataSource = self
            self.tableView.delegate = self
            if self.isFiltering && self.searchTerm != nil {
                filterContentForSearchText(self.searchTerm!)
            }
        }
        else if selectedScope == 2 {
            
            // Changes data source to Google Location Data Source when Location is selected
            self.tableView.dataSource = tableDataSource
            self.tableView.delegate = tableDataSource
        }
        self.tableView.reloadData()
    }
    
    func didUpdateAutocompletePredictionsForTableDataSource(tableDataSource: GMSAutocompleteTableDataSource) {
        // Turn the network activity indicator off.
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        // Reload table data.
        self.tableView.reloadData()
    }
    
    func didRequestAutocompletePredictionsForTableDataSource(tableDataSource: GMSAutocompleteTableDataSource) {
        // Turn the network activity indicator on.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        // Reload table data.
        self.tableView.reloadData()
    }
    
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didAutocompleteWith place: GMSPlace) {
        // Do something with the selected place.
        self.selectedGoogleId = place.placeID
        self.selectedGoogleLocationName = place.name
        self.selectedGoogleLocation = CLLocation.init(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        self.selectedGoogleLocationType = place.types
        
        print("Selected Google Location is: ", place.placeID, " name: ", place.name, "type: ", self.selectedGoogleLocationType, "GPS: ",self.selectedGoogleLocation)
        delegate?.locationSelected(googlePlaceId: self.selectedGoogleId, googlePlaceName: self.selectedGoogleLocationName,  googlePlaceLocation: self.selectedGoogleLocation, googlePlaceType: self.selectedGoogleLocationType)
        self.navigationController?.popViewController(animated: true)

        
    }
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didFailAutocompleteWithError error: Error) {
        // TODO: Handle the error.
        print("Error: \(error)")
    }
    
    
    
    
}
