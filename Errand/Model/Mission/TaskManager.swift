//
//  TaskManager.swift
//  Errand
//
//  Created by Jim on 2020/1/24.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation
import Firebase
import CoreLocation


class TaskManager {
  
  static let shared = TaskManager()
  
  let dbF = Firestore.firestore()
  
  func createMission(taskPhoto: [String], time: Int, detail: String, coordinate: CLLocationCoordinate2D, completion: @escaping (Result<String, Error>) -> Void) {
  
      guard let email = UserManager.shared.currentUserInfo?.email,
      let nickname = UserManager.shared.currentUserInfo?.nickname,
        let gender = UserManager.shared.currentUserInfo?.gender else {return }

  
      let info = TaskInfo(email: email, nickname: nickname, gender: gender, taskPhoto: [], time: time, detail: detail, coordinate: coordinate)
  
      self.dbF.collection("Tasks").document(email).setData(info.toDict) { error in
  
        if error != nil {
  
          completion(Result.failure(RegiError.registFailed))
  
        } else {
  
          completion(Result.success("Success"))
  
        }
      }
    }
  
}
