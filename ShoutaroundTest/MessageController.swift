//
//  MessageController.swift
//  ShoutaroundTest
//
//  Created by Wei Zou Ang on 9/24/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics
import Firebase
import mailgun
import SearchTextField



class MessageController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UITextViewDelegate , UITableViewDelegate, UITableViewDataSource{
    
    let bookmarkCellId = "bookmarkCellId2"
    let postDisplayHeight = 150 as CGFloat
    
    var post: Post?
    
    var activeField: UITextField?
    
    lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.collectionViewLayout.invalidateLayout()
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
//        cv.layer.borderWidth = 0.5
//        cv.layer.borderColor = UIColor.black.cgColor
        return cv
    }()
    
    lazy var fromRow: UIView = {
        let uv = UIView()
        uv.layer.borderWidth = 1
        uv.layer.borderColor = UIColor.init(red:222/255.0, green:225/255.0, blue:227/255.0, alpha: 1.0).cgColor
        return uv
    }()
    
    lazy var fromLabel: UILabel = {
        let ul = UILabel()
        ul.text = "From: "
        ul.font = UIFont.boldSystemFont(ofSize: 16.0)
        return ul
    }()
    
    lazy var fromInput: PaddedTextField = {
        let tf = PaddedTextField()
        tf.font = UIFont.systemFont(ofSize: 14.0)
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.layer.cornerRadius = 10
        tf.layer.masksToBounds = true
        tf.delegate = self
        return tf
    }()
    
    lazy var toRow: UIView = {
        let uv = UIView()
        
        uv.layer.borderWidth = 1
        uv.layer.borderColor = UIColor.init(red:222/255.0, green:225/255.0, blue:227/255.0, alpha: 1.0).cgColor
        return uv
    }()
    
    lazy var toLabel: UILabel = {
        let ul = UILabel()
        ul.text = "To: "
        ul.font = UIFont.boldSystemFont(ofSize: 16.0)
        return ul
    }()
    
    lazy var toInput: PaddedTextField = {
        let tf = PaddedTextField()
        tf.font = UIFont.systemFont(ofSize: 14.0)
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.layer.cornerRadius = 10
        tf.layer.masksToBounds = true
        tf.delegate = self
//        
//        let indentView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
//        tf.leftView = indentView
//        tf.leftViewMode = .always
//
//        tf.inlineMode = true
//        tf.startFilteringAfter = "@"
//        tf.startSuggestingInmediately = true
//        tf.filterStrings(["gmail.com", "yahoo.com", "yahoo.com.ar"])
        
        return tf
    }()
    
    lazy var messageLabel: UILabel = {
        let ul = UILabel()
        ul.text = "Message: "
        ul.font = UIFont.boldSystemFont(ofSize: 16.0)
        return ul
    }()
    
    lazy var messageInput: UITextView = {
        let tf = UITextView()
        tf.font = UIFont.systemFont(ofSize: 14.0)
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.layer.cornerRadius = 10
        return tf
    }()
    
    // EmojiAutoComplete
    var userAutoComplete: UITableView!
    let UserAutoCompleteCellId = "UserAutoCompleteCellId"
    var followingUsers:[User] = []
    var filteredUsers:[User] = []
    var isAutocomplete: Bool = false
    
    var sentUsers: [String: String] = [:]
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        view.backgroundColor  = .white
        self.automaticallyAdjustsScrollViewInsets  = false
        
        collectionView.backgroundColor = .white
        collectionView.register(BookmarkPhotoCell.self, forCellWithReuseIdentifier: bookmarkCellId)
        
        view.addSubview(collectionView)
        collectionView.anchor(top: topLayoutGuide.bottomAnchor , left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: postDisplayHeight)

        view.addSubview(fromRow)
        view.addSubview(fromLabel)
        view.addSubview(fromInput)
        
        view.addSubview(toRow)
        view.addSubview(toLabel)
        view.addSubview(toInput)
        
        view.addSubview(messageLabel)
        view.addSubview(messageInput)
        
        fromRow.anchor(top: collectionView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 2, paddingLeft: 2, paddingBottom: 0, paddingRight: 2, width: 0, height: 50)
        
        fromLabel.anchor(top: fromRow.topAnchor, left: fromRow.leftAnchor, bottom: fromRow.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 60, height: 0)
        
        fromInput.anchor(top: fromRow.topAnchor, left: fromLabel.rightAnchor, bottom: fromRow.bottomAnchor, right: fromRow.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
    
        
        toRow.anchor(top: fromRow.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 2, paddingLeft: 2, paddingBottom: 0, paddingRight: 2, width: 0, height: 50)
        
        toLabel.anchor(top: toRow.topAnchor, left: toRow.leftAnchor, bottom: toRow.bottomAnchor, right: nil, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 0, width: 60, height: 0)
        
        toInput.anchor(top: toRow.topAnchor, left: toLabel.rightAnchor, bottom: toRow.bottomAnchor, right: toRow.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 0)
        
        messageLabel.anchor(top: toRow.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 30)
        
        messageInput.anchor(top: messageLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: 0, height: 150)
        
        print(CurrentUser.username)
        fromInput.text = CurrentUser.username
        
        fromInput.tag = 0
        toInput.tag = 1
        messageInput.tag = 2
        
        fromInput.delegate = self
        toInput.delegate = self
        messageInput.delegate = self
        
        toInput.placeholder = "@username, user@gmail.com"
        toInput.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        
        // Keyboard Setups to Dismiss Keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        fromRow.isUserInteractionEnabled = true
        fromRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        toRow.isUserInteractionEnabled = true
        toRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        messageLabel.isUserInteractionEnabled = true
        messageLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        
        
        setupNavigationButtons()
        
        // User Auto Complete
        
        setupUserAutoComplete()
        view.addSubview(userAutoComplete)
        userAutoComplete.anchor(top: toRow.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        userAutoComplete.isHidden = true
        
        fetchFollowingUsers()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.fromInput.becomeFirstResponder()
    }
    
    
    fileprivate func setupNavigationButtons() {
        navigationItem.title = "Message"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(handleSend))
    }

    // Keyboard Adjustments
    
    var adjusted: Bool = false
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func keyboardWillShow(_ notification: NSNotification) {
        if !self.adjusted {
            self.view.frame.origin.y -= postDisplayHeight
            self.adjusted = true
        }
    }
    
    func keyboardWillHide(_ notification: NSNotification) {
        if self.adjusted {
            self.view.frame.origin.y += postDisplayHeight
            self.adjusted = false
        }
        self.userAutoComplete.isHidden = true
    }
    
    func textFieldDidChange(_ textField: UITextField){
        if textField == toInput {
            guard let tempCaptionWords = textField.text?.components(separatedBy: " ") else {return}
            var lastWord = tempCaptionWords[tempCaptionWords.endIndex - 1]
            self.filterUsersForText(inputString: lastWord)
        }
    }

    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        if textField == toInput {
//            guard let tempCaptionWords = textField.text?.components(separatedBy: " ") else {return true}
//            var lastWord = tempCaptionWords[tempCaptionWords.endIndex - 1]
//            self.filterUsersForText(inputString: lastWord)
//        }
        return true
    }
    
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        textField.keyboardType = UIKeyboardType.twitter
    
