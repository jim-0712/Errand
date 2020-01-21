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

class ViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUpBtn()
    
    NotificationCenter.default.addObserver(self, selector: #selector(goToUserInfo), name: Notification.Name("userInfo"), object: nil)
  }
  
  let backgroundManager = BackgroundManager.shared
  
  @IBOutlet weak var logoLabel: UILabel!
  
  @IBOutlet weak var fbLoginBtn: UIButton!
  
  @IBOutlet weak var visitorRegisterBtn: UIButton!
  
  @IBOutlet weak var googleLoginBtn: UIButton!
  
  @IBOutlet weak var appleLogo: UIImageView!
  
  @IBOutlet weak var appleLoginBtn: UIButton!
  
  @IBOutlet weak var accountText: UITextField!
  
  @IBOutlet weak var passwordText: UITextField!
  
  @IBAction func appleLoginAct(_ sender: Any) {
    
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
            
            UserManager.shared.loadFBProfile(controller: self) { result in
              
              switch result {
                
              case .success:
                
                guard let userInfoVc = self.storyboard?.instantiateViewController(identifier: "userinfo") as? UserInfoViewController else { return }
                
                self.present(userInfoVc, animated: true, completion: nil)
                
              case .failure(let error):
                
                LKProgressHUD.showFailure(text: error.localizedDescription, controller: self)
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
    
    guard let account = accountText.text,
      
      accountText.text != "" else {
        
        LKProgressHUD.showFailure(text: RegistMessage.emptyAccount.rawValue, controller: self)
        
        return }
    
    guard let password = passwordText.text,
      
      passwordText.text != "" else {
        
        LKProgressHUD.showFailure(text: RegistMessage.emptyPassword.rawValue, controller: self)
        
        return }
      
      LKProgressHUD.show(controller: self)
      
      UserManager.shared.registAccount(account: account, password: password) { result in
        
        switch result {
          
        case .success:
          
           LKProgressHUD.dismiss()
          
          guard let userInfoVc = self.storyboard?.instantiateViewController(identifier: "userinfo") as? UserInfoViewController else { return }
          
          self.present(userInfoVc, animated: true, completion: nil)

        case .failure(let error):
          
          LKProgressHUD.showFailure(text: error.localizedDescription, controller: self)
        }
    }
  }
  
  func setUpBtn() {
    
    fbLoginBtn.layer.cornerRadius = 20
 
    visitorRegisterBtn.layer.cornerRadius = 20
  
    googleLoginBtn.layer.cornerRadius = 20

    appleLoginBtn.layer.cornerRadius = 20
    
    appleLoginBtn.layer.borderWidth = 1.0
    
    appleLoginBtn.layer.borderColor = UIColor.black.cgColor
    
    GIDSignIn.sharedInstance()?.presentingViewController = self
    
    logoLabel.transform = CGAffineTransform(a: 1.0, b: -0.15, c: 0, d: 0.7, tx: 0, ty: 10)
    
    let backView = backgroundManager.setUpView(view: self.view)
    
    self.view.layer.insertSublayer(backView, at: 0)
  }
  
  @objc func goToUserInfo () {
    
    guard let userInfoVc = self.storyboard?.instantiateViewController(identifier: "userinfo") as? UserInfoViewController else { return }
    
    self.present(userInfoVc, animated: true, completion: nil)
  }
}
