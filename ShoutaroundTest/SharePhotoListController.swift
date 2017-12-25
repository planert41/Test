//
//  SharePhotoListController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 12/23/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class SharePhotoListController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var uploadPostDictionary: [String: Any] = [:]
    var uploadPost: Post? = nil {
        didSet{
            print("Uploaded Post: ", uploadPost)
            collectionView.reloadData()
        }
    }
    
    var displayList: [List] = defaultList
    var selectedList: [List] {
        return displayList.filter { return $0.isSelected }
    }
    
    let postCellId = "PostCellId"
    let listCellId = "ListCellId"
    
    lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .white
        return cv
    }()
    
    let addListView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    lazy var addListTextField: PaddedTextField = {
        let tf = PaddedTextField()
        tf.font = UIFont.systemFont(ofSize: 14.0)
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.layer.cornerRadius = 10
        tf.layer.masksToBounds = true
        tf.placeholder = "Eg: Chicago, Ramen"
        tf.delegate = self
        return tf
    }()
    
    let addListButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "add").withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.layer.masksToBounds  = true
        button.clipsToBounds = true
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(addList), for: .touchUpInside)
        return button
    } ()
    
    func addList(){
        let listId = NSUUID().uuidString
        checkListName(listName: addListTextField.text) { (listName) in
            let newList = List.init(id: listId, name: listName)
            self.displayList.append(newList)
            self.tableView.reloadData()
            self.addListTextField.text?.removeAll()
        }
        self.addListTextField.resignFirstResponder()
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
    
    
    lazy var tableView : UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.estimatedRowHeight = 100
        tv.allowsMultipleSelection = true
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        // Setup Navigation
        navigationController?.title = "Add To List"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handleShare))
        
        
        // Setup CollectionView for Post
        collectionView.register(BookmarkPhotoCell.self, forCellWithReuseIdentifier: postCellId)
        view.addSubview(collectionView)
        collectionView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 120)
        
        view.addSubview(addListView)
        addListView.anchor(top: collectionView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        view.addSubview(addListButton)
        addListButton.anchor(top: nil, left: nil, bottom: nil, right: addListView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 15, width: 30, height: 30)
        addListButton.centerYAnchor.constraint(equalTo: addListView.centerYAnchor).isActive = true
        
        view.addSubview(addListTextField)
        addListTextField.anchor(top: nil, left: addListView.leftAnchor, bottom: nil, right: addListButton.leftAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 5, width: 0, height: 30)
        addListTextField.centerYAnchor.constraint(equalTo: addListView.centerYAnchor).isActive = true
        addListTextField.placeholder = "New List Name (eg: Chicago, Ramen)"
        

        tableView.register(UploadListCell.self, forCellReuseIdentifier: listCellId)
        view.addSubview(tableView)
        tableView.anchor(top: addListView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    func setupList(){
//        if displayList.count == 0 {
//            displayList = defaultList
//        }
//        tableView.reloadData()
    }
    
    func handleShare(){
        print(self.selectedList)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: postCellId, for: indexPath) as! BookmarkPhotoCell
        cell.bookmarkDate = uploadPost?.creationDate
        cell.post = uploadPost
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: view.frame.width, height: 120)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: listCellId, for: indexPath) as! UploadListCell
        
        cell.list = displayList[indexPath.row]
        
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
        displayList[indexPath.row].isSelected = true
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        displayList[indexPath.row].isSelected = false
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }


    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            // Check For Default List
            if (defaultList.contains(where: { (list) -> Bool in
                list.name == self.displayList[indexPath.row].name})){
                self.alert(title: "Delete List Error", message: "Cannot Delete Default List: \(self.displayList[indexPath.row].name)")
                return
            }
            
            self.displayList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            print(self.displayList)
        }
        
        let edit = UITableViewRowAction(style: .default, title: "Edit") { (action, indexPath) in
            // Check For Default List
            if (defaultList.contains(where: { (list) -> Bool in
                list.name == self.displayList[indexPath.row].name})){
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
                })
            }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
            
            
        }
        
        edit.backgroundColor = UIColor.lightGray
        
        return [delete, edit]
        
    }
    
    
    
    
}
