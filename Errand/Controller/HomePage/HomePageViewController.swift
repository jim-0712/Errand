//
//  ViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/15.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import GoogleSignIn
import FirebaseAuth
import FBSDKLoginKit
import IQKeyboardManager

class ViewController: UIViewController {
  
  var isEmail = false
  
  var photo = ""
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUpBtn()
    visitorRegisterBtn.isEnabled = false
    IQKeyboardManager.shared().isEnabled = true
    
    NotificationCenter.default.addObserver(self, selector: #selector(goToUserInfo), name: Notification.Name("userInfo"), object: nil)
  }
  
  let backgroundManager = BackgroundManager.shared
  
  @IBOutlet weak var logoLabel: UILabel!
  
  @IBOutlet weak var fbLoginBtn: UIButton!
  
  @IBOutlet weak var visitorRegisterBtn: UIButton!
  
  @IBOutlet weak var googleLoginBtn: UIButton!
  
  @IBOutlet weak var visitorBtn: UIButton!
  
  @IBOutlet weak var appleLogo: UIImageView!
  
  @IBOutlet weak var appleLoginBtn: UIButton!
  
  @IBOutlet weak var accountText: UITextField!
  
  @IBOutlet weak var passwordText: UITextField!
  
  @IBAction func appleLoginAct(_ sender: Any) {
    
  }
  
  @IBAction func visitorAct(_ sender: Any) {
    UserManager.shared.isTourist = true
    guard let mapVc  = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab") as? UITabBarController else { return }
    self.present(mapVc, animated: true, completion: nil)
  }
  
  @IBAction func googleLoginAct(_ sender: Any) {
    GIDSignIn.sharedInstance()?.signIn()
  }
  
  @IBAction func fbLoginAct(_ sender: Any) {
    
    UserManager.shared.fbLogin(controller: self) { result in
      
      switch result {
        
      case .success(let accessToken):
        
        UserManager.shared.loginFireBaseWithFB(accesstoken: accessToken, controller: self) { result in
          
          switch result {
            
          case .success:
            
            LKProgressHUD.show(controller: self)
            
            UserManager.shared.loadFBProfile(controller: self) { [weak self] result in
              
              guard let strongSelf = self else { return }
              
              switch result {
                
              case .success:
                
                UserManager.shared.isTourist = false
                
                guard let photoBack = Auth.auth().currentUser?.photoURL?.absoluteString,
                  let email = Auth.auth().currentUser?.email else { return }
      
                strongSelf.photo = photoBack
                
                UserManager.shared.createDataBase(classification: "Users", gender: 1, nickName: "發抖", email: email, photo: strongSelf.photo) { result in
                  
                  switch result {
                    
                  case .success(let success):
                    
                    LKProgressHUD.dismiss()
                    UserManager.shared.isTourist = false
                    UserManager.shared.updatefcmToken()
                    
                    LKProgressHUD.showSuccess(text: success, controller: strongSelf)
                    
                    guard let mapVc  = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab") as? UITabBarController else { return }
                    
                    strongSelf.present(mapVc, animated: true, completion: nil)
                    
                  case .failure(let error):
                    
                    LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
                    
                  }
                }
                
              case .failure(let error):
                
                LKProgressHUD.dismiss()
                LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
              }
            }
            LKProgressHUD.showSuccess(text: "Success", controller: self)
            
          case .failure(let error):
            
            LKProgressHUD.showFailure(text: error.localizedDescription, controller: self)
          }
        }
      case .failure(let error):
        
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: self)
      }
    }
  }
  
  @IBAction func visitorRegisterAct(_ sender: Any) {
    
    if isEmail {
      
      guard let account = accountText.text,
        
        accountText.text != "" else {
          LKProgressHUD.showFailure(text: RegistMessage.emptyAccount.rawValue, controller: self)
          
          return }
      
      guard let password = passwordText.text,
        
        passwordText.text != "" else {
          LKProgressHUD.showFailure(text: RegistMessage.emptyPassword.rawValue, controller: self)
          
          return }
      
      LKProgressHUD.show(controller: self)
      
      UserManager.shared.registAccount(account: account, password: password) { [weak self] result in
        
        guard let strongSelf = self else { return }
        
        switch result {
          
        case .success:
          
          guard let photoBack = Auth.auth().currentUser?.photoURL?.absoluteString else { return }
          
          strongSelf.photo = photoBack
          
          UserManager.shared.createDataBase(classification: "Users", gender: 1, nickName: "", email: account, photo: strongSelf.photo) { result in
            
            switch result {
              
            case .success(let success):
              
              UserManager.shared.isTourist = false
              
              LKProgressHUD.showSuccess(text: success, controller: strongSelf)
              
              guard let mapVc  = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab") as? UITabBarController else { return }
              
              strongSelf.present(mapVc, animated: true, completion: nil)
              
            case .failure(let error):
              
              LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
              
            }
          }
          
        case .failure:
          
          LKProgressHUD.showFailure(text: "Error Email", controller: strongSelf)
        }
        
      }
    }}
  
  func checkMail(email: String) -> Bool {
    
    let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    
    do {
      let regEx = try NSRegularExpression(pattern: emailPattern, options: .caseInsensitive)
      
      let matches = regEx.matches(in: email, options: [], range: NSRange(location: 0, length: email.count))
      
      if matches.count > 0 {
        return true
      } else {
        return false
      }
    } catch {
      fatalError("Wrong email pattern")
    }
  }
  
  func setUpBtn() {
    
    fbLoginBtn.layer.cornerRadius = 20
    visitorRegisterBtn.layer.cornerRadius = 20
    googleLoginBtn.layer.cornerRadius = 20
    appleLoginBtn.layer.cornerRadius = 20
    visitorBtn.layer.cornerRadius = 20
    appleLoginBtn.layer.borderWidth = 1.0
    appleLoginBtn.layer.borderColor = UIColor.black.cgColor
    GIDSignIn.sharedInstance()?.presentingViewController = self
    accountText.delegate = self
    passwordText.delegate = self
    logoLabel.transform = CGAffineTransform(a: 1.0, b: -0.15, c: 0, d: 0.7, tx: 0, ty: 10)
    let backView = backgroundManager.setUpView(view: self.view)
    self.view.layer.insertSublayer(backView, at: 0)
  }
  
  @objc func goToUserInfo () {
    
    UserManager.shared.isTourist = false
    
    guard let photoBack = Auth.auth().currentUser?.photoURL?.absoluteString,
      let email = Auth.auth().currentUser?.email else { return }
    
    self.photo = photoBack
    
    UserManager.shared.createDataBase(classification: "Users", gender: 1, nickName: "", email: email, photo: self.photo) { [weak self] result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success(let success):
        
        UserManager.shared.isTourist = false
        UserManager.shared.updatefcmToken()
        LKProgressHUD.showSuccess(text: success, controller: strongSelf)
  
        guard let mapVc  = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab") as? TabBarViewController else { return }
        strongSelf.present(mapVc, animated: true, completion: nil)
        
      case .failure(let error):
        
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
        
      }
    }
  }
}

extension ViewController: UITextFieldDelegate {
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    
    guard let account = accountText.text,
      accountText.text != "" else { return }
    
    guard let password = passwordText.text,
      passwordText.text != "" else { return }
    
    isEmail = checkMail(email: account)
    
    if isEmail && password.count > 5 {
      
      visitorRegisterBtn.isEnabled = true
    } else {
      
      visitorRegisterBtn.isEnabled = false
    }
  }
}
