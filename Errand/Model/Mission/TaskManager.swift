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
import FirebaseFirestore

class TaskManager {
  
  static let shared = TaskManager()
  
  let dbF = Firestore.firestore()
  
  func createMission(taskPhoto: [URL], time: Int, detail: String, coordinate: CLLocationCoordinate2D, money: Int, classified: Int, completion: @escaping (Result<String, Error>) -> Void) {
  
      guard let email = UserManager.shared.currentUserInfo?.email,
      let nickname = UserManager.shared.currentUserInfo?.nickname,
        let gender = UserManager.shared.currentUserInfo?.gender else {return }
        let lat = coordinate.latitude as Double
        let long = coordinate.longitude as Double

    let info = TaskInfo(email: email, nickname: nickname, gender: gender, taskPhoto: [], time: time, detail: detail, lat: lat, long: long, money: money, classfied: classified)
  
      self.dbF.collection("Tasks").document(email).setData(info.toDict) { error in
  
        if error != nil {
  
          completion(Result.failure(RegiError.registFailed))
  
        } else {
  
          completion(Result.success("Success"))
  
        }
      }
    }
  
}
