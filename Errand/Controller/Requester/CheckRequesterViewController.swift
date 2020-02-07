//
//  GoingMissionViewController.swift
//  Errand
//
//  Created by Jim on 2020/2/5.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import FirebaseAuth

class CheckRequesterViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setUpTableView()
    readTask()
    self.tabBarController?.tabBar.barTintColor = UIColor.black
    // Do any additional setup after loading the view.
  }
  
  var averageStar = 0.0
  
  var infoData: AccountInfo?
  
  var taskInfo: TaskInfo?
  
  let profileDetail = ["暱稱", "歷史評分", "關於我"]
  
  @IBOutlet weak var requesterInfo: UITableView!
  
  func setUpTableView() {
    
    requesterInfo.delegate = self
    requesterInfo.dataSource = self
    requesterInfo.separatorStyle = .none
    requesterInfo.rowHeight = UITableView.automaticDimension
    requesterInfo.register(UINib(nibName: "PhotoTableViewCell", bundle: nil), forCellReuseIdentifier: "personPhoto")
    requesterInfo.register(UINib(nibName: "PersonDetailTableViewCell", bundle: nil), forCellReuseIdentifier: "personDetail")
    requesterInfo.register(UINib(nibName: "PersonAboutTableViewCell", bundle: nil), forCellReuseIdentifier: "personAbout")
  }
  
  func readTask() {
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    TaskManager.shared.readSpecificData(parameter: "uid", parameterString: uid) { result in
      switch result {
        
      case .success(let data):
        
        self.taskInfo = data[0]
        
      case .failure(let error):
        
        print(error.localizedDescription)
      }
    }
  }
  
  @IBAction func refuseAct(_ sender: Any) {
    
    guard let user = infoData,
      var taskInfo = taskInfo else { return }
    
    
    taskInfo.requester = taskInfo.requester.filter({ info in
      
      if info != user.uid {
        return true
      }else {
        return false
      }
    })
    
    taskInfo.refuse.append(user.uid)
    
    TaskManager.shared.updateWholeTask(task: taskInfo) { [weak self] result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success:
        
        NotificationCenter.default.post(name: Notification.Name("refuseRequester"), object: nil)
        strongSelf.navigationController?.popViewController(animated: true)
        
      case .failure:
        
        TaskManager.shared.showAlert(title: "失敗", message: "請重新接受", viewController: strongSelf)
      }
    }
    
    let sender = PushNotificationSender()
    sender.sendPushNotification(to: user.fcmToken, body: "您已被拒絕")
  }
  
  @IBAction func confirmAct(_ sender: Any) {
    
    guard let user = infoData,
      var taskInfo = taskInfo else { return }
    
    taskInfo.missionTaker = user.uid
    taskInfo.requester = []
    taskInfo.status = 1
    
    TaskManager.shared.updateWholeTask(task: taskInfo) { [weak self] result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success:
        
        NotificationCenter.default.post(name: Notification.Name("acceptRequester"), object: nil)
        strongSelf.navigationController?.popViewController(animated: true)
        
      case .failure:
        
        TaskManager.shared.showAlert(title: "失敗", message: "請重新接受", viewController: strongSelf)
      }
    }
    
    let sender = PushNotificationSender()
    sender.sendPushNotification(to: user.fcmToken, body: "任務接受成功")
  }
}

extension CheckRequesterViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return 4
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let infoData = infoData else { return UITableViewCell() }
    
    if infoData.taskCount == 0 {
      averageStar = 0.0
    } else {
      averageStar = infoData.totalStar / Double(infoData.taskCount)
    }
    
    if indexPath.row == 0 {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "personPhoto", for: indexPath) as? PhotoTableViewCell else { return UITableViewCell() }
      
      cell.setUpView(personPhoto: infoData.photo, nickName: infoData.nickname, email: infoData.email)
      cell.choosePhotoBtn.isHidden = true
      
      return cell
    } else if indexPath.row == 1 {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "personDetail", for: indexPath) as? PersonDetailTableViewCell else { return UITableViewCell() }
      
      cell.setUpView(isSetting: false, detailTitle: profileDetail[0], content: infoData.nickname)
      
      return cell
    } else if indexPath.row == 2 {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "requesterRate", for: indexPath) as? RequesterRateTableViewCell else { return UITableViewCell() }
      
      cell.setUp(averageStar: averageStar, titleLabel: profileDetail[1])
      return cell
    } else {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "personAbout", for: indexPath) as? PersonAboutTableViewCell else { return UITableViewCell() }
      
      cell.setUpView(isSetting: false, titleLabel: profileDetail[2], content: infoData.about)
      
      return cell
    }
  }
}
