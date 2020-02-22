//
//  RequesterViewController.swift
//  Errand
//
//  Created by Jim on 2020/2/5.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit


class RequesterViewController: UIViewController {
  
  @IBOutlet weak var noRequesterLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    
    
//          NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("acceptRequester"), object: nil)
//          NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("refuseRequester"), object: nil)
    navigationController?.navigationItem.largeTitleDisplayMode = .always
  }
  
  @objc func reload() {
    readRequester()
  }

override func viewWillAppear(_ animated: Bool) {
  super.viewWillAppear(animated)
  setUpTable()
  
  if UserManager.shared.isTourist {
    
    noRequesterLabel.text = "請先去個人頁登入享有功能"
    
  } else if UserManager.shared.currentUserInfo?.status == 0 {
    
    noRequesterLabel.text = "當前沒有任務                                        趕快去新增任務吧"
    requesterTable.backgroundColor = .clear
    
  } else if  UserManager.shared.currentUserInfo?.status == 2 {
    
    noRequesterLabel.text = "當前您是任務接受者，沒有申請者"
    requesterTable.backgroundColor = .clear
  } else {
    noRequesterLabel.text = "正在搜尋申請者中"
    requesterTable.backgroundColor = .clear
    readRequester()
  }
  NotificationCenter.default.post(name: Notification.Name("hide"), object: nil)
}
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if UserManager.shared.isTourist {
      
    } else if UserManager.shared.currentUserInfo?.status != 0 {
      preventTap()
    }
  }
  
  func preventTap() {
    guard let tabVC = self.view.window?.rootViewController as? TabBarViewController else { return }
    LKProgressHUD.show(controller: tabVC)
  }

var userInfo = [AccountInfo]() {
  didSet {
    if userInfo.isEmpty {
      LKProgressHUD.dismiss()
      noRequesterLabel.text = "目前沒有申請者"
      refreshControl.endRefreshing()
    } else {
      LKProgressHUD.dismiss()
      requesterTable.backgroundColor = .white
      refreshControl.endRefreshing()
      requesterTable.reloadData()
    }
  }
}

var storeInfo = [AccountInfo]()
  
var refreshControl: UIRefreshControl!
  
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

func showAlert(title: String, message: String, viewController: UIViewController) {
  let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
  let okAction = UIAlertAction(title: "ok", style: .default) { _ in
    
    let mapView = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab")
    
    self.view.window?.rootViewController = mapView
  }
  controller.addAction(okAction)
  viewController.present(controller, animated: true, completion: nil)
}

func readRequester() {
  guard let uid = UserManager.shared.currentUserInfo?.uid,
    let currentUser = UserManager.shared.currentUserInfo else { return }
  
  TaskManager.shared.readSpecificData(parameter: "uid", parameterString: uid) { [weak self] result in
    
    guard let strongSelf = self else { return }
    
    switch result {
      
    case .success(let taskInfo):
      
      let taskCount = taskInfo.filter { info in
        if info.isComplete {
          return false
        } else {
          return true
        }
      }
      
      if taskCount.count == 0 {
        strongSelf.userInfo = []
        LKProgressHUD.dismiss()
        strongSelf.showAlert(title: "注意", message: "您當前沒有任務", viewController: strongSelf)
        
      } else if taskCount[0].status == 1 {
        strongSelf.userInfo = []
        LKProgressHUD.dismiss()
        strongSelf.showAlert(title: "注意", message: "任務進行中", viewController: strongSelf)
      } else {
        
        if taskCount[0].requester.count == 0 {
          
          strongSelf.userInfo = []
        } else {
          
          for count in 0 ..< taskCount[0].requester.count {
            
            UserManager.shared.readData(uid: taskCount[0].requester[count]) { result in
              
              switch result {
                
              case .success(let accountInfo):
                
                strongSelf.storeInfo = []
                
                strongSelf.storeInfo.append(accountInfo)
                
                if count == taskCount[0].requester.count - 1 {
                  
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
