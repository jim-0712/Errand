//
//  TabBarViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/31.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

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
    
    //       controller.tabBarItem.titlePositionAdjustment = UIOffset(horizontal: <#T##CGFloat#>, vertical: <#T##CGFloat#>)
    
    return controller
  }
  
  func tabBarItem() -> UITabBarItem {
    
    switch self {
      
    case .map:
      return UITabBarItem(
        title: nil,
        image: UIImage.init(named: "earth"),
        selectedImage: UIImage.init(named: "earth_2")
      )
      
    case .missionList:
      return UITabBarItem(
        title: nil,
        image: UIImage.init(named: "list"),
        selectedImage: UIImage.init(named: "list_2")
      )
    case .profile:
      return UITabBarItem(
        title: nil,
        image: UIImage.init(named: "id_card"),
        selectedImage: UIImage.init(named: "id_card_2")
      )
    case .requester:
      return UITabBarItem(
        title: nil,
        image: UIImage.init(named: "question"),
        selectedImage: UIImage.init(named: "question_2")
      )
      
    case .friend:
    return UITabBarItem(
      title: nil,
      image: UIImage.init(named: "chat"),
      selectedImage: UIImage.init(named: "chat_2")
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
    
    NotificationCenter.default.addObserver(self, selector: #selector(setUpLabel), name: Notification.Name("onTask"), object: nil)
    viewControllers = tabs.map({ $0.controller() })

    delegate = self
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  @objc func setUpLabel() {
    
    guard let userStatus = UserManager.shared.currentUserInfo?.status else { return }
    if userStatus != 0 {
      self.showNotificationView(isON: true)
    } else {
      self.showNotificationView(isON: false)
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
