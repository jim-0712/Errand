//
//  RequesterViewController.swift
//  Errand
//
//  Created by Jim on 2020/2/5.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class RequesterViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

      if UserManager.shared.currentUserInfo?.status == 2 {
        
      
      } else {
        
        setUpTable()
        readRequester()
      }
    }
  
  var userInfo = [AccountInfo]() {
    didSet {
      if userInfo.isEmpty{
        
        LKProgressHUD.show(controller: self)
      } else {
        
        requesterTable.reloadData()
      }
    }
}
  
  var storeInfo = [AccountInfo]()

  func setUpTable() {
    requesterTable.delegate = self
    requesterTable.dataSource = self
    requesterTable.separatorStyle = .none
    requesterTable.rowHeight = UITableView.automaticDimension
    requesterTable.register(UINib(nibName: "RequesterTableViewCell", bundle: nil), forCellReuseIdentifier: "requester")
  }
  
  func readRequester() {
    
    guard let email = UserManager.shared.currentUserInfo?.email else { return }
    
    TaskManager.shared.readSpecificData(parameter: "email", parameterString: email) { [weak self] result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success(let taskInfo):
        
        for count in 0 ..< taskInfo[0].requester.count {
          
          UserManager.shared.readData(account: taskInfo[0].requester[count]) { result in
            
            switch result {
              
            case .success(let accountInfo):
              
              strongSelf.storeInfo.append(accountInfo)
              
              if count == taskInfo[0].requester.count - 1 {
                
                LKProgressHUD.dismiss()
                
                strongSelf.userInfo = strongSelf.storeInfo
              }
              
            case .failure(let error):
              
              LKProgressHUD.dismiss()
              
              LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
              
            }
          }
        }
        
      case .failure(let error):
        
        LKProgressHUD.dismiss()
        
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
      }
    }
  }
    
  @IBOutlet weak var requesterTable: UITableView!
  
  func presentAlert(viewController: UIViewController) {
    
    let controller = UIAlertController(title: "任務進行中", message: "請完成當前任務", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default) { _ in
      
//      guard let goingVc = self.storyboard?.instantiateViewController(identifier: "going") as? GoingMissionViewController else { return }
//
//
//
//      self.show(goingVc, sender: nil)
    }
    controller.addAction(okAction)
    present(controller, animated: true, completion: nil)
  }
  
}

extension RequesterViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return userInfo.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "requester", for: indexPath) as? RequesterTableViewCell else { return UITableViewCell() }
    
    cell.setUp(nickName: userInfo[indexPath.row].nickname, starcount: 4.5, image: userInfo[indexPath.row].photo, index: indexPath.row)
    
    cell.delegate = self
   
    return cell
  }
}

extension RequesterViewController: CheckPersonalInfoManager {
  func checkTheInfo(tableViewCell: RequesterTableViewCell, index: Int) {
    
    print("123")
  }
}
