//
//  DataBaseManagerManager.swift
//  Errand
//
//  Created by Jim on 2020/2/12.
//  Copyright © 2020 Jim. All rights reserved.
//

import Firebase
import FirebaseAuth
import FirebaseFirestore

class DataBaseManager {

 static let shared = DataBaseManager()
 
 let dbF = Firestore.firestore()
  
  func createDataBase(classification: String, nickName: String, email: String, photo: String, completion: @escaping (Result<String, Error>) -> Void) {
    
    let report = 0
    
    let blacklist: [String] = []
    
    let task: [String] = []
    
    guard let token = UserDefaults.standard.value(forKey: "fcmToken") as? String,
         let uid = Auth.auth().currentUser?.uid  else {
          
          return
    }
    
    let info = AccountInfo(email: email, nickname: nickName, noJudgeCount: 0, task: task, minusStar: 0.0, photo: photo, report: report, blacklist: blacklist, onTask: false, fcmToken: token, status: 0, about: "", taskCount: 0, totalStar: 0.0, uid: uid)
    
    self.dbF.collection(classification).document(uid).setData(info.toDict) { error in
      
      if error != nil {
        
        completion(Result.failure(RegiError.registFailed))
        
      } else {
        
        UserDefaults.standard.set(email, forKey: "email")
        
        UserDefaults.standard.set(true, forKey: "login")
        
        completion(Result.success("Success"))
        
      }
    }
  }

}
