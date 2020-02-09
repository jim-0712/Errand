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
    
    FirebaseApp.configure()
    
    //    GMSServices.provideAPIKey("AIzaSyB_voEc15Sn0T_O9C2O-6dWz7c_ju42jXs")
    
    GMSServices.provideAPIKey("AIzaSyBbTnBn0MHPMnioaL4y68Da3d41JlaSY-g")
    
    GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
    
    GIDSignIn.sharedInstance().delegate = self
    
    UNUserNotificationCenter.current().delegate = self
    
    UIApplication.shared.registerForRemoteNotifications()
    
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
//    print("Recived: \(userInfo)")
//    //Parsing userinfo:
////    var temp: NSDictionary = userInfo as NSDictionary
//    if let info = userInfo["aps"] as? Dictionary<String, AnyObject> {
//              guard let alertMsg = info["alert"] as? String else { return }
//              
//              let controller = UIAlertController(title: "怎麼可以忘了!", message: alertMsg, preferredStyle: .alert)
//              let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
//              controller.addAction(okAction)
//
//             }
  }
  
  lazy var persistentContainer: NSPersistentContainer = {
    /*
     The persistent container for the application. This implementation
     creates and returns a container, having loaded the store for the
     application to it. This property is optional since there are legitimate
     error conditions that could cause the creation of the store to fail.
     */
    let container = NSPersistentContainer(name: "Errand")
    container.loadPersistentStores(completionHandler: { (_, error) in
      if let error = error as NSError? {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        
        /*
         Typical reasons for an error here include:
         * The parent directory does not exist, cannot be created, or disallows writing.
         * The persistent store is not accessible, due to permissions or data protection when the device is locked.
         * The device is out of space.
         * The store could not be migrated to the current model version.
         Check the error message to determine what the actual problem was.
         */
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
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }
  
}
