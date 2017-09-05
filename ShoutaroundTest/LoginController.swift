//
//  LoginController.swift
//  InstagramFirebase
//
//  Created by Wei Zou Ang on 8/27/17.
//  Copyright © 2017 Wei Zou Ang. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit

class LoginController: UIViewController, FBSDKLoginButtonDelegate   {
    
    
    
    let logoContainerView: UIView = {
        
        let view = UIView()
        
        let logoImageView = UIImageView(image: #imageLiteral(resourceName: "Instagram_logo_white"))
        logoImageView.contentMode = .scaleAspectFill
        
        view.addSubview(logoImageView)
        logoImageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 200, height: 50)
        logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        
        view.backgroundColor = UIColor.rgb(red: 0, green: 120, blue: 175)
        return view
        
    }()
    
    let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        
        return tf
        
        
    }()
    
    
    let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        
        return tf
        
    }()
    
    let loginButton: UIButton = {
        
        
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        
        
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        
        button.addTarget(self, action: #selector(handleLogIn), for: .touchUpInside)
        
        button.isEnabled = false
        
        return button
    }()
    
    // Add FB Login Button
    
    let fbLoginButton: FBSDKLoginButton = {
     
        let button = FBSDKLoginButton()
        button.layer.cornerRadius = 5
        
        for constraint: NSLayoutConstraint in button.constraints {
            print(constraint)
            if(constraint.firstAttribute == .height) {
                button.removeConstraint(constraint)
            }
        }
        
        return button
        
        
    }()
    
    func handleLogIn(){
        
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
    Auth.auth().signIn(withEmail: email, password: password) { (user, err) in
        
        if let err = err {
            print("Failed to sign in with email:", err)
            return
        }
        
        print("Successfully logged back in with user:", user?.uid ?? "")
        
        self.successfulLogin()
        }
        
    }
    
    fileprivate func successfulLogin() {
        guard let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else { return }
        
        mainTabBarController.setupViewControllers()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func handleTextInputChange(){
        
        let isFormValid = emailTextField.text?.characters.count ?? 0 > 0 && passwordTextField.text?.characters.count ?? 0 > 0
        
        if isFormValid {
            
            loginButton.isEnabled = true
            loginButton.backgroundColor = UIColor.rgb(red: 17, green: 154, blue: 237)
        } else {
            loginButton.isEnabled = false
            loginButton.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
            
        }
    }
    
    
    
    let dontHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        
        
        let attributedTitle = NSMutableAttributedString(string: "Don't have an account? ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(string: "Sign Up", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.rgb(red: 17, green: 154, blue: 237)]))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        
     //   button.setTitle("Don't have an account? Sign Up.", for: .normal)
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        return button
    }()

    
    
    
    func handleShowSignUp() {
        let signUpController = SignUpController()
        navigationController?.pushViewController(signUpController, animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle  {
        
       return.lightContent
        
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
        view.backgroundColor = .white
        
        view.addSubview(logoContainerView)
        logoContainerView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 150)
        
        setupInputFields()
        
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        

    
    }
    

    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        if let _ = FBSDKAccessToken.current() {
            if let currentUser = FBSDKProfile.current() {
                print("current user got: \(currentUser)")
            } else {
                print("current user not got")
                FBSDKProfile.loadCurrentProfile(completion: {
                    profile, error in
                    if let updatedUser = profile {
                        print("finally got user: \(updatedUser)")
                    } else {
                        print("current user still not got")
                    }
                })
            }
        }
        

        
//        let image = CustomImageView()
//        let string = "https://graph.facebook.com/" + FBSDKAccessToken.current() + "/picture?type=square&width=40&height=40"
//        image.loadImage(urlString: string)

        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print("Failed to sign in with FB Credentials", error)
                return
            }

            
            guard let userUid = user?.uid else {return}
            let ref = Database.database().reference().child("users")
            
            ref.observe(DataEventType.value, with: { (snapshot) in
                if snapshot.hasChild(userUid) {

                    print("User Exist")
                  self.successfulLogin()
                
                } else {
                    
            // Create new user in database if current user doesn't exist
                    print("User doesn't Exist")
                    self.fbLoginCreateNewUser()
                    }
                

            
            }){ (err) in print("Error in Search", err) }

  
        }
        
    }
    
    fileprivate func fbLoginCreateNewUser(){
        
        let currentUser = FBSDKProfile.current()
        let fbProfileID = currentUser?.userID as! String
        let fbProfileImageURL = "http://graph.facebook.com/\(fbProfileID)/picture?type=large"
        let fbProfileFullName = currentUser?.name as! String
        let image = UIImage()
        
        guard let url = URL(string: fbProfileImageURL) else {return}
        
        URLSession.shared.dataTask(with: url) { (data, response, err) in
            if let err = err {
                print("Failed to fetch post image:", err)
                return
            }
            
            guard let imageData = data else {return}
            let fbProfileImage = UIImage(data: imageData)
            
            guard let image = fbProfileImage else {return}
            guard let uploadData = UIImageJPEGRepresentation(image, 0.3) else {return}
            
            let filename = NSUUID().uuidString
            Storage.storage().reference().child("profile_images").child(filename).putData(uploadData, metadata: nil, completion: { (metadata,err) in
                
                if let err = err {
                    print("Failed to upload Profile Image", err)
                    return
                }
                
                guard let profileImageUrl = metadata?.downloadURL()?.absoluteString else {return}
                print("Successfully uploaded profile image:", profileImageUrl )
                
                
                guard let uid = Auth.auth().currentUser?.uid else {return}
                let dictionaryValues = ["username": fbProfileFullName, "profileImageUrl": profileImageUrl]
                let values = [uid:dictionaryValues]
                
                Database.database().reference().child("users").updateChildValues(values, withCompletionBlock: { (err, ref) in
                    
                    if let err = err {
                        
                        print("Failed to save user info into db:", err)
                        return }
                    
                    print("Successfully saved user info to db")
                    
                    guard let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else { return }
                    
                    mainTabBarController.setupViewControllers()
                    self.dismiss(animated: true, completion: nil)
                    
                })
            })
        }.resume()
 
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        do {
            try Auth.auth().signOut()
            
            if Auth.auth().currentUser == nil {
                
            } else {
            
            let loginController = LoginController()
            let navController = UINavigationController( rootViewController: loginController)
            self.present(navController, animated: true, completion: nil)
            }
            
        } catch let signOutErr {
            print("Failed to sign out:", signOutErr)
        }
        
    }


    
    fileprivate func setupInputFields() {
        let stackView = UIStackView(arrangedSubviews: [emailTextField, passwordTextField, loginButton, fbLoginButton])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        
        view.addSubview(stackView)
        stackView.anchor(top: logoContainerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 40, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 190)
        
        fbLoginButton.delegate = self
    }
    
    
}
