//
//  SearchResultsController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/16/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit


protocol SearchControllerDelegate {
    
}

class PostSearchController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {

    var delegate: SearchControllerDelegate?

    
    var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .blue

        return tv
    }()
    
    lazy var filterBar: UIView = {
        let sb = UIView()
        sb.backgroundColor = UIColor.lightGray
        return sb
    }()
    
    
    lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search for Caption or Emoji 😍🐮🍔🇺🇸🔥"
        sb.barTintColor = .white
        sb.backgroundColor = .white
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        
        sb.delegate = self
        return sb
    }()
    
    lazy var geoFilterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(self.geoFilterRange[0], for: .normal)
        button.addTarget(self, action: #selector(filterRange), for: .touchUpInside)
        button.backgroundColor = .white
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.black.cgColor
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.blue
        
        
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
}
