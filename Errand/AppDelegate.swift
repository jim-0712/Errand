//
//  AppDelegate.swift
//  Errand
//
//  Created by Jim on 2020/1/15.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import GoogleMaps
import GoogleSignIn
import UserNotifications
import FBSDKLoginKit
import FirebaseFirestore
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate, UNUserNotificationCenterDelegate {
  
  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
    if let error = error {
      print(error)
      return
    }
    guard let authentication = user.authentication else {return}
    let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
    Auth.auth().signIn(with: credential) { (_, error) in
      if let error = error {
        print(error)
        return
      }
      NotificationCenter.default.post(name: Notification.Name("userInfo"), object: nil)
    }
  }
  
  var window: UIWindow?
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    
    if url.scheme! == "fb473880586821358" {
      
      ApplicationDelegate.shared.application(app, open: url, options: options)
      
      return true
    } else {
      
      return GIDSignIn.sharedInstance().handle(url)
    }
  }
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    
    NotificationCenter.default.addObserver(self, selector: #selector(perFormPushVC), name: Notification.Name("popVC"), object: nil)
    
    FirebaseApp.configure()
    
    GMSServices.provideAPIKey("AIzaSyBbTnBn0MHPMnioaL4y68Da3d41JlaSY-g")
    
    GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
    
    GIDSignIn.sharedInstance().delegate = self
    
    UNUserNotificationCenter.current().delegate = self
    
    let pushManager = PushNotificationManager()
    
    pushManager.registerForPushNotifications()
    
    var firstVC: UIViewController?
    
    window = UIWindow(frame: UIScreen.main.bounds)
    
    if UserDefaults.standard.value(forKey: "login") as? Bool != nil {
      
      firstVC = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab") as? TabBarViewController
      
      UserManager.shared.isTourist = false
      
      window?.rootViewController = firstVC
      
      window?.makeKeyAndVisible()
      
      return true
    } else {
      
      firstVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "main") as? ViewController
      
      window?.rootViewController = firstVC
      
      window?.makeKeyAndVisible()
      
      return true
    }
  }
  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    
    var tokenString = ""
    for byte in deviceToken {
      let hexString = String(format: "%02x", byte)
      tokenString += hexString
    }
    UserDefaults.standard.set(tokenString, forKey: "deviceToken")
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    //
    
    print("Hi")
    print("Recived: \(userInfo)")
    
    var pretitle = ""
    var prebody = ""
    if let info = userInfo["aps"] as? [String: Any] {
      guard let message = info["alert"] as? [String: Any] else { return }
      guard let title = message["title"] as? String,
        let body = message["body"] as? String else { return }
      pretitle = title
      prebody = body
    }
    
//    let state = application.applicationState
//
//    if state == .active {
////      backGroundNoti(title: pretitle, body: prebody)
//      print("1")
//    } else if state == .inactive {
//      print("2")
//    } else {
//      print("3")
//    }
    
    completionHandler(.newData)
  }
  
  @objc func perFormPushVC() {
    let storyboard = UIStoryboard(name: "Mission", bundle: nil)
    if let conversationVC = storyboard.instantiateViewController(withIdentifier: "startMission") as? StartMissionViewController,
      let tabBarController = self.window?.rootViewController as? TabBarViewController,
      let navController = tabBarController.selectedViewController as? UINavigationController {
      tabBarController.dismiss(animated: true) {
        conversationVC.modalPresentationStyle = .fullScreen
        tabBarController.present(conversationVC, animated: true, completion: nil)
      }
    }
  }
  
  func backGroundNoti(title: String, body: String) {
    
    let center = UNUserNotificationCenter.current()
    let content = UNMutableNotificationContent()
    content.title = "背景"
    content.body = "背景"
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
    let request = UNNotificationRequest(identifier: "Errand", content: content, trigger: trigger)
    center.add(request) { error in
      if error != nil {
        print(error?.localizedDescription)
      }
      print("ya")
    }
  }
  
  lazy var persistentContainer: NSPersistentContainer = {
  
    let container = NSPersistentContainer(name: "Errand")
    container.loadPersistentStores(completionHandler: { (_, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    return container
  }()
  
  // MARK: - Core Data Saving support
  
  func saveContext () {
    let context = persistentContainer.viewContext
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }
  
}
