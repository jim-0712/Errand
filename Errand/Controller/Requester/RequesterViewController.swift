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
      
      NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("acceptRequester"), object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("refuseRequester"), object: nil)

      if UserManager.shared.currentUserInfo?.status == 2 {
        
      } else {
        
        setUpTable()
        readRequester()
      }
    }
  
  @objc func reload() {
    
    readRequester()
  }
  
  var refreshControl: UIRefreshControl!
  
  var userInfo = [AccountInfo]() {
    didSet {
      if userInfo.isEmpty {
        
        LKProgressHUD.show(controller: self)
      } else {
        LKProgressHUD.dismiss()
        self.refreshControl.endRefreshing()
        requesterTable.reloadData()
      }
    }
}
  
  var storeInfo = [AccountInfo]()

  func setUpTable() {
    requesterTable.delegate = self
    requesterTable.dataSource = self
    refreshControl = UIRefreshControl()
    requesterTable.addSubview(refreshControl)
    refreshControl.addTarget(self, action: #selector(loadData), for: .valueChanged)
    requesterTable.separatorStyle = .none
    requesterTable.rowHeight = UITableView.automaticDimension
    requesterTable.register(UINib(nibName: "RequesterTableViewCell", bundle: nil), forCellReuseIdentifier: "requester")
  }
  
  @objc func loadData() {
    
    readRequester()
  }
  
  func readRequester() {
    
    guard let uid = UserManager.shared.currentUserInfo?.uid,
         let currentUser = UserManager.shared.currentUserInfo else { return }
    
    TaskManager.shared.readSpecificData(parameter: "uid", parameterString: uid) { [weak self] result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success(let taskInfo):
        
        if taskInfo.count == 0 {
          strongSelf.userInfo = []
          TaskManager.shared.showAlert(title: "注意", message: "您當前沒有任務", viewController: strongSelf)
          
        } else if taskInfo[0].status == 1 {
          strongSelf.userInfo = []
          TaskManager.shared.showAlert(title: "注意", message: "任務進行中", viewController: strongSelf)
        } else {
          
          for count in 0 ..< taskInfo[0].requester.count {
            
            UserManager.shared.readData(uid: taskInfo[0].requester[count]) { result in
              
              switch result {
                
              case .success(let accountInfo):
                
                strongSelf.storeInfo.append(accountInfo)
                
                if count == taskInfo[0].requester.count - 1 {
                  
                  LKProgressHUD.dismiss()
                  
                  strongSelf.userInfo = strongSelf.storeInfo
                  
                  UserManager.shared.currentUserInfo = currentUser
                }
                
              case .failure(let error):
                
                LKProgressHUD.dismiss()
                
                LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
                
              }
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
  
  func checkRequest(viewController: UIViewController, indexInt: Int) {
    
    guard let requesterInfo = self.storyboard?.instantiateViewController(identifier: "requesterInfo") as? CheckRequesterViewController else { return }

      requesterInfo.requsterInfoData = self.userInfo[indexInt]
      
      self.show(requesterInfo, sender: nil)
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
    
    checkRequest(viewController: self, indexInt: index)
  }
}
