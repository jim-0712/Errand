//
//  TaskManager.swift
//  Errand
//
//  Created by Jim on 2020/1/24.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import CoreLocation
import FirebaseFirestore

class TaskManager {
  
  static let shared = TaskManager()
  
  let dbF = Firestore.firestore()
  
  let database = Database.database().reference()
  
  var taskData = [TaskInfo]()
  
  let taskClassified = [
    TaskGroup(color: .black, title: "所有任務", image: "none"),
    TaskGroup(color: .red, title: "搬運物品", image: "trucks"),
    TaskGroup(color: .yellow, title: "清潔打掃", image: "broom"),
    TaskGroup(color: .blue, title: "水電維修", image: "fix"),
    TaskGroup(color: .lightGray, title: "科技維修", image: "tools"),
    TaskGroup(color: .pink, title: "驅趕害蟲", image: "bug"),
    TaskGroup(color: .lightPurple, title: "一日陪伴", image: "develop"),
    TaskGroup(color: .orange, title: "交通接送", image: "drive"),
    TaskGroup(color: .green, title: "其他種類", image: "questions")
  ]
  
  func createMission(taskPhoto: [String], coordinate: CLLocationCoordinate2D, taskData: [Int], detail: String, fileType: [Int], completion: @escaping (Result<String, Error>) -> Void) {
    
    guard let email = UserManager.shared.currentUserInfo?.email,
      let nickname = UserManager.shared.currentUserInfo?.nickname,
      let gender = UserManager.shared.currentUserInfo?.gender,
      let photo = UserManager.shared.currentUserInfo?.photo,
      let fcmToken = UserManager.shared.currentUserInfo?.fcmToken,
      let uid = UserManager.shared.currentUserInfo?.uid else {return }
      let lat = coordinate.latitude as Double
      let long = coordinate.longitude as Double
      let personPhoto = "\(photo)"
    
    let info = TaskInfo(email: email, nickname: nickname, gender: gender, taskPhoto: taskPhoto, time: taskData[0], detail: detail, lat: lat, long: long, money: taskData[1], classfied: taskData[2], status: taskData[3], fileType: fileType, personPhoto: personPhoto, requester: [], fcmToken: fcmToken, missionTaker: "", refuse: [], uid: uid, chatRoom: "")
    
    self.dbF.collection("Tasks").document(uid).setData(info.toDict) { error in
      
      if error != nil {
        
        completion(Result.failure(RegiError.registFailed))
        
      } else {
        
        completion(Result.success("Success"))
        
      }
    }
  }
  
  func readData(completion: @escaping ((Result<[TaskInfo], Error>) -> Void)) {
    
    self.taskData = []
    
    dbF.collection("Tasks").getDocuments { [weak self] (querySnapshot, err) in
      
      guard let strongSelf = self else { return }
      
      if err != nil {
        
        completion(.failure(ReadDataError.readDataError))
        
      } else {
        
        guard let quary = querySnapshot else {return }
        
        strongSelf.reFactData(quary: quary)
        
        completion(.success(strongSelf.taskData))
      }
    }
  }
  
  func readSpecificData(parameter: String, parameterDataInt: Int, completion: @escaping ((Result<[TaskInfo], Error>) -> Void)) {
    
    self.taskData = []
    
    dbF.collection("Tasks").whereField(parameter, isEqualTo: parameterDataInt).getDocuments { [weak self] (querySnapshot, err) in
      
      guard let strongSelf = self else { return }
      
      if err != nil {
        
        completion(.failure(ReadDataError.readDataError))
        
      } else {
        
        guard let quary = querySnapshot else {return }
        
        strongSelf.reFactDataSpec(quary: quary)
        
        completion(.success(strongSelf.taskData))
      }
    }
  }
  
  func readSpecificData(parameter: String, parameterString: String, completion: @escaping ((Result<[TaskInfo], Error>) -> Void)) {
    
    self.taskData = []
    
    dbF.collection("Tasks").whereField(parameter, isEqualTo: parameterString).getDocuments { [weak self] (querySnapshot, err) in
      
      guard let strongSelf = self else { return }
      
      if err != nil {
        
        completion(.failure(ReadDataError.readDataError))
        
      } else {
        
        guard let quary = querySnapshot else {return }
        
        strongSelf.reFactDataSpec(quary: quary)
        
        completion(.success(strongSelf.taskData))
      }
    }
  }
  
  func reFactData(quary: QuerySnapshot) {
    
    for info in quary.documents {
             
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
               let personPhoto = info.data()["personPhoto"] as? String,
               let requester = info.data()["requester"] as? [String],
               let fcmToken = info.data()["fcmToken"] as? String,
               let missionTaker = info.data()["missionTaker"] as? String,
               let refuse = info.data()["refuse"] as? [String],
               let uid = info.data()["uid"] as? String,
               let chatRoom = info.data()["chatRoom"] as? String else { return }
      
               if status == 1 {
                 continue
               } else {
                 let dataReturn = TaskInfo(email: email, nickname: nickname, gender: gender, taskPhoto: taskPhoto, time: time, detail: detail, lat: lat, long: long, money: money, classfied: classfied, status: status, fileType: fileType, personPhoto: personPhoto, requester: requester, fcmToken: fcmToken, missionTaker: missionTaker, refuse: refuse, uid: uid, chatRoom: chatRoom)
                 
                 self.taskData.append(dataReturn)
             }
           }
  }
  
