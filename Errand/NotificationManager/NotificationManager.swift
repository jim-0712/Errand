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
    print("hellooooooo")
    
    guard let userInfo = notification.request.content.userInfo as? [String: Any] else { return }
    guard let info = userInfo["aps"] as? [String: Any],
         let message = info["alert"] as? [String: Any],
         let  body = message["body"] as? String else { return }
    
    if body == "對方放棄任務" {
      
      NotificationCenter.default.post(name: Notification.Name("giveUpCome"), object: nil)
    }
    completionHandler([.badge, .sound, .alert])
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
      print("apple")
    
    guard let userInfo = response.notification.request.content.userInfo as? [String: Any] else { return }
    guard let info = userInfo["aps"] as? [String: Any],
         let message = info["alert"] as? [String: Any],
         let  body = message["body"] as? String else { return }
    
    if body != "您已被拒絕" && body != "對方放棄任務" && body != "有人申請任務" {
      NotificationCenter.default.post(name: Notification.Name("popVC"), object: nil)
    } 
    
    if body == "對方放棄任務" {
      NotificationCenter.default.post(name: Notification.Name("refusePOP"), object: nil)
    }
    
      NotificationCenter.default.post(name: Notification.Name("getMissionList"), object: nil)
      completionHandler()
  }
}
