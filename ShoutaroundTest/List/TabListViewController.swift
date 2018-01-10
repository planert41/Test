//
//  TabListViewController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 1/9/18.
//  Copyright © 2018 Wei Zou Ang. All rights reserved.
//

import UIKit

class TabListViewController: UIViewController {

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let testView = UIView()
        testView.backgroundColor = UIColor.blue
        view.addSubview(testView)
        testView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 100)
        
        let listViewController = ListViewController()
        listViewController.displayListId = CurrentUser.listIds[0]
        addChildViewController(listViewController)
        view.addSubview(listViewController.view)
        listViewController.view.anchor(top: testView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
