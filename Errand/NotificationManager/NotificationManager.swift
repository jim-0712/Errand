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
      // For iOS 10 display notification (sent via APNS)
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: {_, _ in })
      // For iOS 10 data message (sent via FCM)
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
    
    NotificationCenter.default.post(name: Notification.Name("reloadUser"), object: nil)
    
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
    
    if body != "您已被拒絕" && body != "對方放棄任務" {
      NotificationCenter.default.post(name: Notification.Name("popVC"), object: nil)
    } 

    if body == "任務接受成功" || body == "任務完成" {
      NotificationCenter.default.post(name: Notification.Name("reloadUser"), object: nil)
    }
    
    if body == "對方放棄任務" {
      NotificationCenter.default.post(name: Notification.Name("refusePOP"), object: nil)
    }
    
    NotificationCenter.default.post(name: Notification.Name("getMissionList"), object: nil)
      completionHandler()
  }
}
