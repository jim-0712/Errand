//
//  TabBarViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/31.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Firebase

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
        image: UIImage.init(named: "bubble_1"),
        selectedImage: UIImage.init(named: "bubble_0")
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
    
    viewControllers = tabs.map({ $0.controller() })
    
    self.tabBar.tintColor = UIColor.white
    
    self.tabBar.unselectedItemTintColor = .white
    
    self.tabBar.barTintColor = UIColor.BB1
    
    delegate = self
    
    setUpListener()
  }
  
  private var reference: CollectionReference?
  
  let dbF = Firestore.firestore()
  
  func setUpListener() {
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    LKProgressHUD.show(controller: self)
    
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
      
      LKProgressHUD.dismiss()
      UserManager.shared.currentUserInfo = dataReturn
      UserManager.shared.isChange = !UserManager.shared.isChange
     
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