//        self.adjustment = textField.convert(textField.frame.origin, to: self.view).y - (self.navigationController?.navigationBar.frame.height)!
//        print("Adjustment is \(self.adjustment)")
        return true
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Try to find next responder
        
        if textField == fromInput {
            toInput.becomeFirstResponder()
        } else if textField == toInput {
            // This calls the autocomplete function for searchtextfield. Just a workaround. Doesn't work wiht multiple @s
//            toInput.textFieldDidEndEditingOnExit()
            self.checkToText(inputString: self.toInput.text, completion: { (fetchedSentUsers) in
                self.sentUsers = fetchedSentUsers
            })
            messageInput.becomeFirstResponder()
            self.userAutoComplete.isHidden = true
            
        } else {
            textField.resignFirstResponder()
        }

        // Do not add a line break
        return false
    }
    
// User Autocomplete Functions
    
    func setupUserAutoComplete(){
        
        // User Autocomplete View
        userAutoComplete = UITableView()
        userAutoComplete.register(UserCell.self, forCellReuseIdentifier: UserAutoCompleteCellId)
        userAutoComplete.delegate = self
        userAutoComplete.dataSource = self
        userAutoComplete.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        userAutoComplete.backgroundColor = UIColor.white
        userAutoComplete.estimatedRowHeight = 66
    }
    
    func fetchFollowingUsers() {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        if CurrentUser.followingUids.count == 0 {
            Database.fetchFollowingUserUids(uid: uid) { (fetchedFollowingUsers) in
                CurrentUser.followingUids = fetchedFollowingUsers
                self.FirebaseFetchUsers()
            }
        } else {
            self.FirebaseFetchUsers()
        }
    }
    
    func FirebaseFetchUsers(){
        for uid in CurrentUser.followingUids {
            Database.fetchUserWithUID(uid: uid, completion: { (user) in
                    self.followingUsers.append(user)
            })
        }
    }
    
    func filterUsersForText(inputString: String){
        filteredUsers = followingUsers.filter({( user : User) -> Bool in
            return user.username.lowercased().contains(inputString.lowercased())
        })
        
        // Show only if filtered users not 0
        if filteredUsers.count > 0 {
            self.userAutoComplete.isHidden = false
        } else {
            self.userAutoComplete.isHidden = true
        }
        
        // Sort results based on prefix
        filteredUsers.sort { (p1, p2) -> Bool in
            ((p1.username.hasPrefix(inputString)) ? 0 : 1) < ((p2.username.hasPrefix(inputString)) ? 0 : 1)
        }
        self.userAutoComplete.reloadData()
    }
    
    
    // Tableview delegate functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserAutoCompleteCellId, for: indexPath) as! UserCell
        cell.user = filteredUsers[indexPath.row]
        cell.followButton.isHidden = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var userSelected = filteredUsers[indexPath.row]
        var selectedUsername = userSelected.username
        var addedString : String?
        addedString = selectedUsername
        
        guard var tempCaptionWords = self.toInput.text?.lowercased().components(separatedBy: " ") else {
            self.toInput.text = (addedString)! + ", "
            return
        }
        
        var lastWord = tempCaptionWords[tempCaptionWords.endIndex - 1]
        self.toInput.text = tempCaptionWords.dropLast().joined(separator: " ") + (addedString)! + ", "
        self.userAutoComplete.isHidden = true

    }
    
    
