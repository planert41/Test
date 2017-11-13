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



class MessageController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    
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
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        view.backgroundColor  = .white
        self.automaticallyAdjustsScrollViewInsets  = false
        
        collectionView.backgroundColor = .white
        collectionView.register(BookmarkPhotoCell.self, forCellWithReuseIdentifier: bookmarkCellId)
        
        view.addSubview(collectionView)
        collectionView.anchor(top: topLayoutGuide.bottomAnchor , left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: postDisplayHeight)

        view.addSubview(fromRow)
        fromRow.addSubview(fromLabel)
        fromRow.addSubview(fromInput)
        
        view.addSubview(toRow)
        toRow.addSubview(toLabel)
        toRow.addSubview(toInput)
        
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
        
        
        setupNavigationButtons()
    
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Try to find next responder
        
        if textField == fromInput {
            toInput.becomeFirstResponder()
        } else if textField == toInput {
            messageInput.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }

        // Do not add a line break
        return false
    }
    
    
    

    fileprivate func setupNavigationButtons() {
        
        navigationItem.title = "Message"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(handleSend))
            
        }
    
    
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
    
    
    func handleSend() {
     
        guard let toText = toInput.text else {return}
        
        if toText.isUsername{
            handleSendMessage()
        }
        else if toText.isValidEmail {
            handleSendEmail()
        } else{
            alert(title: "Sending Error", message: "Not a valid receipient")
        }
    }
    
    func handleSendMessage() {
        
        guard let toText = toInput.text else {return}
        Database.fetchUserWithUsername(username: toText) { (user) in
        
            
            guard let senderUID = Auth.auth().currentUser?.uid else {return}
            guard let postId = self.post?.id else {return}
            guard let message = self.messageInput.text else {return}
            let uploadTime = Date().timeIntervalSince1970
            let receiverUID = user.uid
            
            let databaseRef = Database.database().reference().child("messages").child(receiverUID)
            let userMessageRef = databaseRef.childByAutoId()
            
            let values = ["postUID": postId, "senderUID": senderUID, "message": message, "creationDate": uploadTime] as [String:Any]
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
    
    
    
    func handleSendEmail(){
            
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
            
            if isValidEmail(testStr: toInput.text!) {
                toLabel = "<" + toInput.text! + ">"
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
                print("success sending email")
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
