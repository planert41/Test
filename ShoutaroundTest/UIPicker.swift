//
//  UIPicker.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 10/29/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation



//                Old Code to allow refresh with filters on
//                if self.groupUsersFilter.count > 0 && self.isGroupUserFiltering {
//                    print(self.groupUsersFilter)
//                    print(key,value)
//                    if self.groupUsersFilter.contains(key){
//                        Database.fetchUserWithUID(uid: key, completion: { (user) in
//                            self.fetchPostsWithUser(user: user)
//                        })
//                    }
//                }
//                else {
//
//                    Database.fetchUserWithUID(uid: key, completion: { (user) in
//                    self.fetchPostsWithUser(user: user)
//                    })
//                }


//lazy var longPressGesture: UILongPressGestureRecognizer = {
//    
//    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(activateFilterRange))
//    longPressGesture.minimumPressDuration = 0.5 // 1 second press
//    longPressGesture.delegate = self
//    return longPressGesture
//}()


//lazy var dummyTextView: UITextView = {
//    let tv = UITextView()
//    return tv
//}()
//
//var pickerView: UIPickerView = {
//    let pv = UIPickerView()
//    pv.backgroundColor = .white
//    pv.showsSelectionIndicator = true
//    
//    return pv
//}()
//
//func setupGeoPicker() {
//    
//    
//    var toolBar = UIToolbar()
//    toolBar.barStyle = UIBarStyle.default
//    toolBar.isTranslucent = true
//    
//    toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
//    toolBar.sizeToFit()
//    
//    
//    let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.bordered, target: self, action: Selector("donePicker"))
//    let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
//    spaceButton.title = "Filter Range"
//    let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.bordered, target: self, action: Selector("cancelPicker"))
//    
//    toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
//    toolBar.isUserInteractionEnabled = true
//    
//    pickerView.delegate = self
//    pickerView.dataSource = self
//    self.dummyTextView.inputView = pickerView
//    self.dummyTextView.inputAccessoryView = toolBar
//}
//
//
//func donePicker(){
//    dummyTextView.resignFirstResponder()
//    filterPostByCaption(self.resultSearchController?.searchBar.text)
//    filterPostByLocation()
//    
//}
//
//func cancelPicker(){
//    dummyTextView.resignFirstResponder()
//}
//
//func activateFilterRange() {
//    
//    if self.filterRange != nil {
//        let rangeIndex = self.geoFilterRange.index(of: String(format:"%.1f", self.filterRange!))
//        pickerView.selectRow(rangeIndex!, inComponent: 0, animated: false)
//    }
//    dummyTextView.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.1)
//}
//
//// UIPicker DataSource
//func numberOfComponents(in pickerView: UIPickerView) -> Int {
//    
//    return 1
//    
//}
//func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//    return geoFilterRange.count
//}
//
//// UIPicker Delegate
//
//func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//    
//    if self.filterRange == Double(geoFilterRange[row]) {
//        
//        let rangeIndex = self.geoFilterRange.index(of: String(format:"%.1f", self.filterRange!))
//        pickerView.selectRow(rangeIndex!, inComponent: 0, animated: false)
//    }
//    
//    return geoFilterRange[row]
//}
//
//func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//    // If Select some number
//    if row > 0 {
//        filterRange = Double(geoFilterRange[row])
//    } else {
//        filterRange = nil
//    }
//    
//}


