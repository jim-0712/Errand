//
//  RegisterItem.swift
//  Errand
//
//  Created by Jim on 2020/1/15.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation
import Firebase

enum FireBaseMessage: Error {
  
  case fireBaseLoginError
  
}

enum FbMessage: Error {
  
  case emptyToken
  
  case fbloginError
}

enum RegistMessage: String {
  
  case emptyAccount = "EmptyAccount"
  
  case emptyPassword = "EmptyPassword"
  
  case emptyConfirm = "EmptyConfirm"
  
  case emptyNickname = "Empty Nickname"
  
  case confirmWrong = "Confirm Wrong"
  
}

enum RegiError: Error {
  
  case illegalAccount
  
  case registFailed
  
  case registSuccess
  
  case notFirstRegi
  
}

struct AccountInfo {
  
  let email: String
  
  var nickname: String
  
  var gender: Int
  
  var task: [String]
  
  var friends: [String]
  
  var photo: String
  
  var report: Int

  var blacklist: [String]
  
  var onTask: Bool
  
  var fcmToken: String
  
  var status: Int
  
  var about: String
  
  var taskCount: Int
  
  var totalStar: Double
  
  var uid: String
  
  var toDict: [String: Any] {
    
    return [  "email": email,
              
              "nickname": nickname,
              
              "gender": gender,
              
              "task": task,
              
              "friends": friends,
              
              "photo": photo,
              
              "blacklist": blacklist,
              
              "report": report,
              
              "onTask": onTask,
              
              "fcmToken": fcmToken,
              
              "status": status,
              
              "about": about,
              
              "taskCount": taskCount,
              
              "totalStar": totalStar,
              
              "uid": uid
          ]
  }
}

struct FbData {
  
  var name: String
  
  var image: URL
}

struct Friends {
  
  var nameREF: DocumentReference
  
  var chatRoomID: String
  
  var toDict: [String: Any] {
    
    return [
      "nameREF": nameREF,
      "chatRoomID": chatRoomID
          ]
  }
}
