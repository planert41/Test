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
    
    var displayedPost: Post? = nil
    var displayedList: [String: String]? = [:] {
        didSet{
            displayedNames = []
            guard let displayedList = displayedList else {
                print("No Displayed List")
                return
            }
            for (key,value) in displayedList{
                displayedNames.append(value)
            }
            print(displayedNames)
        }
    }
    var displayedNames: [String] = []

    var cellId = "cellId"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        self.navigationController?.navigationBar.tintColor = UIColor.blue
        self.navigationItem.title = "Tagged List"
        
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
        guard let tagId = displayedList?.key(forValue: displayedNames[indexPath.row]) else {
            print("Fetch List Error: Can't find key")
            return
        }
        
        // Check if List Exist
        Database.fetchListforSingleListId(listId: tagId, completion: { (fetchedList) in
            if fetchedList == nil {
                // List Does not Exist
                self.alert(title: "List Error", message: "List Does Not Exist Anymore")
                guard var tempPost = self.displayedPost else {
                    print("No Attached Post Error")
                    return
                }
                
                // Update list from Post
                if let deleteIndex = tempPost.creatorListId?.index(forKey: tagId) {
                    var updatePostListIds = tempPost.creatorListId?.remove(at: deleteIndex)
                    var tempPostDictionary = tempPost.dictionary()
                    tempPostDictionary["lists"] = updatePostListIds
                    print("Deleting \(tagId) list from \(tempPost.id) Post")
                    Database.updatePostwithPostID(post: tempPost, newDictionaryValues: tempPostDictionary)
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
