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
    self.view.backgroundColor = UIColor.LG1
    
//    NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("acceptRequester"), object: nil)
//    NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("refuseRequester"), object: nil)
    navigationItem.leftBarButtonItem?.tintColor = .black
    navigationItem.rightBarButtonItem?.tintColor = .black
  }
  
  @objc func reload() {
    readRequester()
  }
  
  var indexRow = 0
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setUpTable()
    UserManager.shared.isRequester = true
    
    if UserManager.shared.isTourist {
      
      noRequesterLabel.text = "請先去個人頁登入享有功能"
    
    } else if UserManager.shared.currentUserInfo?.status == 0 {
      noRequesterLabel.text = "當前沒有任務                                        趕快去新增任務吧"
    } else if UserManager.shared.currentUserInfo?.status == 2 {
      
      noRequesterLabel.text = "當前您是任務接受者"
    } else {
      noRequesterLabel.text = ""
      readRequester()
    }
    NotificationCenter.default.post(name: Notification.Name("hide"), object: nil)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    UserManager.shared.isRequester = false
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if UserManager.shared.isTourist {
      
    } else if UserManager.shared.currentUserInfo?.status == 1 {
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
        noRequesterLabel.text = ""
        requesterTable.backgroundColor = UIColor.LG1
        refreshControl.endRefreshing()
        requesterTable.reloadData()
      }
    }
  }
  
  var storeInfo = [AccountInfo]()
  
  var taskinfo: TaskInfo?
  
  var refreshControl: UIRefreshControl!
  
  func setUpTable() {
    requesterTable.delegate = self
    requesterTable.dataSource = self
    refreshControl = UIRefreshControl()
    requesterTable.separatorStyle = .none
    requesterTable.addSubview(refreshControl)
    refreshControl.addTarget(self, action: #selector(loadData), for: .valueChanged)
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
          SwiftMes.shared.showWarningMessage(body: "您當前沒有任務", seconds: 1.0)
        } else if taskCount[0].status == 1 {
          strongSelf.userInfo = []
          strongSelf.requesterTable.reloadData()
          strongSelf.taskinfo = taskCount[0]
          LKProgressHUD.dismiss()
          SwiftMes.shared.showWarningMessage(body: "任務進行中", seconds: 1.0)
        } else {
          
          if taskCount[0].requester.count == 0 {
            strongSelf.userInfo = []
            strongSelf.taskinfo = taskCount[0]
            strongSelf.requesterTable.reloadData()
            
          } else {
            strongSelf.taskinfo = taskCount[0]
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
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "test" {
      guard let userVC = segue.destination as? PersonInfoViewController else { return }
      UserManager.shared.isRequester = true
      UserManager.shared.requesterInfo = userInfo[indexRow]
      userVC.isRequester = true
      userVC.requester = userInfo[indexRow]
    }
  }
}

extension RequesterViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return userInfo.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "requester", for: indexPath) as? RequesterTableViewCell else { return UITableViewCell() }
    
    let user = userInfo[indexPath.row]
    var averageStar = 0.0
    var noJudge = false
    if user.taskCount == user.noJudgeCount {
      noJudge = true
    } else {
      averageStar = (user.totalStar / Double(user.taskCount - user.noJudgeCount)) - user.minusStar
    }
    
    cell.setUp(nickName: user.nickname, starcount: averageStar, image: userInfo[indexPath.row].photo, index: indexPath.row, taskCount: user.taskCount, noJudge: noJudge)
    
    cell.delegate = self
    
    return cell
  }
}

extension RequesterViewController: CheckPersonalInfoManager {
  func checkTheInfo(tableViewCell: RequesterTableViewCell, index: Int) {
    
    indexRow = index
    
    guard let userVC = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(identifier: "PersonInfoViewController") as? PersonInfoViewController,
         let taskinfoData = taskinfo else { return }
         UserManager.shared.isRequester = true
         UserManager.shared.requesterInfo = userInfo[indexRow]
         userVC.isRequester = true
         userVC.taskInfo = taskinfoData
         userVC.requester = userInfo[indexRow]
         self.navigationController?.pushViewController(userVC, animated: false)
  }
}
