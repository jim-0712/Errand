//
//  TaskDataItem.swift
//  Errand
//
//  Created by Jim on 2020/1/24.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation
import CoreLocation

struct TaskInfo {
  
  let email: String
  
  let nickname: String
  
  let gender: Int
  
  let taskPhoto: [String]
  
  let time: Int
  
  let detail: String
  
  let coordinate: CLLocationCoordinate2D
  
  var toDict: [String: Any] {
    
    return [   "email": email,
              
              "nickname": nickname,
              
              "gender": gender,
              
              "taskPhoto": taskPhoto,
              
              "time": time,
              
              "detail": detail,
              
              "coordinate": coordinate
    
          ]
  }
}
