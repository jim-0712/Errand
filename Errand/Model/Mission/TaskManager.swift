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
  
  func createMission(taskPhoto: [String], coordinate: CLLocationCoordinate2D, taskData: [Int], detail: String, fileType: [Int], completion: @escaping (Result<String, Error>) -> Void) {
    
    guard let email = UserManager.shared.currentUserInfo?.email,
      let nickname = UserManager.shared.currentUserInfo?.nickname,
      let gender = UserManager.shared.currentUserInfo?.gender,
      let photo = Auth.auth().currentUser?.photoURL else {return }
      let lat = coordinate.latitude as Double
      let long = coordinate.longitude as Double
      let personPhoto = "\(photo)"
    
    let info = TaskInfo(email: email, nickname: nickname, gender: gender, taskPhoto: taskPhoto, time: taskData[0], detail: detail, lat: lat, long: long, money: taskData[1], classfied: taskData[2], status: taskData[3], fileType: fileType, personPhoto: personPhoto)
    
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
            let status = info.data()["status"] as? Int,
            let fileType = info.data()["fileType"] as? [Int],
            let classfied = info.data()["classfied"] as? Int,
            let personPhoto = info.data()["personPhoto"] as? String else { return }
          
          let dataReturn = TaskInfo(email: email, nickname: nickname, gender: gender, taskPhoto: taskPhoto, time: time, detail: detail, lat: lat, long: long, money: money, classfied: classfied, status: status, fileType: fileType, personPhoto: personPhoto)
          
          strongSelf.taskData.append(dataReturn)
        }

        completion(.success(strongSelf.taskData))
      }
    }
  }
  
}
