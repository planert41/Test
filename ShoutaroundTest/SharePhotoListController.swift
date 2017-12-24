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
    
    var uploadPost: Post? = nil {
        didSet{
            print(uploadPost)
            collectionView.reloadData()
        }
    }
    
    var displayList: [List] = listDefault
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
        guard let listName = addListTextField.text else {
            self.alert(title: "New List Requirement", message: "Please Insert List Name")
            return
        }
        if listName.isEmptyOrWhitespace() {
            self.alert(title: "New List Requirement", message: "Please Insert List Name")
            return
        }
        
        if displayList.contains(where: { (displayList) -> Bool in
            return displayList.name == listName
        }) {
            self.alert(title: "Duplicate List Name", message: "Please Insert Different List Name")
            return
        }
        
        let newList = List.init(id: listId, name: listName)
        displayList.append(newList)
        tableView.reloadData()
        
        addListTextField.text?.removeAll()
        addListTextField.resignFirstResponder()
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
//            displayList = listDefault
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

    
    
    
}
