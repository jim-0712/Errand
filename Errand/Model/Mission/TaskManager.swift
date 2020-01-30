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
  
  var taskData = [TaskInfo]()
  
  func createMission(taskPhoto: [String], time: Int, detail: String, coordinate: CLLocationCoordinate2D, money: Int, classified: Int, completion: @escaping (Result<String, Error>) -> Void) {
    
    guard let email = UserManager.shared.currentUserInfo?.email,
      let nickname = UserManager.shared.currentUserInfo?.nickname,
      let gender = UserManager.shared.currentUserInfo?.gender else {return }
    let lat = coordinate.latitude as Double
    let long = coordinate.longitude as Double
    
    let info = TaskInfo(email: email, nickname: nickname, gender: gender, taskPhoto: taskPhoto, time: time, detail: detail, lat: lat, long: long, money: money, classfied: classified)
    
    self.dbF.collection("Tasks").document(email).setData(info.toDict) { error in
      
      if error != nil {
        
        completion(Result.failure(RegiError.registFailed))
        
      } else {
        
        completion(Result.success("Success"))
        
      }
    }
  }
  
  func readData(completion: @escaping ((Result<[TaskInfo], Error>) -> Void)) {
    
    dbF.collection("Tasks").getDocuments { [weak self] (querySnapshot, err) in
      
      guard let strongSelf = self else { return }
      
      if err != nil {
        
        completion(.failure(ReadDataError.readDataError))
        
      } else {
        
        guard let quary = querySnapshot else {return }
        
        quary.documents.map { info in
          
            guard let email = info.data()["email"] as? String,
            let nickname = info.data()["nickname"] as? String,
            let gender = info.data()["gender"] as? Int,
            let taskPhoto = info.data()["taskPhoto"] as? [String],
            let time = info.data()["time"] as? Int,
            let detail = info.data()["detail"] as? String,
            let lat = info.data()["lat"] as? Double,
            let long = info.data()["long"] as? Double,
            let money = info.data()["money"] as? Int,
            let classfied = info.data()["classfied"] as? Int else { return }
          
          let dataReturn = TaskInfo(email: email, nickname: nickname, gender: gender, taskPhoto: taskPhoto, time: time, detail: detail, lat: lat, long: long, money: money, classfied: classfied)
          
          strongSelf.taskData.append(dataReturn)
        }

        completion(.success(strongSelf.taskData))
      }
    }
  }
  
}
