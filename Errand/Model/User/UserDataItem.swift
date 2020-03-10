//
//  UserDataItem.swift
//  Errand
//
//  Created by Jim on 2020/1/21.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation
import Firebase

protocol FireBaseParser {
  
  var path: String { get }
  
  var whereUid: String { get }
  
  var takerUid: String { get }
  
  var ownerUid: String { get }
}

extension FireBaseParser {

  func getFriendQuery(dbF: Firestore) -> DocumentReference {

    return dbF.collection(path).document(takerUid).collection("Friends").document(ownerUid)
  }
  
  func makeQuery(dbF: Firestore) -> Query {
    
    return dbF.collection(path).whereField("uid", isEqualTo: whereUid)
  }
}

enum FirebaseRequest: FireBaseParser {
    
  case fetchUserInfo(path: String, uid: String)
  
  case getFriends(ownerUid: String, takerUid: String)
  
  var path: String {
    switch self {
      
    case .fetchUserInfo(let path, _):
      
      return path
      
    case .getFriends:
      
      return "Users"
    }
  }
  
  var takerUid: String {
    switch self {
      
    case .fetchUserInfo:
      
      return ""
      
    case .getFriends(_, let takerUid):
      
      return takerUid
    }
  }
  
  var ownerUid: String {
    switch self {
    case .fetchUserInfo:
      
      return ""
      
    case .getFriends(let ownerUid, _):
      
      return ownerUid
    }
  }
  
  var whereUid: String {
    switch self {
    case .fetchUserInfo(_, let uid):
      
      return uid
      
    case .getFriends:
      
      return ""
    }
  }
}

enum FireBaseUpdateError: Error {
  
  case updateError
}

enum FireBaseDownloadError: Error {
  
  case downloadError
}

enum MissionError: Error {
  
  case completeMission
}

enum CellType {
  case detail
  case rate
  case about
  case logout
  case miniPhoto
  case startMission
  case normal
  case purpose
  case blacklist
}

struct CellContent {
  var type: CellType
  var title: String
}
