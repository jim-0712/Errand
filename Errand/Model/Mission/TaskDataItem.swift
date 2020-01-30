//
//  TaskDataItem.swift
//  Errand
//
//  Created by Jim on 2020/1/24.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation
import CoreLocation

enum ReadDataError: Error {
  
  case readDataError
}

struct TaskInfo {
  
  let email: String
  
  let nickname: String
  
  let gender: Int
  
  let taskPhoto: [String]
  
  let time: Int
  
  let detail: String
  
  let lat: Double
  
  let long: Double
  
  let money: Int
  
  let classfied: Int
  
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
              
              "long": long
    
          ]
  }
}
