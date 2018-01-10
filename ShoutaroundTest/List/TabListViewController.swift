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
    
    var displayUser: User? = nil {
        didSet{
            userListIds = displayUser?.listIds
        }
    }
    var userListIds: [String]? = []
    var displayedLists: [List]? = []
    
    let listCellId = "listCellId"
    
    lazy var listCollectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .white
        return cv
    }()
    
    var listViewController: ListViewController?
    
    

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listCollectionView.delegate = self
        listCollectionView.dataSource = self
        listCollectionView.register(UploadLocationCell.self, forCellWithReuseIdentifier: listCellId)

        view.addSubview(listCollectionView)
        listCollectionView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        listViewController = ListViewController()
        addChildViewController(listViewController!)
        view.addSubview((listViewController?.view)!)
        listViewController?.view.anchor(top: listCollectionView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        checkUsers {
            self.fetchList()
        }
        
        
        // Do any additional setup after loading the view.
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
                print("Tab List View: No Display User, Fetching Current User from Cache")
                self.displayUser = CurrentUser.user
                completion()
            }
        } else {
            print("Tab List View: Has Display User")
            completion()
        }
    }
    
    
    func fetchList(){
        
        guard let userListIds = userListIds else {
            print("Fetch User Lists: ERROR, No List Ids")
            return
        }
        
        Database.fetchListForMultListIds(listUid: userListIds) { (fetchedLists) in
            

            self.displayedLists = fetchedLists
            self.listCollectionView.reloadData()
            self.listViewController?.displayListId = self.userListIds?[0]
            self.listViewController?.reloadInputViews()
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: listCellId, for: indexPath) as! UploadLocationCell
        cell.uploadLocations.text = self.displayedLists![indexPath.row].name
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected \(displayedLists![indexPath.row].name)")
        self.listViewController?.displayListId = displayedLists![indexPath.row].id
        self.listViewController?.displayList = displayedLists?[indexPath.row]
        self.listViewController?.reloadInputViews()
        NotificationCenter.default.post(name: ListViewController.refreshListViewNotificationName, object: nil)
    }
    
    
}
