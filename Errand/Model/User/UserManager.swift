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

class FirebaseManager {
  
  let dbf: Firestore
  
  init(dbf: Firestore = Firestore.firestore()) {
    self.dbf = dbf
  }
  
  func fetchData(uid: String, completion: @escaping (Result<AccountInfo, Error>) -> Void) {
    
    let ref = FirebaseRequest.fetchUserInfo(path: "Users", uid: uid)
    
    ref.makeQuery(dbF: dbf).getDocuments { (querySnapshot, err) in
      if err != nil {
        
        completion(.failure(FireBaseDownloadError.downloadError))
        
      } else {
        guard let query = querySnapshot else {return }
        
        if query.documents.isEmpty {
          
          completion(.failure(FireBaseDownloadError.downloadError))
          
        } else {
          
          UserManager.shared.dataParser(query: query) { result in
            switch result {
            case .success(let account):
              completion(.success(account))
            case .failure:
              completion(.failure(FireBaseDownloadError.downloadError))
            }
          }
        }
      }
    }
  }
  
  func fetchDataWithQuery(uid: String, completion: @escaping (Result<QuerySnapshot, Error>) -> Void) {
    
    let ref = FirebaseRequest.fetchUserInfo(path: "Users", uid: uid)
    
    ref.makeQuery(dbF: dbf).getDocuments { (querySnapshot, err) in
      if err != nil {
        
        completion(.failure(RegiError.registFailed))
        
      } else {
        guard let query = querySnapshot else {return }
        
        if query.documents.isEmpty {
          
          completion(.failure(RegiError.notFirstRegi))
          
        } else {
          
          completion(.success(query))
          
        }
      }
    }
  }
  
  func addFriend(owneruid: String, takerUid: String, data: [String: Any], completion: @escaping ((Result<String, Error>) -> Void)) {
    
    let ref = FirebaseRequest.getFriends(ownerUid: owneruid, takerUid: takerUid)
    
    ref.getFriendQuery(dbF: dbf).setData(data) { error in
      
      if error == nil {
        completion(.success("success"))
      }
    }
  }
  
  func updateDate(document: QueryDocumentSnapshot, data: [String: Any], completion: @escaping ((Result<String, Error>) -> Void)) {
    
    document.reference.updateData(data) { error in
      
      if error != nil {
        
        completion(.failure(FireBaseUpdateError.updateError))
      }
      completion(.success("Success"))
    }
  }
}

class UserManager: NSObject {
  
  @objc static let shared = UserManager()
  
  let firebaseManager: FirebaseManager
  
  let dbF: Firestore = Firestore.firestore()
  
  init(firebaseManager: FirebaseManager = FirebaseManager()) {
    self.firebaseManager = firebaseManager
    super.init()
  }
  
  var currentUserInfo: AccountInfo?
  
  @objc dynamic var isChange = false
  
  var statusJudge = 0
  
  var isRequester = false
  
  var requesterInfo: AccountInfo?
  
  var isEditNameEmpty = false
  
  var checkDetailBtn = false
  
  var isHideNavi = false
  
  var isTourist = true
  
  var isPostTask = false
  
  var FBData: FbData?
  
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
  