// CollectionView Delegate Functions
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            
            return CGSize(width: view.frame.width, height: postDisplayHeight)
        
        }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: bookmarkCellId, for: indexPath) as! BookmarkPhotoCell
            cell.post = post
            return cell
     
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func handleSendTest(sentUsers: [String: String]){
        
        guard let toText = toInput.text else {return}
        guard let creatorUID = Auth.auth().currentUser?.uid else {return}
        guard let creatorUsername = CurrentUser.username else {return}
        guard let postId = self.post?.id else {return}
        guard let message = self.messageInput.text else {return}
        let postCreationDate = self.post?.creationDate.timeIntervalSince1970
        let uploadTime = Date().timeIntervalSince1970
        let descTime = Date()

        var receiveUserUid: [String: String] = [:]
        var receiveUserEmail: [String: String] = [:]
        
        //Disable Message Button to avoid dup presses
        navigationItem.rightBarButtonItem?.isEnabled = false
        

            // Split Sent Users to email/uids
            for (key,value) in sentUsers {
                if key.isValidEmail {
                    receiveUserEmail[key] = value
                } else {
                    receiveUserUid[key] = value
                }
            }
            
            print("Sent Targets Emails: \(receiveUserEmail), Uids: \(receiveUserUid)")
        
        // Save and create Message Thread
        
            let messageThreadRef = Database.database().reference().child("messageThreads").childByAutoId()
            let values = ["postUID": postId, "creatorUID": creatorUID, "creatorUsername": creatorUsername, "sentMessage": message, "creationDate": uploadTime, "sentTo": toText] as [String:Any]
        
            messageThreadRef.updateChildValues(values, withCompletionBlock: { (err, ref) in
                
                if let err = err {
                    print("Failed to Save Message to DB", err)
                }
                
                // Success Creating Message Thread
                var threadKey = messageThreadRef.key
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                
                print("Successfully Created Message Thread \(threadKey) in Database")

                // Update Post_Messages
                let messageRef = Database.database().reference().child("post_messages").child(postId)
                messageRef.runTransactionBlock({ (currentData) -> TransactionResult in
                    
                    var post = currentData.value as? [String : AnyObject] ?? [:]
                    var count = post["messageCount"] as? Int ?? 0
                    var threads = post["threads"] as? [String : Any] ?? [:]
                    var postDate = post["creationDate"] as? Double ?? 0
                    
                    count = max(0, count + 1)
                    threads[threadKey] = creatorUID
                    
                    // Update Message Thread Counts
                    post["messageCount"] = count as AnyObject?
                    post["threads"] = threads as AnyObject?
                    
                    // Handle/Update Post Creation Date
                    if let postCreationDate = postCreationDate {
                        if postDate != postCreationDate {
                            postDate = postCreationDate
                        }
                    }
                    
                    // Enables firebase sort by count and recent upload time
                    let  sortTime = uploadTime/1000000000000000
                    post["sort"] = (Double(count) + sortTime) as AnyObject
                    
                    currentData.value = post
                    print("Update Message Count for post : \(postId) to \(count)")
                    return TransactionResult.success(withValue: currentData)
                
                }) { (error, committed, snapshot) in
                    if let error = error {
                        print("Failed to Update Message Thread Count Error: ", postId, error.localizedDescription)
                    }
                }
            
                // Send Emails
                print("Trying to send emails for emails: \(receiveUserEmail)")
                for (key,value) in receiveUserEmail {
                    self.handleSendEmail(email: key)
                }
                
                // Send User Message
                print("Trying to send messages for user uids: \(receiveUserUid)")
                if receiveUserUid.count > 0 {
                    Database.updateMessageThread(threadKey: threadKey, creatorUid: creatorUID, creatorUsername: creatorUsername, receiveUid: receiveUserUid, message: message)
                }
                
                self.navigationController?.popViewController(animated: true)
            })
        
    }
    
    func checkToText(inputString: String?, completion: @escaping ([String:String]) -> ()){
        guard let inputString = inputString else {return}
        let toArray = inputString.components(separatedBy: ",")
        let checkGroup = DispatchGroup()
        var sentArray: [String: String] = [:]
        
        print("Checking To Field for Array: \(toArray)")
        for text in toArray {
            
            // Remove white spaces and lower case everything
            var tempText = text
            print("Searching for: \(tempText)")
            
            tempText = tempText.removingWhitespaces()
            tempText = tempText.lowercased()
            
            // Check is blank
            if tempText.isEmptyOrWhitespace(){
                print("Empty Space So Ignore")
                continue
            } else {
                checkGroup.enter()
            }
            
            // Check if email
            if tempText.isValidEmail {
                sentArray[tempText] = "email"
                print("Email Found for \(tempText)")
                checkGroup.leave()

            } else {
                // Check if is a user
                Database.fetchUserWithUsername(username: tempText, completion: { (fetchedUser, error) in
                   
                    var user: User?
                    var userId: String!
                    
                    if let error = error {
                        print("Error finding user for \(tempText): \(error)")
                        self.alert(title: "Error Message Receipient", message: "No user or email was found for \(tempText)")
                        return
                    }
                    
                    if let user = fetchedUser {
                        userId = user.uid
                        print("User Found for \(tempText): \(userId!)")
                        sentArray[userId!] = tempText
                        checkGroup.leave()
                    }
                    
                    else {
                        print("No user was found for \(tempText)")
                        self.alert(title: "Error Message Receipient", message: "No user or email was found for \(tempText)")
                        return
                    }
                })
            }
        }
        
        checkGroup.notify(queue: .main) {
            print("Final Sent Array: \(sentArray)")
            completion(sentArray)
        }
    }
    
    
    
    func handleSend() {
     
        self.checkToText(inputString: toInput.text) { (users) in
            self.handleSendTest(sentUsers: users)
        }
    }
    
    
    func handleSendMessage(userId: String) {
        
        guard let toText = toInput.text else {return}
        Database.fetchUserWithUsername(username: toText) { (user, error) in
        
            
            guard let senderUID = Auth.auth().currentUser?.uid else {return}
            guard let postId = self.post?.id else {return}
            guard let message = self.messageInput.text else {return}
            guard let user = user else {return}
            let uploadTime = Date().timeIntervalSince1970
            let receiverUID = user.uid
            
            let databaseRef = Database.database().reference().child("messages").child(receiverUID)
            let userMessageRef = databaseRef.childByAutoId()
            
            let values = ["postId": postId, "creatorUID": senderUID, "message": message, "creationDate": uploadTime] as [String:Any]
            userMessageRef.updateChildValues(values) { (err, ref) in
                if let err = err {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    print("Failed to save message to DB", err)
                    return
                }
                
                print("Successfully save message to DB")
                self.navigationController?.popViewController(animated: true)

            }
        }
    }
    
    
    
    func handleSendEmail(email: String!){
            
            view.endEditing(true)
            
            guard let post = self.post else {return}
    
            let mailgun = Mailgun.client(withDomain: "shoutaround.com", apiKey: "key-2562988360d4f7f8a1fcc6f3647b446a")
    
            var fromLabel: String?
            
            if fromInput.text == nil {
                fromLabel = "<user@shoutaround.com>"
            } else {
                
                var trimmedusername = CurrentUser.username!.replacingOccurrences(of: " ", with: "")
                    trimmedusername = trimmedusername.replacingOccurrences(of: "@", with: "")
                
                fromLabel = fromInput.text!.replacingOccurrences(of: "@", with: "") + "<" + trimmedusername + "@shoutaround.com>"
            }
            
            var toLabel: String?
            
            if isValidEmail(testStr: email) {
                toLabel = "<" + email + ">"
            } else {
                print("Not Email")
                return
            }
                
        
            let message = MGMessage(from:fromLabel,
                                    to:toLabel,
                                    subject:"Shoutaround Message",
                                    body:(""))!
    
            let postImage = CustomImageView()
            postImage.loadImage(urlString: post.imageUrl)
    
            //        message.add(postImage.image, withName: "image01", type: .JPEGFileType, inline: true)
            message.html = "<html><p><img src=" + post.imageUrl + " width = \"25%\" height = \"25%\"/></p><p>" + post.emoji + "</p><p>" + post.locationName + "</p><p>" + post.locationAdress + "</p><p>" + post.user.username + "</p><p>" + post.caption +  "</p><p>" + "Message From " + fromInput.text! + "</p><p>" + messageInput.text + "</p></html>"
  
            // someImage: UIImage
            // type can be either .JPEGFileType or .PNGFileType
            // message.add(postImage.image, withName: "image01", type:.PNGFileType)
    
    
            mailgun?.send(message, success: { (success) in
                print("success sending email to \(email)")
                self.navigationController?.popViewController(animated: true)
                
            }, failure: { (error) in
                print(error)
            })
    
    }
        
    
    func isValidEmail(testStr:String) -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    
}
