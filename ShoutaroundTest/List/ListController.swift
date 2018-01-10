//
//  ListController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/7/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Firebase


class ListController: UITableViewController {
    
    var displayedList: [List]? = nil {
        didSet{
            if displayedList != nil {
                var tempListNameDic: [String:String] = [:]
                
                for list in displayedList! {
                    tempListNameDic[list.id!] = list.name
                }
                displayedListNameDictionary = tempListNameDic
            }
        }
    }
    
    // ListID: ListName Dictionary
    var displayedListNameDictionary: [String: String]? = [:] {
        didSet{
            displayedNames = []
            guard let displayedListNameDictionary = displayedListNameDictionary else {
                print("No Displayed List")
                return
            }
            
            // Check for Legit
            if displayedListNameDictionary.key(forValue: legitListName) != nil {
                displayedNames.append(legitListName)
            }
            
            // Check for Bookmark
            if displayedListNameDictionary.key(forValue: bookmarkListName) != nil{
                displayedNames.append(bookmarkListName)
            }
            
            for (key,value) in displayedListNameDictionary{
                if value != legitListName && value != bookmarkListName {
                    displayedNames.append(value)
                }
            }
            print(displayedNames)
        }
    }
    var displayedNames: [String] = []
    
    var displayedPost: Post? = nil
    var cellId = "cellId"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        self.navigationController?.navigationBar.tintColor = UIColor.blue
        self.navigationItem.title = "List"
        
        self.tableView.register(UITableViewCell, forCellReuseIdentifier: cellId)

    }
    

    // Tableview delegate functions
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return displayedNames.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
       
        cell.textLabel?.text = displayedNames[indexPath.row]
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // List Tag Selected
        guard let tagId = displayedListNameDictionary?.key(forValue: displayedNames[indexPath.row]) else {
            print("Fetch List Error: Can't find key")
            return
        }
        
        // Check if List Exist
        Database.fetchListforSingleListId(listId: tagId, completion: { (fetchedList) in
            if fetchedList == nil {
                // List Does not Exist
                self.alert(title: "List Error", message: "List Does Not Exist Anymore")
                
                if self.displayedPost != nil {
                    guard var tempPost = self.displayedPost else {
                        print("List Deleted Update For Post: ERROR, No Post")
                        return
                    }
                        // Delete Creator List in Post Database if Creator List does not exist anymore
                    if let deleteIndex = tempPost.creatorListId?.index(forKey: tagId) {
                            var updatePostListIds = tempPost.creatorListId?.remove(at: deleteIndex)
                        var tempPostDictionary = tempPost.dictionary()
                            tempPostDictionary["lists"] = updatePostListIds
                            print("Deleting \(tagId) list from \(tempPost.id) Post")
                            Database.updatePostwithPostID(post: tempPost, newDictionaryValues: tempPostDictionary)
                        }
                }
            } else {
                let listViewController = ListViewController()
                listViewController.displayListId = tagId
                listViewController.displayList = fetchedList
                self.navigationController?.pushViewController(listViewController, animated: true)
            }
            
        })
        
        
    }
    
    
    
    
}
