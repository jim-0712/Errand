//
//  NotificationManager.swift
//  Errand
//
//  Created by Jim on 2020/2/5.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Firebase
import Foundation
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications

class PushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
  
  func registerForPushNotifications() {
    if #available(iOS 10.0, *) {
      
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: {_, _ in })
      
      Messaging.messaging().delegate = self
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      UIApplication.shared.registerUserNotificationSettings(settings)
    }
    UIApplication.shared.registerForRemoteNotifications()
    updateFirestorePushTokenIfNeeded()
  }
  
  func updateFirestorePushTokenIfNeeded() {
    
    if let token = Messaging.messaging().fcmToken {
      
      UserDefaults.standard.set(token, forKey: "fcmToken")
      UserManager.shared.updatefcmToken()
    }
    
  }
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
    updateFirestorePushTokenIfNeeded()
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    
    guard let userInfo = notification.request.content.userInfo as? [String: Any] else { return }
    guard let info = userInfo["aps"] as? [String: Any],
      let message = info["alert"] as? [String: Any],
      let  body = message["body"] as? String else { return }
    
    if body == "對方放棄任務" {
      backToMap()
    }
    completionHandler([.badge, .sound, .alert])
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    
    guard let userInfo = response.notification.request.content.userInfo as? [String: Any] else { return }
    guard let info = userInfo["aps"] as? [String: Any],
      let message = info["alert"] as? [String: Any],
      let body = message["body"] as? String else { return }
    
    if body != "您已被拒絕" && body != "對方放棄任務" && body != "有人申請任務" {
      perFormPushVC()
    } 
    
    if body == "對方放棄任務" {
      backToRootRefuse()
    }
    NotificationCenter.default.post(name: Notification.Name("getMissionList"), object: nil)
    completionHandler()
  }
  
  func perFormPushVC() {
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    UserManager.shared.readUserInfo(uid: uid, isSelf: true) { [weak self] result in
      guard let strongSelf = self else { return }
      switch result {
      case .success:
        strongSelf.gotoDetail()
      case .failure:
        print("Fail on read userInfo")
      }
    }
  }
  
  func backToRootRefuse () {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
    
    _ = UIStoryboard(name: "Mission", bundle: nil)
    
    guard let tabBarController = appDelegate.window?.rootViewController as? TabBarViewController,
      let _ = tabBarController.selectedViewController as? UINavigationController else {
        
        return
    }
    tabBarController.dismiss(animated: true)
  }
  
  func backToMap() {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
    guard let tabBarController = appDelegate.window?.rootViewController as? TabBarViewController,
      let navi = tabBarController.selectedViewController as? UINavigationController else {
        return
    }
    
    if navi.visibleViewController is MissionDetailViewController == true {
      
      guard let mapVc  = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(withIdentifier: "tab") as? TabBarViewController else { return }
      appDelegate.window?.rootViewController = mapVc
    }
  }
  
  func gotoDetail() {
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    let group = DispatchGroup()
    
    group.enter()
    
    var status = 0
    
    UserManager.shared.readUserInfo(uid: uid, isSelf: true) { result in
      switch result {
      case .success(let userInfo):
        status = userInfo.status
        group.leave()
      case .failure:
        print("Fail on read userInfo")
      }
    }
    
    group.notify(queue: DispatchQueue.main) {
      
      if status != 0 {
        let storyboard = UIStoryboard(name: "Mission", bundle: nil)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let conversationVC = storyboard.instantiateViewController(withIdentifier: "detailViewController") as? MissionDetailViewController,
          let tabBarController = appDelegate.window?.rootViewController as? TabBarViewController,
          let navigationController = tabBarController.selectedViewController as? UINavigationController else {
            
            return
        }
        
        if navigationController.visibleViewController is MissionDetailViewController == false {
          
          if tabBarController.presentedViewController == nil {
            tabBarController.dismiss(animated: true) {
              conversationVC.modalPresentationStyle = .fullScreen
              UserManager.shared.currentUserInfo?.status = 2
              conversationVC.isMissionON = true
              tabBarController.present(conversationVC, animated: true, completion: nil)
            }
          } else {
            tabBarController.presentedViewController?.dismiss(animated: true, completion: {
            tabBarController.dismiss(animated: true) {
                UserManager.shared.currentUserInfo = nil
                conversationVC.modalPresentationStyle = .fullScreen
                conversationVC.isMissionON = true
                tabBarController.present(conversationVC, animated: true, completion: nil)
              }
            })
          }
        }
      }
    }
  }
}
