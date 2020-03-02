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
  
  var statusJudge = 0
  
  var isRequester = false
  
  var requesterInfo: AccountInfo?
  
  var isEditNameEmpty = false
  
  var checkDetailBtn = false
  
  var isHideNavi = false
  
  var isTourist = true
  
  var isPostTask = false
  
  var FBData: FbData?
  
  private init() { }
  
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
  
  func goToSignOrStay(viewController: UIViewController) {
    let alert = UIAlertController(title: "注意", message: "請先登入享有功能", preferredStyle: UIAlertController.Style.alert)
       
    let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
       
       let action = UIAlertAction(title: "OK", style: .default) { (_) in
         
         let storyboard = UIStoryboard(name: "Main", bundle: nil)
         
         let goViewController = storyboard.instantiateViewController(withIdentifier: "main")
         
         viewController.view.window?.rootViewController = goViewController
       }
       
       alert.addAction(action)
       
       alert.addAction(cancelAction)
       
       viewController.present(alert, animated: true, completion: nil)
  }
  
  func readBlackData(uid: String, completion: @escaping ((Result<AccountInfo, Error>) -> Void)) {
    
    dbF.collection("Users").whereField("uid", isEqualTo: uid).getDocuments { (querySnapshot, err) in
      if err != nil {
        
        completion(.failure(RegiError.registFailed))
        
      } else {
        guard let quary = querySnapshot else {return }
        
        if quary.documents.count == 0 {
          
          completion(.failure(RegiError.notFirstRegi))
          
        } else {
          
          self.dataParser(quary: quary) { result in
            
            switch result {
            case .success(let accountInfo):
              
              print(accountInfo)
              
              completion(.success(accountInfo))
            case .failure:
              print("error")
            }
          }
          
        }
      }
    }
  }
  
  
  func updateOppoInfo(userInfo: AccountInfo, completion: @escaping (Result<String, Error>) -> Void) {
    dbF.collection("Users").whereField("uid", isEqualTo: userInfo.uid).getDocuments { (querySnapshot, error) in
      if let querySnapshot = querySnapshot {
        let document = querySnapshot.documents.first
        document?.reference.updateData(userInfo.toDict, completion: { error in
          
          if error != nil {
            
            completion(.failure(FireBaseUpdateError.updateError))
          } else {
            
            completion(.success("good"))
  
          }
        })
      }
    }
  }
  
  func readData(uid: String, completion: @escaping ((Result<AccountInfo, Error>) -> Void)) {
    
    dbF.collection("Users").whereField("uid", isEqualTo: uid).getDocuments { (querySnapshot, err) in
      if err != nil {
        
        completion(.failure(RegiError.registFailed))
        
      } else {
        guard let quary = querySnapshot else {return }
        
        if quary.documents.count == 0 {
          
          completion(.failure(RegiError.notFirstRegi))
          
        } else {
          
          self.dataParser(quary: quary) { result in
            
            switch result {
            case .success(let accountInfo):
              self.currentUserInfo = accountInfo
              print(accountInfo)
              
              completion(.success(accountInfo))
            case .failure:
              print("error")
            }
          }
          
        }
      }
    }
  }
  
  func dataParser(quary: QuerySnapshot, completion: @escaping (Result<AccountInfo, Error>) -> Void) {
    
    guard let onTask = quary.documents.first?.data()["onTask"] as? Bool,
      let email = quary.documents.first?.data()["email"] as? String,
      let nickname = quary.documents.first?.data()["nickname"] as? String,
      let noJudgeCount = quary.documents.first?.data()["noJudgeCount"] as? Int,
      let task = quary.documents.first?.data()["task"] as? [String],
      let minusStar = quary.documents.first?.data()["minusStar"] as? Double,
      let photo = quary.documents.first?.data()["photo"] as? String,
      let blacklist = quary.documents.first?.data()["blacklist"] as? [String],
      let report = quary.documents.first?.data()["report"] as? Int,
      let fcmToken = quary.documents.first?.data()["fcmToken"] as? String,
      let status = quary.documents.first?.data()["status"] as? Int,
      let about = quary.documents.first?.data()["about"] as? String,
      let totalStar = quary.documents.first?.data()["totalStar"] as? Double,
      let taskCount = quary.documents.first?.data()["taskCount"] as? Int,
      let uid = quary.documents.first?.data()["uid"] as? String,
      let oppoBlacklist = quary.documents.first?.data()["oppoBlacklist"] as? [String] else { return }
    
    let dataReturn = AccountInfo(email: email, nickname: nickname, noJudgeCount: noJudgeCount, task: task, minusStar: minusStar, photo: photo, report: report, blacklist: blacklist, oppoBlacklist: oppoBlacklist, onTask: onTask, fcmToken: fcmToken, status: status, about: about, taskCount: taskCount, totalStar: totalStar, uid: uid)
    
      completion(.success(dataReturn))
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
  
  func updateStatus(uid: String, status: Int, completion: @escaping (Result<String, Error>) -> Void) {
    
    dbF.collection("Users").whereField("uid", isEqualTo: uid).getDocuments { (querySnapshot, error) in
      if let querySnapshot = querySnapshot {
        let document = querySnapshot.documents.first
        
        document?.reference.updateData(["status": status], completion: { (error) in
          
          if error != nil {
            
            completion(.failure(FireBaseUpdateError.updateError))
            
          } else {
            
            completion(.success("Update Success"))
            
          }
        })
      }
    }
  }
  
  func updateUserInfo(completion: @escaping (Result<AccountInfo, Error>) -> Void) {
    guard let data = currentUserInfo else { return }
    dbF.collection("Users").whereField("uid", isEqualTo: data.uid).getDocuments { (querySnapshot, error) in
      if let querySnapshot = querySnapshot {
        let document = querySnapshot.documents.first
        document?.reference.updateData(data.toDict, completion: { error in
          
          if error != nil {
            
            completion(.failure(FireBaseUpdateError.updateError))
          } else {
            
            completion(.success(data))
  
          }
        })
      }
    }
  }
  
  func updateReverseUid(uid: String, completion: @escaping (Result<String, Error>) -> Void) {
      
    UserManager.shared.readData(uid: uid) { result in
      switch result {
      case .success(var  reverseInfo):
        
        var isBlack = false
        guard let currentuid = Auth.auth().currentUser?.uid else { return }
        
        for info in reverseInfo.oppoBlacklist where info == currentuid {
            isBlack = true
            break
        }
        
        if isBlack {
          
          completion(.success("Good"))
  
        } else {
          
          reverseInfo.oppoBlacklist.append(currentuid)
          self.currentUserInfo = reverseInfo
          
            UserManager.shared.updateUserInfo { result in
              switch result {
              case .success:
                completion(.success("Success"))
              case .failure:
                completion(.failure(FireBaseUpdateError.updateError))
              }
            }
        }
      case .failure:
        completion(.failure(FireBaseUpdateError.updateError))
      }
    }
  }
  
  func updatefreinds(ownerUid: String, takerUid: String, chatRoomID: String, completion: @escaping (Result<String, Error>) -> Void) {
    
    let ownerRdf = dbF.collection("Users").document(ownerUid)
    let takerRef = dbF.collection("Users").document(takerUid)
    let ownerFriend = Friends(nameREF: takerRef, chatRoomID: chatRoomID)
    let takerFriend = Friends(nameREF: ownerRdf, chatRoomID: chatRoomID)
    
    let group = DispatchGroup()
    group.enter()
    group.enter()
    
    dbF.collection("Users").document(ownerUid).collection("Friends").document(takerUid).setData(ownerFriend.toDict) { error in
      
      if error != nil {
        
        completion(.failure(FireBaseUpdateError.updateError))
      } else {
        
        group.leave()
      }
    }
    
    dbF.collection("Users").document(takerUid).collection("Friends").document(ownerUid).setData(takerFriend.toDict) { error in
      
      if error != nil {
        
        completion(.failure(FireBaseUpdateError.updateError))
      } else {
        
        group.leave()
      }
    }
    
    group.notify(queue: DispatchQueue.main) {
      completion(.success("Success"))
    }
  }
  
  func getFriends(completion: @escaping (Result<[Friends], Error>) -> Void) {
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    dbF.collection("Users").document(uid).collection("Friends").getDocuments { quaryData, error in
      
      if error != nil {
        completion(.failure(FireBaseDownloadError.downloadError))
      }
      
      guard let quary = quaryData else {return }
      
      var friendsList: [Friends] = []
      
      for count in 0 ..< quary.documents.count {
        
        guard let chatroomID = quary.documents[count].data()["chatRoomID"] as? String,
          let nameRef = quary.documents[count].data()["nameREF"] as? DocumentReference else { return }
        
        let dataReturn = Friends(nameREF: nameRef, chatRoomID: chatroomID)
        
        friendsList.append(dataReturn)
      }
      
      completion(.success(friendsList))
    }
  }
  
  func getPhoto(nameRef: DocumentReference, completion: @escaping (Result<AccountInfo, Error>) -> Void) {
    nameRef.getDocument { (quary, error) in
      
      if error != nil {
        completion(.failure(FireBaseDownloadError.downloadError))
      }
      
      guard let data = quary?.data() else { return }
      
      guard let onTask = data["onTask"] as? Bool,
      let email = data["email"] as? String,
      let nickname = data["nickname"] as? String,
      let noJudgeCount = data["noJudgeCount"] as? Int,
      let task = data["task"] as? [String],
      let minusStar = data["minusStar"] as? Double,
      let photo = data["photo"] as? String,
      let blacklist = data["blacklist"] as? [String],
      let report = data["report"] as? Int,
      let fcmToken = data["fcmToken"] as? String,
      let status = data["status"] as? Int,
      let about = data["about"] as? String,
      let totalStar = data["totalStar"] as? Double,
      let taskCount = data["taskCount"] as? Int,
      let uid = data["uid"] as? String,
      let oppoBlacklist = data["oppoBlacklist"] as? [String] else { return }
      
      let dataReturn = AccountInfo(email: email, nickname: nickname, noJudgeCount: noJudgeCount, task: task, minusStar: minusStar, photo: photo, report: report, blacklist: blacklist, oppoBlacklist: oppoBlacklist, onTask: onTask, fcmToken: fcmToken, status: status, about: about, taskCount: taskCount, totalStar: totalStar, uid: uid)
      
      completion(.success(dataReturn))
    }
  }
  
  func preventTap(viewController: UIViewController) {
    guard let tabVC = viewController.view.window?.rootViewController as? TabBarViewController else { return }
    LKProgressHUD.show(controller: tabVC)
  }
  
//  func updateHistoryMission(owner: String, classified: Int, judge: String, star: Double, completion: @escaping (Result<String, Error>) -> Void) {
//    
//    guard let uid = Auth.auth().currentUser?.uid else { return }
//    
//    let info = JudgeInfo(owner: owner, judge: judge, star: star, classified: classified)
//    
//    dbF.collection("Users").document(uid).collection("History").addDocument(data: info.toDict) { _  in
//      
//      completion(Result.success("Success"))
//    }
//  }
}
