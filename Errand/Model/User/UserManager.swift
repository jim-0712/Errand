//
//  UserManager.swift
//  Errand
//
//  Created by Jim on 2020/1/15.
//  Copyright © 2020 Jim. All rights reserved.
//
import UIKit
import Foundation
import FBSDKLoginKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class UserManager {
  
  static let shared = UserManager()
  
  let dbF = Firestore.firestore()
  
  var currentUserInfo: AccountInfo?
  
  var checkDetailBtn = false
  
  var isTourist = true
  
  var isPostTask = false
  
  var FBData: FbData?
  
  private init() { }
  
  func registAccount(account: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
    
    Auth.auth().createUser(withEmail: account, password: password) { (_, error) in
      
      if error != nil {
        
        completion(Result.failure(RegiError.registFailed))
      }
      
      completion(.success("ok"))
    }
  }
  
  func createDataBase(classification: String, gender: Int, nickName: String, email: String, photo: String, completion: @escaping (Result<String, Error>) -> Void) {
    
    let report = 0
    
    let blacklist: [String] = []
    
    let friends: [String] = []
    
    let task: [String] = []
    
    let userId = Auth.auth().currentUser?.uid
    
    guard let token = UserDefaults.standard.value(forKey: "fcmToken") as? String,
         let uid = Auth.auth().currentUser?.uid else { return }
    
    let info = AccountInfo(email: email, nickname: nickName, gender: gender, task: task, friends: friends, photo: photo, report: report, blacklist: blacklist, onTask: false, fcmToken: token, status: 0, about: "", taskCount: 0, totalStar: 0.0, uid: uid)
    
    self.dbF.collection(classification).document(email).setData(info.toDict) { error in
      
      if error != nil {
        
        completion(Result.failure(RegiError.registFailed))
        
      } else {
        
        UserDefaults.standard.set(gender, forKey: "gender")
        
        UserDefaults.standard.set(nickName, forKey: "nickname")
        
        UserDefaults.standard.set(email, forKey: "email")
        
        UserDefaults.standard.set(true, forKey: "login")
        
        UserDefaults.standard.set(userId, forKey: "userid")
        
        completion(Result.success("Success"))
        
      }
    }
  }
  
  func fbLogin(controller: UIViewController, completion: @escaping (Result<String, Error>) -> Void) {
    
    let manager = LoginManager()
    
    manager.logIn(permissions: ["email"], from: controller) { (result, _) in
      
      guard let response = result else {
        
        completion(Result.failure(FbMessage.fbloginError))
        
        return }
      
      guard let accessToken = response.token?.tokenString else {
        
        completion(Result.failure(FbMessage.emptyToken))
        
        return
        
      }
      
      completion(Result.success(accessToken))
      
    }
  }
  
  func loadFBProfile(controller: UIViewController, completion: @escaping (Result<String, Error>) -> Void) {
    
    Profile.loadCurrentProfile { [weak self](profile, error) in
      
      if error != nil {
        
        completion(Result.failure(FireBaseMessage.fireBaseLoginError))
        
        return
        
      } else {
        
        guard let profile = profile,
          let profileName = profile.name,
          let profilePicture = profile.imageURL(forMode: .normal, size: CGSize(width: 300, height: 300)) else {
            
            completion(Result.failure(FireBaseMessage.fireBaseLoginError))
            
            return }
        
        self?.FBData = FbData(name: profileName, image: profilePicture)
        
        completion(Result.success("Success"))
        
      }
    }
  }
  
  func loginFireBaseWithFB(accesstoken: String, controller: UIViewController, completion: @escaping (Result<String, Error>) -> Void) {
    
    let credit = FacebookAuthProvider.credential(withAccessToken: accesstoken)
    
    Auth.auth().signIn(with: credit) { (_, error) in
      
      if error != nil {
        
        completion(Result.failure(FireBaseMessage.fireBaseLoginError))
        
      } else {
        
        completion(Result.success("Success"))
      
      }
    }
  }
  
  func updatePhotoData(photo: URL, completion: @escaping (Result<String, Error>) -> Void) {
    
    let transferPhoto = photo.absoluteString
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    dbF.collection("Users").whereField("uid", isEqualTo: uid).getDocuments { (querySnapshot, error) in
      
      if error != nil {
        
        completion(.failure(FireBaseUpdateError.updateError))
        
      }
      
      guard let document = querySnapshot?.documents.first else { return }
      
      document.reference.updateData(["photo": transferPhoto]) { error in
        
        if error != nil {
          
          completion(.failure(FireBaseUpdateError.updateError))
        }
      }
      
      completion(.success("Update Success"))
    }
  }
  
  func updatefcmToken() {
    
    guard let uid = Auth.auth().currentUser?.uid,
      let token = UserDefaults.standard.value(forKey: "fcmToken") as? String else { return }
    
    dbF.collection("Users").whereField("uid", isEqualTo: uid).getDocuments { (querySnapshot, _) in
      
      guard let document = querySnapshot?.documents.first else { return }
      
      document.reference.updateData(["fcmToken": token]) { _ in

    }
  }
}
  
  func goToSign(viewController: UIViewController) {
    
    let alert = UIAlertController(title: "注意", message: "請先登入享有功能", preferredStyle: UIAlertController.Style.alert)
    
    let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (_) in
      
      let mapView = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab")
      
      viewController.view.window?.rootViewController = mapView
    }
    
    let action = UIAlertAction(title: "OK", style: .default) { (_) in
      
      let storyboard = UIStoryboard(name: "Main", bundle: nil)
      
      let goViewController = storyboard.instantiateViewController(withIdentifier: "main")
      
      viewController.view.window?.rootViewController = goViewController
    }
    
    alert.addAction(action)
    
    alert.addAction(cancelAction)
    
    viewController.present(alert, animated: true, completion: nil)
  }
  
  func readData(uid: String, completion: @escaping ((Result<AccountInfo, Error>) -> Void)) {
    
    dbF.collection("Users").whereField("uid", isEqualTo: uid).getDocuments { (querySnapshot, err) in
      if err != nil {
        
        completion(.failure(RegiError.registFailed))
        
      } else {
        guard let quary = querySnapshot else {return }
        
        guard let onTask = quary.documents.first?.data()["onTask"] as? Bool,
          let email = quary.documents.first?.data()["email"] as? String,
          let nickname = quary.documents.first?.data()["nickname"] as? String,
          let gender = quary.documents.first?.data()["gender"] as? Int,
          let task = quary.documents.first?.data()["task"] as? [String],
          let friends = quary.documents.first?.data()["friends"] as? [String],
          let photo = quary.documents.first?.data()["photo"] as? String,
          let blacklist = quary.documents.first?.data()["blacklist"] as? [String],
          let report = quary.documents.first?.data()["report"] as? Int,
          let fcmToken = quary.documents.first?.data()["fcmToken"] as? String,
          let status = quary.documents.first?.data()["status"] as? Int,
          let about = quary.documents.first?.data()["about"] as? String,
          let totalStar = quary.documents.first?.data()["totalStar"] as? Double,
          let taskCount = quary.documents.first?.data()["taskCount"] as? Int,
          let uid = quary.documents.first?.data()["uid"] as? String else { return }
        
        let dataReturn = AccountInfo(email: email, nickname: nickname, gender: gender, task: task, friends: friends, photo: photo, report: report, blacklist: blacklist, onTask: onTask, fcmToken: fcmToken, status: status, about: about, taskCount: taskCount, totalStar: totalStar, uid: uid)
        
        print(dataReturn)
        
        self.currentUserInfo = dataReturn
        
        completion(.success(dataReturn))
      }
    }
  }
                                
  func updateData(status: Int, completion: @escaping (Result<String, Error>) -> Void) {
    
    guard let userInfo = currentUserInfo else { return }
    
    dbF.collection("Users").whereField("uid", isEqualTo: userInfo.uid).getDocuments { (querySnapshot, error) in
      if let querySnapshot = querySnapshot {
        let document = querySnapshot.documents.first
        
        document?.reference.updateData(["status": status ], completion: { (error) in
          
          if error != nil {
            
            completion(.failure(FireBaseUpdateError.updateError))
            
          } else {
            
            completion(.success("Update Success"))
            
          }
        })
      }
    }
  }
  
  func updateUserInfo(completion: @escaping (Result<String,Error>) -> Void){
    guard let data = currentUserInfo else { return }
    dbF.collection("Users").whereField("uid", isEqualTo: data.uid).getDocuments { (querySnapshot, error) in
      if let querySnapshot = querySnapshot {
        let document = querySnapshot.documents.first
        document?.reference.updateData(data.toDict, completion: { error in
          
          if error != nil {
            
            completion(.failure(FireBaseUpdateError.updateError))
          } else {
            self.readData(uid: data.uid) { [weak self] result in
              
              guard let strongSelf = self else { return }
              
              switch result {
                
              case .success(let dataReturn):
                
                strongSelf.currentUserInfo = dataReturn
    
                completion(.success("Success"))
                
              case .failure:
                
                completion(.failure(FireBaseUpdateError.updateError))
              }
            }
            
          }
        })
      }
    }
  }
  
}
