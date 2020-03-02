//
//  TabBarViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/31.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Firebase
import MarqueeLabel

private enum Tab {
  
  case map
  
  case missionList
  
  case profile
  
  case requester
  
  case friend
  
  func controller() -> UIViewController {
    
    var controller: UIViewController
    
    switch self {
      
    case .map: controller = UIStoryboard.map.instantiateInitialViewController()!
      
    case .missionList: controller = UIStoryboard.missionList.instantiateInitialViewController()!
      
    case .profile: controller = UIStoryboard.profile.instantiateInitialViewController()!
      
    case .requester: controller = UIStoryboard.requester.instantiateInitialViewController()!
      
    case .friend: controller = UIStoryboard.friend.instantiateInitialViewController()!
    }
    
    controller.tabBarItem = tabBarItem()
    
    controller.tabBarItem.imageInsets = UIEdgeInsets(top: 8.0, left: 0.0, bottom: -10.0, right: 0.0)
    
    return controller
  }
  
  func tabBarItem() -> UITabBarItem {
    
    switch self {
      
    case .map:
      return UITabBarItem(
        title: nil,
        image: UIImage.init(named: "pin_0"),
        selectedImage: UIImage.init(named: "pin_1")
      )
      
    case .missionList:
      return UITabBarItem(
        title: nil,
        image: UIImage.init(named: "list_0"),
        selectedImage: UIImage.init(named: "list_1")
      )
    case .profile:
      return UITabBarItem(
        title: nil,
        image: UIImage.init(named: "id-card_0"),
        selectedImage: UIImage.init(named: "id-card_1")
      )
    case .requester:
      return UITabBarItem(
        title: nil,
        image: UIImage.init(named: "user_0"),
        selectedImage: UIImage.init(named: "user_1")
      )
      
    case .friend:
      return UITabBarItem(
        title: nil,
        image: UIImage.init(named: "bubble_0"),
        selectedImage: UIImage.init(named: "bubble_1")
      )
    }
  }
}

class TabBarViewController: UITabBarController, UITabBarControllerDelegate {
  
  private let tabs: [Tab] = [.map, .missionList, .requester, .friend, .profile]
  
  var trolleyTabBarItem: UITabBarItem!
  
  var orderObserver: NSKeyValueObservation!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NotificationCenter.default.addObserver(self, selector: #selector(hideNoti), name: Notification.Name("hide"), object: nil)
    
    viewControllers = tabs.map({ $0.controller() })
    
    delegate = self
 
    setUpListener()
  }
  
  let notiView = UIView()
  
  let lengthyLabel = MarqueeLabel()
  
  let alert = UIImageView()
  
  private var reference: CollectionReference?
  
  let dbF = Firestore.firestore()
  
  func setUpListener() {
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    dbF.collection("Users").document(uid).addSnapshotListener { querySnapshot, error in
      guard querySnapshot != nil else {
        print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
        return
      }
      guard let quary = querySnapshot?.data() else { return }
      
      guard let onTask = quary["onTask"] as? Bool,
        let email = quary["email"] as? String,
        let nickname = quary["nickname"] as? String,
        let noJudgeCount = quary["noJudgeCount"] as? Int,
        let task = quary["task"] as? [String],
        let minusStar = quary["minusStar"] as? Double,
        let photo = quary["photo"] as? String,
        let blacklist = quary["blacklist"] as? [String],
        let report = quary["report"] as? Int,
        let fcmToken = quary["fcmToken"] as? String,
        let status = quary["status"] as? Int,
        let about = quary["about"] as? String,
        let totalStar = quary["totalStar"] as? Double,
        let taskCount = quary["taskCount"] as? Int,
        let uid = quary["uid"] as? String,
        let oppoBlacklist = quary["oppoBlacklist"] as? [String] else { return }
      
      let dataReturn = AccountInfo(email: email, nickname: nickname, noJudgeCount: noJudgeCount, task: task, minusStar: minusStar, photo: photo, report: report, blacklist: blacklist, oppoBlacklist: oppoBlacklist, onTask: onTask, fcmToken: fcmToken, status: status, about: about, taskCount: taskCount, totalStar: totalStar, uid: uid)
      
      UserManager.shared.currentUserInfo = dataReturn
      
      
  
    }
  }
  
  func setUpView() {
    notiView.frame = CGRect(x: 10, y: 35, width: self.view.frame.size.width, height: 50)
    notiView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
    notiView.backgroundColor = .clear
    self.view.addSubview(notiView)
    
    alert.image = UIImage(named: "bell")
    
    lengthyLabel.type = .continuous
    lengthyLabel.speed = .duration(3.0)
    lengthyLabel.animationCurve = .easeInOut
    lengthyLabel.fadeLength = 0.0
    lengthyLabel.leadingBuffer = 5.0
    lengthyLabel.trailingBuffer = 5.0
    lengthyLabel.backgroundColor = .white
    lengthyLabel.text = " 提醒親愛的用戶，您的任務進行中   "
    
    notiView.addSubview(lengthyLabel)
    lengthyLabel.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      lengthyLabel.centerXAnchor.constraint(equalTo: notiView.centerXAnchor, constant: 0),
      lengthyLabel.centerYAnchor.constraint(equalTo: notiView.centerYAnchor, constant: 0),
      lengthyLabel.heightAnchor.constraint(equalToConstant: 50),
      lengthyLabel.widthAnchor.constraint(equalToConstant: 280)
    ])
    
    notiView.addSubview(alert)
    alert.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      alert.trailingAnchor.constraint(equalTo: lengthyLabel.leadingAnchor, constant: -10),
      alert.centerYAnchor.constraint(equalTo: lengthyLabel.centerYAnchor),
      alert.widthAnchor.constraint(equalToConstant: 30),
      alert.heightAnchor.constraint(equalToConstant: 30)
    ])
  }
  
  @objc func setUpLabe() {
    
    guard let userStatus = UserManager.shared.currentUserInfo?.status else {
      self.showNotificationView(isON: false)
      return }
    if userStatus != 0 {
      self.setUpView()
      self.showNotificationView(isON: true)
    } else {
      self.showNotificationView(isON: false)
    }
  }
  
  func showNotificationView(isON: Bool) {
    if isON {
          alert.isHidden = !isON
          notiView.isHidden = !isON
          lengthyLabel.isHidden = !isON
        } else {
          alert.isHidden = isON
          notiView.isHidden = isON
          lengthyLabel.isHidden = isON
        }
  }
  
  // MARK: - UITabBarControllerDelegate
  
  func tabBarController(
    _ tabBarController: UITabBarController,
    shouldSelect viewController: UIViewController
  ) -> Bool {
    
    guard let navVC = viewController as? UINavigationController,
      navVC.viewControllers.first is GoogleMapViewController
      else { return true }
    
    return true
  }
}

extension TabBarViewController {
  @objc func hideNoti() {
    alert.isHidden = true
    notiView.isHidden = true
    lengthyLabel.isHidden = true
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      LKProgressHUD.dismiss()
    }
  }
}
