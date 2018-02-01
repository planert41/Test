//
//  ManageListController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/28/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class ManageListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    
    var displayList: [List] = []
    var displayListNames: [String] = []
    let listCellId = "ListCellId"
    var tableEdit: Bool = false

    let addListView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    lazy var addListTextField: PaddedTextField = {
        let tf = PaddedTextField()
        tf.font = UIFont.systemFont(ofSize: 14.0)
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.legitColor().cgColor
        tf.backgroundColor = UIColor(white: 1, alpha: 0.03)
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.layer.cornerRadius = 10
        tf.layer.masksToBounds = true
        tf.placeholder = "Eg: Chicago, Ramen"
        tf.delegate = self
        return tf
    }()
    
    let addListButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create List", for: .normal)
        button.titleLabel?.textColor = UIColor.legitColor()
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        
//        button.setImage(#imageLiteral(resourceName: "add").withRenderingMode(.alwaysOriginal), for: .normal)
//        button.imageView?.contentMode = .scaleAspectFit
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.white
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.legitColor().cgColor
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.layer.cornerRadius = 10

        button.addTarget(self, action: #selector(addList), for: .touchUpInside)
        return button
    } ()
    
    lazy var tableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.estimatedRowHeight = 100
        tv.allowsMultipleSelection = false
        return tv
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationItems()
        
        view.addSubview(addListView)
        addListView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        addListView.backgroundColor = UIColor.legitColor()
        
        view.addSubview(addListButton)
        addListButton.anchor(top: nil, left: nil, bottom: nil, right: addListView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 10, width: 80, height: 30)
        addListButton.centerYAnchor.constraint(equalTo: addListView.centerYAnchor).isActive = true

        
        view.addSubview(addListTextField)
        addListTextField.anchor(top: nil, left: addListView.leftAnchor, bottom: nil, right: addListButton.leftAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 5, width: 0, height: 30)
        addListTextField.centerYAnchor.constraint(equalTo: addListView.centerYAnchor).isActive = true
        addListTextField.placeholder = "ex: Chicago, Ramen, Travel"
        addListTextField.backgroundColor = UIColor.white
        
        
        tableView.register(UploadListCell.self, forCellReuseIdentifier: listCellId)
        view.addSubview(tableView)
        tableView.anchor(top: addListView.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshList), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.alwaysBounceVertical = true
        tableView.keyboardDismissMode = .onDrag
        
        setupLists()
        
    }
    
    func setupNavigationItems(){
        navigationItem.title = "Manage Lists"
        let editButton = UIBarButtonItem(image: (self.tableEdit ? #imageLiteral(resourceName: "list_tab_unfill") : #imageLiteral(resourceName: "delete")).withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(editList))
        navigationItem.rightBarButtonItem = editButton
    }
    
    
    func editList(){
        if !self.tableEdit{
            self.tableView.setEditing(true, animated: true)
            print("Table Editing")
        } else {
            self.tableView.setEditing(false, animated: true)
            print("Table Not Editing")
        }
        self.tableEdit = !self.tableEdit
        setupNavigationItems()
    }
    
    func refreshList(){
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
    }
    
    func setupLists(){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        Database.fetchCurrentUser {
            self.sortList(inputList: CurrentUser.lists, completion: { (sortedList) in
                self.displayList = sortedList
          
                // Update List Names
                var tempListNames: [String] = []
                for list in self.displayList {
                    var listName = "\(list.name) (\(list.postIds?.count)!)"
                    tempListNames.append(listName)
                }
                self.displayListNames = tempListNames
                self.tableView.reloadData()
                }
            )
        }
    }
    
    func sortList(inputList: [List]?, completion: @escaping ([List]) -> ()){
        
        var tempList: [List] = []
        guard let inputList = inputList else {
            print("Sort List: ERROR, No List")
            completion([])
            return
        }
        
        inputList.sorted(by: { (p1, p2) -> Bool in
            return p1.creationDate.compare(p2.creationDate) == .orderedAscending
        })
        
        // Check For Legit
        if let index = inputList.index(where: {$0.name == legitListName}){
            tempList.append(inputList[index])
        }
        
        //Check For Bookmark
        if let index = inputList.index(where: {$0.name == bookmarkListName}){
            tempList.append(inputList[index])
        }
        
        // Add Others
        for list in inputList {
            if !tempList.contains(where: {$0.id == list.id}){
                tempList.append(list)
            }
        }
        
        completion(tempList)
        
    }
    
    func addList(){
        let listId = NSUUID().uuidString
        guard let uid = Auth.auth().currentUser?.uid else {return}
        checkListName(listName: addListTextField.text) { (listName) in
            
            let optionsAlert = UIAlertController(title: "Create New List", message: "", preferredStyle: UIAlertControllerStyle.alert)
            
            optionsAlert.addAction(UIAlertAction(title: "Public", style: .default, handler: { (action: UIAlertAction!) in
                // Create Public List
                let newList = List.init(id: listId, name: listName, publicList: 1)
                self.createList(newList: newList)
            }))
            
            optionsAlert.addAction(UIAlertAction(title: "Private", style: .default, handler: { (action: UIAlertAction!) in
                // Create Private List
                let newList = List.init(id: listId, name: listName, publicList: 0)
                self.createList(newList: newList)
            }))
            
            optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                print("Handle Cancel Logic here")
            }))
            self.present(optionsAlert, animated: true, completion: {
                self.addListTextField.resignFirstResponder()
            })
        }
    }
    
    func createList(newList: List){
        // Create New List in Database
        Database.createList(uploadList: newList)
        
        self.displayList.append(newList)
        self.tableView.reloadData()
        self.addListTextField.text?.removeAll()
    }
    
    func checkListName(listName: String?, completion: @escaping (String) -> ()){
        guard let listName = listName else {
            self.alert(title: "New List Requirement", message: "Please Insert List Name")
            return
        }
        if listName.isEmptyOrWhitespace() {
            self.alert(title: "New List Requirement", message: "Please Insert List Name")
            return
        }
        
        if displayList.contains(where: { (displayList) -> Bool in
            return displayList.name.lowercased() == listName.lowercased()
        }) {
            self.alert(title: "Duplicate List Name", message: "Please Insert Different List Name")
            return
        }
        
        completion(listName)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        addListTextField.resignFirstResponder()
        self.addList()
        return true
    }
    
    
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: listCellId, for: indexPath) as! UploadListCell
        
        cell.list = displayList[indexPath.row]
        cell.isListManage = true

        
        // select/deselect the cell
        if displayList[indexPath.row].isSelected {
            if !cell.isSelected {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        } else {
            if cell.isSelected {
                tableView.deselectRow(at: indexPath, animated: false)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let listViewController = ListViewController()
        listViewController.currentDisplayList = displayList[indexPath.row]
        self.navigationController?.pushViewController(listViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
//        displayList[indexPath.row].isSelected = false
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        // Prevents Full Swipe Delete
        if tableView.isEditing{
            return .delete
        }
        return .none
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//        print("Trigger")
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            // Check For Default List
            if (defaultListNames.contains(where: { (listNames) -> Bool in
                listNames == self.displayList[indexPath.row].name})){
                self.alert(title: "Delete List Error", message: "Cannot Delete Default List: \(self.displayList[indexPath.row].name)")
                return
            }
            var list = self.displayList[indexPath.row]
            
            self.displayList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // Delete List in Database
            Database.deleteList(uploadList: list)
            
        }
        
        let edit = UITableViewRowAction(style: .default, title: "Edit") { (action, indexPath) in
            // Check For Default List
            if (defaultListNames.contains(where: { (listNames) -> Bool in
                listNames == self.displayList[indexPath.row].name})){
                self.alert(title: "Edit List Error", message: "Cannot Edit Default List: \(self.displayList[indexPath.row].name)")
                return
            }
            
            print("I want to change: \(self.displayList[indexPath.row])")
            
            
            //1. Create the alert controller.
            let alert = UIAlertController(title: "Change List Name", message: "Enter a New Name", preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            alert.addTextField { (textField) in
                textField.text = self.displayList[indexPath.row].name
            }
            
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                print("Text field: \(textField?.text)")
                
                // Change List Name
                self.checkListName(listName: textField?.text, completion: { (listName) in
                    self.displayList[indexPath.row].name = listName
                    self.tableView.reloadData()
                    
                    var list = self.displayList[indexPath.row]
                    
                    // Replace Database List
                    Database.createList(uploadList: list)
                    
                    // Update Current User
                    if let listIndex = CurrentUser.lists.index(where: { (currentList) -> Bool in
                        currentList.id == list.id
                    }) {
                        CurrentUser.lists[listIndex].name = listName
                    }
                })
            }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
            
            
        }
        
        edit.backgroundColor = UIColor.lightGray
        return [delete, edit]
        
    }
    
    

    
    
    
    
}
