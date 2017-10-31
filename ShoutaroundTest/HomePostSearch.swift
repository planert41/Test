//
//  HomePostSearch.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/17/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit

protocol HomePostSearchDelegate {
    func filterCaptionSelected(searchedText: String?)
    
}

class HomePostSearch : UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    
    var defaultEmojis:[Emoji] = []
    var filteredEmojis:[Emoji] = []
    let EmojiCellId = "EmojiCellId"
    var isFiltering: Bool = false {
        didSet{
            self.tableView.reloadData()
        }
    }
    var delegate: HomePostSearchDelegate?
    
    
    let emojiDictionary: UILabel = {
        let label = UILabel()
        label.text = "Emoji Dictionary"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.mainBlue()
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        tableView.register(EmojiCell.self, forCellReuseIdentifier: EmojiCellId)
        
        for emoji in defaultEmojiSelection {
            
            let tempEmoji = Emoji(emoji: emoji, name: EmojiDictionary[emoji])
            defaultEmojis.append(tempEmoji)
        }
        
        
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredEmojis.count
        }
        else {
        return defaultEmojis.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EmojiCellId, for: indexPath) as! EmojiCell
        
        if isFiltering{
            cell.emoji = filteredEmojis[indexPath.row]
        } else {
        
        cell.emoji = defaultEmojis[indexPath.row]
        }
        
        return cell
        
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
        filteredEmojis = defaultEmojis.filter({( emoji : Emoji) -> Bool in
            
        return emoji.emoji.lowercased().contains(searchText.lowercased()) || (emoji.name?.contains(searchText.lowercased()))!
        })
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        
        if (searchBar.text?.isEmpty)! {
            self.isFiltering = false
            searchController.searchResultsController?.view.isHidden = false
        }
        
        self.isFiltering = searchController.isActive && !(searchBar.text?.isEmpty)!
        
        if self.isFiltering {
        filterContentForSearchText(searchBar.text!)
        }
    
    
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchBar.text?.isEmpty)! {
            self.isFiltering = false
            self.tableView.reloadData()
            
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
    
    
    
}
