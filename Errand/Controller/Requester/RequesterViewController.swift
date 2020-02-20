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
    
    //      NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("acceptRequester"), object: nil)
    //      NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("refuseRequester"), object: nil)
    navigationController?.navigationItem.largeTitleDisplayMode = .always
  }
  
  @objc func reload() {
    readRequester()
  }
  
  func showMapAlert(title: String, message: String, viewController: UIViewController) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "ok", style: .default) { _ in
      let mapView = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab")
      self.view.window?.rootViewController = mapView
    }
    controller.addAction(okAction)
    viewController.present(controller, animated: true, completion: nil)
  }
  
  func showTaskAlert(title: String, message: String, viewController: UIViewController) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "ok", style: .default) { _ in
      let mapView = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab")
      self.view.window?.rootViewController = mapView
//      if let conversationVC = UIStoryboard.init(name: "Mission", bundle: nil).instantiateViewController(withIdentifier: "startMission") as? StartMissionViewController {
//
//        UserManager.shared.currentUserInfo = nil
//        conversationVC.modalPresentationStyle = .fullScreen
//        viewController.present(conversationVC, animated: true, completion: nil)
//      }
    }
  controller.addAction(okAction)
  viewController.present(controller, animated: true, completion: nil)
}

override func viewWillAppear(_ animated: Bool) {
  super.viewWillAppear(animated)
  
  if UserManager.shared.currentUserInfo?.status == 0 {
    
    showAlert(title: "注意", message: "當前沒有任務", viewController: self)
    
  } else if  UserManager.shared.currentUserInfo?.status == 2 {
    
    showTaskAlert(title: "注意", message: "任務進行中", viewController: self)
    
  } else {
    
    setUpTable()
    readRequester()
  }
  NotificationCenter.default.post(name: Notification.Name("onTask"), object: nil)
}

var userInfo = [AccountInfo]() {
  didSet {
    if userInfo.isEmpty {
      LKProgressHUD.show(controller: self)
      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        LKProgressHUD.dismiss()
      }
      refreshControl.endRefreshing()
      requesterTable.reloadData()
    } else {
      LKProgressHUD.dismiss()
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
        strongSelf.showAlert(title: "注意", message: "您當前沒有任務", viewController: strongSelf)
        
      } else if taskCount[0].status == 1 {
        strongSelf.userInfo = []
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
