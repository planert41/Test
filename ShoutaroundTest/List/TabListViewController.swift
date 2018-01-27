//
//  TabListViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/9/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import UIKit
import Firebase

class TabListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    
    
    // List Variables
    
    //INPUT
    var displayUser: User? = nil {
        didSet{
            userListIds = displayUser?.listIds
        }
    }
    
    var userListIds: [String]? = []
    
    var displayedLists: [List]? = [] {
        didSet{
            guard let uid = Auth.auth().currentUser?.uid else {return}
            if displayUser?.uid != uid {
                // Filter bookmark list if not current user
                if let bookmarkIndex = displayedLists?.index(where: { (list) -> Bool in
                    return list.name == bookmarkListName
                }) {
                    displayedLists?.remove(at: bookmarkIndex)
                }
            }
            self.listCollectionView.reloadData()
        }
    }
    
    var currentDisplayListIndex: Int? = nil {
        didSet{
            guard let currentDisplayListIndex = currentDisplayListIndex else {return}
            self.listViewController?.displayListId = displayedLists![currentDisplayListIndex].id
            self.listViewController?.displayList = displayedLists?[currentDisplayListIndex]
            print("Loading List \(displayedLists![currentDisplayListIndex].id) : \(displayedLists?[currentDisplayListIndex].name)")
            NotificationCenter.default.post(name: ListViewController.refreshListViewNotificationName, object: nil)
        }
    }
    
    let listCellId = "listCellId"
    
    let listCollectionViewHeight: CGFloat = 35
    lazy var listCollectionView : UICollectionView = {
        let layout = ListNameFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .white
        return cv
    }()
    
    var listViewController: ListViewController?
    
    lazy var expandList: UIButton = {
        let label = UIButton()
        label.addTarget(self, action: #selector(handleExpandList), for: .touchUpInside)
        label.setImage(#imageLiteral(resourceName: "expand"), for: .normal)
        label.layer.borderWidth = 0
//        label.backgroundColor = UIColor.legitColor()
        return label
    }()
    
    func handleExpandList() {
        let listController  = ListController()
        listController.displayedPost = nil
        listController.displayedList = self.displayedLists
        self.navigationController?.pushViewController(listController, animated: true)
    }
    
    let listHeaderView = UIView()
    let topDivider = UIView()
    let bottomDivider = UIView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        navigationItem.title = "Lists"
        
        listHeaderView.backgroundColor = UIColor(white: 0, alpha: 0.05)
        view.addSubview(listHeaderView)
        listHeaderView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: listCollectionViewHeight)
        
        topDivider.backgroundColor = UIColor.lightGray
        view.addSubview(topDivider)
        topDivider.anchor(top: listHeaderView.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
        bottomDivider.backgroundColor = UIColor.lightGray
        view.addSubview(bottomDivider)
        bottomDivider.anchor(top: nil, left: view.leftAnchor, bottom: listHeaderView.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
        listCollectionView.delegate = self
        listCollectionView.dataSource = self
        listCollectionView.register(listNameCell.self, forCellWithReuseIdentifier: listCellId)
        listCollectionView.layer.borderColor = UIColor.lightGray.cgColor
        listCollectionView.layer.borderWidth  = 0
        listCollectionView.showsHorizontalScrollIndicator = false
        listCollectionView.backgroundColor = UIColor.clear

        view.addSubview(expandList)
        expandList.anchor(top: listHeaderView.topAnchor, left: nil, bottom: nil, right: listHeaderView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 3, width: listCollectionViewHeight/2, height: listCollectionViewHeight)
        
        
        view.addSubview(listCollectionView)
        listCollectionView.anchor(top: listHeaderView.topAnchor, left: listHeaderView.leftAnchor, bottom: listHeaderView.bottomAnchor, right: expandList.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        

        
        listViewController = ListViewController()
        addChildViewController(listViewController!)
        view.addSubview((listViewController?.view)!)
        listViewController?.view.anchor(top: bottomDivider.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        checkUsers {
            self.fetchList()
        }
        
        // Do any additional setup after loading the view.
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        checkUsers {
//            print("Check User Finished, Userid: \(displayUser?.uid), Post No: \(displayedLists?.count)")
//            // Just checks for user at loading. If no users then fetches for Current User.
//            // Only Fetches List once user has been loaded or is refreshed
//            // self.fetchList()
//        }
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Refreshes List when view appears
        checkUsers {
            self.fetchList()
        }
    }
    
    func checkUsers(completion: @escaping() ->()){
        
        if displayUser == nil {
            // No Display User, so provide current user
            if CurrentUser.user == nil {
                print("Tab List View: No Display User, No Current User, Fetching Current User from Firebase")
                // If No Current User, pull current user
                Database.fetchCurrentUser {
                    print("Tab List View: No Display User, Fetched Current User from Firebase")
                    self.displayUser = CurrentUser.user
                    completion()
                }
            } else {
                print("Tab List View: No Display User, Fetching Current User from Cache with \(CurrentUser.user?.listIds.count) Lists")
                self.displayUser = CurrentUser.user
                completion()
            }
        } else {
            print("Tab List View: Has Display User")
            
            if displayUser?.uid == Auth.auth().currentUser?.uid{
                print("Refresh Current User List")
                self.userListIds = CurrentUser.listIds
            }
            
            completion()
        }
    }
    
    
    func fetchList(){
        
        guard let userListIds = userListIds else {
            print("Fetch User Lists: ERROR, No List Ids, Refetching User")
            
            Database.fetchUserWithUID(uid: (displayUser?.uid)!, completion: { (user) in
                print("Refetched User \(self.displayUser?.uid)! with \(user.listIds.count) Lists")
                self.userListIds = user.listIds
                self.fetchList()
            })
        
            return
        }
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        
        
        Database.fetchListForMultListIds(listUid: userListIds) { (fetchedLists) in
            if fetchedLists.count == 0 {
                print("Fetch List Error, No Lists, Displaying Default Empty Lists")
                self.displayedLists = [emptyLegitList, emptyBookmarkList]
                self.currentDisplayListIndex = 0
            } else {
                self.displayedLists = fetchedLists
                self.currentDisplayListIndex = 0
            }
            
            print("Fetched Lists: Post Numbers: \(self.displayedLists?.count)")
            self.listCollectionView.reloadData()
            NotificationCenter.default.post(name: ListViewController.refreshListViewNotificationName, object: nil)

        }
    }


    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (displayedLists?.count)!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: listCellId, for: indexPath) as! listNameCell
        cell.listName = self.displayedLists![indexPath.row].name
        
        if indexPath.row == currentDisplayListIndex {
            cell.backgroundColor = UIColor.rgb(red: 153, green: 204, blue: 255)
        } else {
            cell.backgroundColor = UIColor.clear
        }
  
        cell.heightAnchor.constraint(equalToConstant: listCollectionViewHeight).isActive = true
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.currentDisplayListIndex = indexPath.row
        let cell = collectionView.cellForItem(at: indexPath) as! listNameCell
        collectionView.scrollToItem(at: indexPath, at: .right, animated: true)
        collectionView.reloadData()
    }
    
    
}
