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
  
  var userInfo = [AccountInfo]() {
    didSet {
      if userInfo.isEmpty {
        LKProgressHUD.dismiss()
        listImage.isHidden = true
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
  
  var storeAccountInfo = [AccountInfo]()
  
  let segueIdentifier = "requesterInfo"
  
  var taskinfo: TaskInfo?
  
  var refreshControl: UIRefreshControl!
  
  var indexRow = 0
  
  @IBOutlet weak var requesterTable: UITableView!
  
  @IBOutlet weak var listImage: UIImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    listImage.isHidden = true
    setUpTable()
    self.view.backgroundColor = UIColor.LG1
    navigationItem.leftBarButtonItem?.tintColor = .white
    navigationItem.rightBarButtonItem?.tintColor = .white
    NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("requester"), object: nil)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    UserManager.shared.isRequester = true
    
    if UserManager.shared.isTourist {
      listImage.isHidden = true
      noRequesterLabel.text = "請先去個人頁登入享有功能"
      
    } else if UserManager.shared.currentUserInfo?.status == 0 {
      listImage.isHidden = false
      noRequesterLabel.text = "當前沒有任務                                        趕快去新增任務吧"
    } else if UserManager.shared.currentUserInfo?.status == 2 {
      listImage.isHidden = true
      noRequesterLabel.text = "當前您是任務接受者"
    } else {
      listImage.isHidden = true
      noRequesterLabel.text = ""
      fetchRequester()
    }
    self.refreshControl.endRefreshing()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    UserManager.shared.isRequester = false
    self.refreshControl.endRefreshing()
    SwiftMes.shared.dismiss()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == segueIdentifier {
      guard let userVC = segue.destination as? PersonInfoViewController else { return }
      UserManager.shared.isRequester = true
      UserManager.shared.requesterInfo = userInfo[indexRow]
      userVC.isRequester = true
      userVC.requester = userInfo[indexRow]
    }
  }
  
  @objc func reload() {
    fetchRequester()
  }
  
  @objc func loadData() {
    requesterTable.isScrollEnabled = false
    fetchRequester()
  }
  
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
  
  func showAlert(title: String, message: String, viewController: UIViewController) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "ok", style: .default) { _ in
      
      let mapView = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(withIdentifier: "tab")
      
      self.view.window?.rootViewController = mapView
    }
    controller.addAction(okAction)
    viewController.present(controller, animated: true, completion: nil)
  }
  
  func fetchRequester() {
    guard let uid = UserManager.shared.currentUserInfo?.uid else { return }
    
    TaskManager.shared.fetchSpecificParameterData(parameter: "uid", parameterString: uid) { [weak self] result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success(let taskInfo):
        
        let taskOnGoing = taskInfo.filter { info in
          
          return info.isComplete ? false : true

        }
        
        strongSelf.handleRequesterData(taskInfo: taskOnGoing)
        
      case .failure(let error):
        
        LKProgressHUD.dismiss()
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
      }
    }
  }
  
  func stopTabBar(status: Bool) {
    guard let tab = self.tabBarController?.tabBar.items else { return }
    tab.forEach { tabItem in
      tabItem.isEnabled = status
    }
  }
  
  func handleRequesterData(taskInfo: [TaskInfo]) {
    
    if taskInfo.isEmpty || taskInfo[0].isComplete {
      userInfo = []
      LKProgressHUD.dismiss()
      self.refreshControl.endRefreshing()
      stopTabBar(status: false)
      SwiftMes.shared.showWarningMessage(body: "您當前沒有任務", seconds: 1.0)
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        self.stopTabBar(status: true)
        self.requesterTable.isScrollEnabled = true
      }
      
    } else if taskInfo[0].status == 1 {
      userInfo = []
      requesterTable.reloadData()
      taskinfo = taskInfo[0]
      LKProgressHUD.dismiss()
      self.refreshControl.endRefreshing()
      SwiftMes.shared.showWarningMessage(body: "任務進行中", seconds: 1.0)
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        self.stopTabBar(status: true)
        self.requesterTable.isScrollEnabled = true
      }
    } else if taskInfo[0].requester.isEmpty {
      userInfo = []
      taskinfo = taskInfo[0]
      requesterTable.reloadData()
    } else {
      taskinfo = taskInfo[0]
      for count in 0 ..< taskInfo[0].requester.count {
        UserManager.shared.readUserInfo(uid: taskInfo[0].requester[count], isSelf: false) {[weak self] result in
          guard let strongSelf = self else { return }
          switch result {
            
          case .success(let accountInfo):
            
            strongSelf.storeAccountInfo = []
            strongSelf.storeAccountInfo.append(accountInfo)
            if count == taskInfo[0].requester.count - 1 {
              LKProgressHUD.dismiss()
              strongSelf.userInfo = strongSelf.storeAccountInfo
            }
            
          case .failure(let error):
            
            LKProgressHUD.dismiss()
            LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
          }
        }
      }
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
    
    guard let userVC = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "PersonInfoViewController") as? PersonInfoViewController,
      let taskinfoData = taskinfo else { return }
    UserManager.shared.isRequester = true
    UserManager.shared.requesterInfo = userInfo[indexRow]
    userVC.isRequester = true
    userVC.taskInfo = taskinfoData
    userVC.requester = userInfo[indexRow]
    self.navigationController?.pushViewController(userVC, animated: false)
  }
}