  func reFactDataSpec(quary: QuerySnapshot) {
    
    for info in quary.documents {
             
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
               let personPhoto = info.data()["personPhoto"] as? String,
               let requester = info.data()["requester"] as? [String],
               let fcmToken = info.data()["fcmToken"] as? String,
               let missionTaker = info.data()["missionTaker"] as? String,
               let refuse = info.data()["refuse"] as? [String],
               let uid = info.data()["uid"] as? String,
               let chatRoom = info.data()["chatRoom"] as? String else { return }
      
                 let dataReturn = TaskInfo(email: email, nickname: nickname, gender: gender, taskPhoto: taskPhoto, time: time, detail: detail, lat: lat, long: long, money: money, classfied: classfied, status: status, fileType: fileType, personPhoto: personPhoto, requester: requester, fcmToken: fcmToken, missionTaker: missionTaker, refuse: refuse, uid: uid, chatRoom: chatRoom)
                 
                 self.taskData.append(dataReturn)
           }
  }
  
  func filterClassified(classified: Int) -> [String] {
    
    switch classified {
      
    case 0 :
      
      return [self.taskClassified[0].title, self.taskClassified[0].image]
    case 1 :
      
      return [self.taskClassified[1].title, self.taskClassified[1].image]
    case 2 :
      
      return [self.taskClassified[2].title, self.taskClassified[2].image]
    case 3 :
      
      return [self.taskClassified[3].title, self.taskClassified[3].image]
    case 4 :
      
      return [self.taskClassified[4].title, self.taskClassified[4].image]
    case 5 :
      
      return [self.taskClassified[5].title, self.taskClassified[5].image]
    case 6 :
      
      return [self.taskClassified[6].title, self.taskClassified[6].image]
    case 7 :
      
      return [self.taskClassified[7].title, self.taskClassified[7].image]
    default:
      
      return [self.taskClassified[8].title, self.taskClassified[8].image]
    }
  }
  
  func filterClassifiedToInt(task: String) -> Int {
    
    switch task {
      
    case taskClassified[0].title :
      
      return 0
    case taskClassified[1].title :
      
      return 1
    case taskClassified[2].title :
      
      return 2
    case taskClassified[3].title :
      
      return 3
    case taskClassified[4].title :
      
      return 4
    case taskClassified[5].title :
      
      return 5
    case taskClassified[6].title :
      
      return 6
    case taskClassified[7].title :
      
      return 7
    default:
      
      return 8
    }
  }
  
  func timeConverter(time: Int) -> String {
    
    let time = Date.init(timeIntervalSince1970: TimeInterval((time)))
    
    let dateFormatter = DateFormatter()
    
    dateFormatter.dateFormat = "yyyy-MM-dd hh:mm"
    
    let timeConvert = dateFormatter.string(from: time)
    
    return timeConvert
  }
  
  func updateTaskRequest(owner: String, completion: @escaping (Result<String, Error>) -> Void) {
    
      guard let uid = UserManager.shared.currentUserInfo?.uid else { return }
    
    dbF.collection("Tasks").whereField("uid", isEqualTo: owner).getDocuments { (querySnapshot, error) in
      
      if error != nil {
        
        completion(.failure(FireBaseUpdateError.updateError))
        
      }
      
      guard let document = querySnapshot?.documents.first,
           var requester = document.data()["requester"] as? [String] else { return }
      
      requester.append(uid)
      
      document.reference.updateData(["requester": requester]) { error in
        
        if error != nil {
          
          completion(.failure(FireBaseUpdateError.updateError))
        }
      }
      
      completion(.success("Update Success"))
    }
  }
  
  func showAlert(title: String, message: String, viewController: UIViewController) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "ok", style: .default) { _ in
      LKProgressHUD.dismiss()
    }
    controller.addAction(okAction)
    viewController.present(controller, animated: true, completion: nil)
  }
  
  func updateWholeTask(task: TaskInfo, completion: @escaping (Result<String, Error>) -> Void ) {
    
    guard let uid = UserManager.shared.currentUserInfo?.uid else { return }
    
    dbF.collection("Tasks").whereField("uid", isEqualTo: uid).getDocuments { (querySnapshot, error) in
      
      if error != nil {
        
        completion(.failure(FireBaseUpdateError.updateError))
        
      }
      
      let taskNewVersion = TaskInfo(email: task.email, nickname: task.nickname, gender: task.gender, taskPhoto: task.taskPhoto, time: task.time, detail: task.detail, lat: task.lat, long: task.long, money: task.money, classfied: task.classfied, status: task.status, fileType: task.fileType, personPhoto: task.personPhoto, requester: task.requester, fcmToken: task.fcmToken, missionTaker: task.missionTaker, refuse: task.refuse, uid: task.uid, chatRoom: task.chatRoom)
      
      if let querySnapshot = querySnapshot {
        
        let document = querySnapshot.documents.first
        
        document?.reference.updateData(taskNewVersion.toDict) { error in
          
          if error != nil {
            
            completion(.failure(FireBaseUpdateError.updateError))
          }
        }
      }
      
      completion(.success("Update Success"))
    }
  }
  
  func createChatRoom(chatRoomID: String, completion: @escaping (Result<String, Error>) -> Void) {
    
    let channel = Channel(name: chatRoomID)
    
    dbF.collection("Chatrooms").document(chatRoomID).setData(channel.representation) { (_) in
      
      completion(.success("ya"))
    }
  }
}
