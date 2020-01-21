//
//  UserInfoViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/15.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import FirebaseAuth

class UserInfoViewController: UIViewController {
  
  lazy var gender = 1
  
  @IBOutlet weak var cheatView: UIView!
  
  @IBOutlet weak var nickNameLabel: UILabel!
  
  @IBOutlet weak var nickNameText: UITextField!
  
  @IBAction func genderSegmentAct(_ sender: UISegmentedControl) {
    
    switch sender.selectedSegmentIndex {
      
    case 0:
      
      gender = 1
      
    case 1:
      
      gender = 0
      
    default:
      
      gender = 1
      
    }
  }
  
  @IBAction func createDataBase(_ sender: Any) {
    
    guard let email = Auth.auth().currentUser?.email else { return }
    
    guard let nickName = nickNameText.text else { return }
    
    UserManager.shared.createDataBase(classification: "Users", gender: gender, nickName: nickName, email: email) { result in
      
      switch result {
        
      case .success(let success):
        
        LKProgressHUD.showSuccess(text: success, controller: self)
        
        guard let userInfoVc  = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab") as? UITabBarController else { return }
        
        self.present(userInfoVc, animated: true, completion: nil)
        
      case .failure(let error):
        
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: self)
        
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUpView()
    // Do any additional setup after loading the view.
    let backView = BackgroundManager.shared.setUpView(view: self.view)
    
    cheatView.layer.insertSublayer(backView, at: 0)
  }
  
  func setUpView() {
    
    cheatView.layer.cornerRadius = 20
    
  }
}
