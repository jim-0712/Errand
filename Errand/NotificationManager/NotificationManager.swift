//
//  NotificationManager.swift
//  Errand
//
//  Created by Jim on 2020/2/5.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseMessaging
import UIKit
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
          
          UserManager.shared.updatefcmToken()

    }
    
   func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage.appData)
    }
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        updateFirestorePushTokenIfNeeded()
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(response)
    }
  
}

