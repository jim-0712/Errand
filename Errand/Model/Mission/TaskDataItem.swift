//
//  TaskDataItem.swift
//  Errand
//
//  Created by Jim on 2020/1/24.
//  Copyright © 2020 Jim. All rights reserved.
//
import UIKit
import Foundation
import CoreLocation

enum ReadDataError: Error {
  
  case readDataError
}

struct JudgeInfo {
  
  var owner: String
  
  var judge: String
  
  var star: Double
  
  var classified: Int
  
  var date: Int
  
  var toDict: [String: Any] {
    
    return [
      "owner": owner,
      
      "judge": judge,
      
      "star": star,
      
      "classified": classified,
      
      "date": date
    ]
  }
}

struct TaskInfo {
  
  var email: String
  
  var nickname: String
  
  var gender: Int
  
  var taskPhoto: [String]
  
  var time: Int
  
  var detail: String
  
  var lat: Double
  
  var long: Double
  
  var money: Int
  
  var classfied: Int
  
  var status: Int
  
  var ownerOK: Bool
  
  var takerOK: Bool
  
  var ownerAskFriend: Bool
  
  var takerAskFriend: Bool
  
  var fileType: [Int]
  
  var personPhoto: String
  
  var requester: [String]
  
  var fcmToken: String
  
  var missionTaker: String
  
  var refuse: [String]
  
  var uid: String
  
  var chatRoom: String
  
  var isFrirndsNow: Bool
  
  var isComplete: Bool
  
  var star: Double
  
  var ownerJudge: Bool
  
  var takerJudge: Bool

  var toDict: [String: Any] {
    
    return [   "email": email,
               
               "nickname": nickname,
               
               "gender": gender,
               
               "taskPhoto": taskPhoto,
               
               "time": time,
               
               "detail": detail,
               
               "money": money,
               
               "classfied": classfied,
               
               "lat": lat,
               
               "long": long,
               
               "status": status,
               
               "fileType": fileType,
               
               "personPhoto": personPhoto,
               
               "requester": requester,
               
               "fcmToken": fcmToken,
               
               "missionTaker": missionTaker,
               
               "refuse": refuse,
               
               "uid": uid,
               
               "chatRoom": chatRoom,
               
               "isComplete": isComplete,
               
               "ownerOK": ownerOK,
               
               "takerOK": takerOK,
               
               "star": star,
               
               "ownerAskFriend": ownerAskFriend,
               
               "takerAskFriend": takerAskFriend,
               
               "isFrirndsNow": isFrirndsNow,
               
               "ownerJudge": ownerJudge,
               
               "takerJudge": takerJudge
    ]
  }
}

struct TaskGroup {
  
  let color: UIColor
  
  let title: String
  
  let image: String
}