  func updatePersonPhotoURL(photo: URL, completion: @escaping (Result<String, Error>) -> Void) {
    
    let transferPhoto = photo.absoluteString
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    firebaseManager.fetchDataWithQuery(uid: uid) { [weak self] result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success(let query):
        
         guard let document = query.documents.first else { return }
         strongSelf.firebaseManager.updateDate(document: document, data: ["photo": transferPhoto]) { result in
          switch result {
          case .success:
            completion(.success("upload Success"))
          case .failure(let error):
            completion(.failure(error))
          }
        }
        
      case .failure:
        
        completion(.failure(FireBaseUpdateError.updateError))
      }
    }
  }
  
  func updatefcmToken() {
    
    guard let uid = Auth.auth().currentUser?.uid,
         let token = UserDefaults.standard.value(forKey: "fcmToken") as? String else { return }
    
    firebaseManager.fetchDataWithQuery(uid: uid) { [weak self] result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success(let query):
        
         guard let document = query.documents.first else { return }
         strongSelf.firebaseManager.updateDate(document: document, data: ["fcmToken": token]) { result in
          switch result {
          case .success:
            print("fcm update")
          case .failure(let error):
            print(error.localizedDescription)
          }
        }
        
      case .failure:
        print("error")
      }
    }
  }
  
  func goSignInPage(viewController: UIViewController) {
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
  
  func updateOppoInfo(userInfo: AccountInfo, completion: @escaping (Result<String, Error>) -> Void) {
    
    firebaseManager.fetchDataWithQuery(uid: userInfo.uid) { [weak self] result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success(let query):
        
         guard let document = query.documents.first else { return }
         strongSelf.firebaseManager.updateDate(document: document, data: userInfo.toDict) { result in
          switch result {
          case .success:
            completion(.success("upload Success"))
          case .failure(let error):
            completion(.failure(error))
          }
        }
        
      case .failure:
        
        completion(.failure(FireBaseUpdateError.updateError))
      }
    }
  }
  
  func readUserInfo(uid: String, isSelf: Bool, completion: @escaping ((Result<AccountInfo, Error>) -> Void)) {
    
    firebaseManager.fetchData(uid: uid) { result in
      switch result {
      case .success(let account):
        
        if isSelf {
          self.currentUserInfo = account
        }
        
        completion(.success(account))
  
      case.failure(let error):
        
        completion(.failure(FireBaseDownloadError.downloadError))
        print(error.localizedDescription)
      }
    }
  }
  
  func dataParser(query: QuerySnapshot, completion: @escaping (Result<AccountInfo, Error>) -> Void) {

    guard let onTask = query.documents.first?.data()["onTask"] as? Bool,
      let email = query.documents.first?.data()["email"] as? String,
      let nickname = query.documents.first?.data()["nickname"] as? String,
      let noJudgeCount = query.documents.first?.data()["noJudgeCount"] as? Int,
      let task = query.documents.first?.data()["task"] as? [String],
      let minusStar = query.documents.first?.data()["minusStar"] as? Double,
      let photo = query.documents.first?.data()["photo"] as? String,
      let blacklist = query.documents.first?.data()["blacklist"] as? [String],
      let report = query.documents.first?.data()["report"] as? Int,
      let fcmToken = query.documents.first?.data()["fcmToken"] as? String,
      let status = query.documents.first?.data()["status"] as? Int,
      let about = query.documents.first?.data()["about"] as? String,
      let totalStar = query.documents.first?.data()["totalStar"] as? Double,
      let taskCount = query.documents.first?.data()["taskCount"] as? Int,
      let uid = query.documents.first?.data()["uid"] as? String,
      let oppoBlacklist = query.documents.first?.data()["oppoBlacklist"] as? [String] else { return }

    let dataReturn = AccountInfo(email: email, nickname: nickname, noJudgeCount: noJudgeCount, task: task, minusStar: minusStar, photo: photo, report: report, blacklist: blacklist, oppoBlacklist: oppoBlacklist, onTask: onTask, fcmToken: fcmToken, status: status, about: about, taskCount: taskCount, totalStar: totalStar, uid: uid)

    completion(.success(dataReturn))
  }
  
  func updateStatus(uid: String, status: Int, completion: @escaping (Result<String, Error>) -> Void) {
    
    firebaseManager.fetchDataWithQuery(uid: uid) { [weak self] result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success(let query):
        
         guard let document = query.documents.first else { return }
         strongSelf.firebaseManager.updateDate(document: document, data: ["status": status]) { result in
          switch result {
          case .success:
            print("status update")
            completion(.success("status update"))
          case .failure(let error):
            print(error.localizedDescription)
          }
        }
        
      case .failure:
        print("error")
      }
    }
  }
  
  func updateOppoBlackList(uid: String, isSelf: Bool, completion: @escaping (Result<String, Error>) -> Void) {
    
    UserManager.shared.readUserInfo(uid: uid, isSelf: isSelf) { result in
      switch result {
      case .success(var reverseInfo):
        
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
          UserManager.shared.updateOppoInfo(userInfo: reverseInfo) { result in
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
    
    firebaseManager.addFriend(owneruid: ownerUid, takerUid: takerUid, data: takerFriend.toDict) { result in
      switch result {
      case .success:
        group.leave()
      case .failure:
        print("add friend fail")
      }
    }
    
    firebaseManager.addFriend(owneruid: takerUid, takerUid: ownerUid, data: ownerFriend.toDict) { result in
      switch result {
      case .success:
        group.leave()
      case .failure:
        print("add friend fail")
      }
    }
    
    group.notify(queue: DispatchQueue.main) {
      completion(.success("Success"))
    }
  }
  
  func fetchFriends(completion: @escaping (Result<[Friends], Error>) -> Void) {
    
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
  
  func fetchPersonPhoto(nameRef: DocumentReference, completion: @escaping (Result<AccountInfo, Error>) -> Void) {
    nameRef.getDocument { (query, error) in
      
      if error != nil {
        completion(.failure(FireBaseDownloadError.downloadError))
      }
      
      guard let data = query?.data() else { return }
            
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
  
  func checkFriends(nameRef: DocumentReference, completion: @escaping ((Result<Bool, Error>)) -> Void) {
    
    UserManager.shared.fetchFriends { result in
      switch result {
      case .success(let friends):
        
        var isFriends = false
        for friend in friends where friend.nameREF == nameRef {
            isFriends = true
          break
        }
        completion(.success(isFriends))
        
      case .failure:
        print("friendsError")
      }
    }
  }
}
