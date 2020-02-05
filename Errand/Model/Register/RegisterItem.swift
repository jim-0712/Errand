//
//  RegisterItem.swift
//  Errand
//
//  Created by Jim on 2020/1/15.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation

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
  
}

struct AccountInfo {
  
  let email: String
  
  let nickname: String
  
  let gender: Int
  
  let task: [String]
  
  let friends: [String]
  
  let photo: String
  
  let report: Int

  let blacklist: [String]
  
  let onTask: Bool
  
  let deviceToken: String
  
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
              
              "deviceToken": deviceToken
          ]
  }
}

struct FbData {
  
  var name: String
  
  var image: URL
}
