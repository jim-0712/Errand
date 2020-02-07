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
  
  var fileType: [Int]
  
  var personPhoto: String
  
  var requester: [String]
  
  var fcmToken: String
  
  var missionTaker: String
  
  var refuse: [String]
  
  var uid: String
  
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
              
              "uid": uid
          ]
  }
}

struct TaskGroup {

    let color: UIColor

    let title: String
  
    let image: String
}
