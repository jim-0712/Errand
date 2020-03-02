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
import Fabric
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
      guard let uid = Auth.auth().currentUser?.uid else { return }
      UserDefaults.standard.set(uid, forKey: "uid")
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
    
    NotificationCenter.default.addObserver(self, selector: #selector(lkprogressShowHudeTab), name: Notification.Name("test"), object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(backToRootRefuse), name: Notification.Name("refusePOP"), object: nil)
    
     NotificationCenter.default.addObserver(self, selector: #selector(jumpOut), name: Notification.Name("giveUpCome"), object: nil)
    
    FirebaseApp.configure()
    
    GMSServices.provideAPIKey("AIzaSyBbTnBn0MHPMnioaL4y68Da3d41JlaSY-g")
    
    Fabric.sharedSDK().debug = true
    
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
    
    if let info = userInfo["aps"] as? [String: Any] {
      guard (info["alert"] as? [String: Any]) != nil else { return }
    }
    completionHandler(.newData)
  }
  
  @objc func perFormPushVC() {
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    UserManager.shared.readData(uid: uid) { result in
      switch result {
      case .success:
        self.gotoDetail()
      case .failure:
        print("error")
      }
    }
  }
  
  @objc func backToRootRefuse () {
    _ = UIStoryboard(name: "Mission", bundle: nil)
    guard let tabBarController = self.window?.rootViewController as? TabBarViewController,
      let _ = tabBarController.selectedViewController as? UINavigationController else {
        
        return
    }
    tabBarController.dismiss(animated: true)
  }
  
  @objc func jumpOut() {
    
    guard let tabBarController = self.window?.rootViewController as? TabBarViewController,
      let navi = tabBarController.selectedViewController as? UINavigationController else {
        return
    }
    
    if navi.visibleViewController is MissionDetailViewController == true {
      
      guard let mapVc  = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab") as? TabBarViewController else { return }
        self.window?.rootViewController = mapVc
    }
  }
  
  func gotoDetail() {
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    let group = DispatchGroup()
    
    group.enter()
    
    var status = 0
    
    UserManager.shared.readData(uid: uid) { result in
      switch result {
      case .success(let userInfo):
        status = userInfo.status
        group.leave()
      case .failure:
        print("error")
      }
    }
    
    group.notify(queue: DispatchQueue.main) {
      
      if status != 0 {
        let storyboard = UIStoryboard(name: "Mission", bundle: nil)
        
        guard let conversationVC = storyboard.instantiateViewController(withIdentifier: "detailViewController") as? MissionDetailViewController,
          let tabBarController = self.window?.rootViewController as? TabBarViewController,
          let navi = tabBarController.selectedViewController as? UINavigationController else {
            
            return
        }
        
        if navi.visibleViewController is MissionDetailViewController == false {
      
          if tabBarController.presentedViewController == nil {
            tabBarController.dismiss(animated: true) {
              //  navi.popViewController(animated: true)
              conversationVC.modalPresentationStyle = .fullScreen
              UserManager.shared.currentUserInfo?.status = 2
              conversationVC.isMissionON = true
              conversationVC.isNavi = true
              tabBarController.present(conversationVC, animated: true, completion: nil)
            }
          } else {
            tabBarController.presentedViewController?.dismiss(animated: true, completion: {
              tabBarController.dismiss(animated: true) {
                UserManager.shared.currentUserInfo = nil
                conversationVC.modalPresentationStyle = .fullScreen
                conversationVC.isNavi = true
                conversationVC.isMissionON = true
                tabBarController.present(conversationVC, animated: true, completion: nil)
              }
            })
          }
        }
      }
    }
  }
  
  @objc func lkprogressShowHudeTab() {
    
    guard let tabBar = self.window?.rootViewController as? TabBarViewController  else { return }
    
    LKProgressHUD.show(controller: tabBar)
    
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
        print(error?.localizedDescription ?? "error")
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
