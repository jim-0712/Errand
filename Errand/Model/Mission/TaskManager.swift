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
  
  private init() {}
  
  let dbF = Firestore.firestore()
  
  let database = Database.database().reference()
  
  var address = ""
  
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
    
    let info = TaskInfo(email: email, nickname: nickname, gender: gender, taskPhoto: taskPhoto, time: taskData[0], detail: detail, lat: lat, long: long, money: taskData[1], classfied: taskData[2], status: taskData[3], ownerOK: false, takerOK: false, ownerAskFriend: false, takerAskFriend: false, fileType: fileType, personPhoto: personPhoto, requester: [], fcmToken: fcmToken, missionTaker: "", refuse: [], uid: uid, chatRoom: "", isFrirndsNow: false, isComplete: false, star: 0.0, ownerJudge: false, takerJudge: false)
    
      dbF.collection("Tasks").document(uid).setData(info.toDict) { error in
      
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
    
    self.taskData = []
    var storeData: [TaskInfo] = []
    for info in quary.documents {
      
      self.reFactDataSpec(quary: info) { result in
        
        switch result {
        case .success(let task):
          
          if task.status == 1 || task.isComplete {
            
          } else {
            self.taskData.append(task)
            storeData.append(task)
          }
        case .failure(let error):
          print(error.localizedDescription)
        }
      }
    }
    self.taskData = storeData
  }
  
  func reFactDataSpec(quary: QuerySnapshot) {
    
    self.taskData = []
    
    for info in quary.documents {
      
      self.reFactDataSpec(quary: info) { result in
        
        switch result {
        case .success(let task):
          self.taskData.append(task)
        case .failure(let error):
          print(error.localizedDescription)
        }
      }
    }
  }
  
  func reFactDataSpec(quary: DocumentSnapshot, completion: @escaping (Result<TaskInfo, Error>) -> Void) {
    
    guard let quary = quary.data() else { return }
    
    self.taskData = []
    guard let email = quary["email"] as? String,
      let nickname = quary["nickname"] as? String,
      let gender = quary["gender"] as? Int,
      let taskPhoto = quary["taskPhoto"] as? [String],
      let time = quary["time"] as? Int,
      let detail = quary["detail"] as? String,
      let lat = quary["lat"] as? Double,
      let long = quary["long"] as? Double,
      let money = quary["money"] as? Int,
      let status = quary["status"] as? Int,
      let fileType = quary["fileType"] as? [Int],
      let classfied = quary["classfied"] as? Int,
      let personPhoto = quary["personPhoto"] as? String,
      let requester = quary["requester"] as? [String],
      let fcmToken = quary["fcmToken"] as? String,
      let missionTaker = quary["missionTaker"] as? String,
      let refuse = quary["refuse"] as? [String],
      let uid = quary["uid"] as? String,
      let chatRoom = quary["chatRoom"] as? String,
      let isComplete = quary["isComplete"] as? Bool,
      let ownerOK = quary["ownerOK"] as? Bool,
      let takerOK = quary["takerOK"] as? Bool,
      let star = quary["star"] as? Double,
      let ownerAskFriend = quary["ownerAskFriend"] as? Bool,
      let takerAskFriend = quary["takerAskFriend"] as? Bool,
      let isFrirndsNow = quary["isFrirndsNow"] as? Bool,
      let ownerJudge = quary["ownerJudge"] as? Bool,
      let takerJudge = quary["takerJudge"] as? Bool else { return }
    
    let dataReturn = TaskInfo(email: email, nickname: nickname, gender: gender, taskPhoto: taskPhoto, time: time, detail: detail, lat: lat, long: long, money: money, classfied: classfied, status: status, ownerOK: ownerOK, takerOK: takerOK, ownerAskFriend: ownerAskFriend, takerAskFriend: takerAskFriend, fileType: fileType, personPhoto: personPhoto, requester: requester, fcmToken: fcmToken, missionTaker: missionTaker, refuse: refuse, uid: uid, chatRoom: chatRoom, isFrirndsNow: isFrirndsNow, isComplete: isComplete, star: star, ownerJudge: ownerJudge, takerJudge: takerJudge)
    
    completion(.success(dataReturn))
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
  
  func updateWholeTask(task: TaskInfo, uid: String, completion: @escaping (Result<String, Error>) -> Void ) {
    
    dbF.collection("Tasks").whereField("uid", isEqualTo: uid).getDocuments { (querySnapshot, error) in
      
      if error != nil {
        
        completion(.failure(FireBaseUpdateError.updateError))
        
      }
      
      let taskNewVersion = TaskInfo(email: task.email, nickname: task.nickname, gender: task.gender, taskPhoto: task.taskPhoto, time: task.time, detail: task.detail, lat: task.lat, long: task.long, money: task.money, classfied: task.classfied, status: task.status, ownerOK: task.ownerOK, takerOK: task.takerOK, ownerAskFriend: task.ownerAskFriend, takerAskFriend: task.takerAskFriend, fileType: task.fileType, personPhoto: task.personPhoto, requester: task.requester, fcmToken: task.fcmToken, missionTaker: task.missionTaker, refuse: task.refuse, uid: task.uid, chatRoom: task.chatRoom, isFrirndsNow: task.isFrirndsNow, isComplete: task.isComplete, star: task.star, ownerJudge: task.ownerJudge, takerJudge: task.takerJudge)
      
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
  
  func taskUpdateData(uid: String, status: Bool, identity: String, completion: @escaping (Result<String, Error>) -> Void) {
    
    dbF.collection("Tasks").whereField("uid", isEqualTo: uid).getDocuments { (querySnapshot, error) in
      if let querySnapshot = querySnapshot {
        guard let document = querySnapshot.documents.first else { return }
        
        self.reFactDataSpec(quary: document) { result in
          
          switch result {
          case .success(var taskInfo):
            
            if identity == "ownerOK" {
              
              taskInfo.ownerOK = status
              
            } else {
              taskInfo.takerOK = status
            }
            
            document.reference.updateData(taskInfo.toDict) { (error) in
              
              if error != nil {
                
                completion(.failure(FireBaseUpdateError.updateError))
                
              } else {
                
                completion(.success("Update Success"))
                
              }
            }
            
          case .failure:
            print("error")
          }
        }
      }
    }
  }
  
  func updateJudge(owner: String, classified: Int, judge: String, star: Double, completion: @escaping (Result<String, Error>) -> Void) {
    
    let info = JudgeInfo(owner: owner, judge: judge, star: star, classified: classified)
    
    dbF.collection("Judge").addDocument(data: info.toDict) { _  in
      
      completion(Result.success("Success"))
    }
  }
  
  func deleteTask(uid: String, completion: @escaping (Result<String, Error>) -> Void) {
    
    dbF.collection("Tasks").document(uid).delete { error in
      if error != nil {
        completion(.failure(FireBaseUpdateError.updateError))
      } else {
        completion(.success("Success"))
      }
    }
  }
  
  func setUpStatusData(completion: @escaping (Result<TaskInfo, Error>) -> Void) {
    
    guard let userInfo = UserManager.shared.currentUserInfo else {
      
      return
    }
    
    if userInfo.status == 1 {
      
      TaskManager.shared.readSpecificData(parameter: "uid", parameterString: userInfo.uid) { result in
        
        switch result {
        case .success(let taskInfo):
          
          completion(.success(taskInfo[0]))
          
        case .failure:
          completion(.failure(FireBaseUpdateError.updateError))
        }
      }
    } else if userInfo.status == 2 {
      TaskManager.shared.readSpecificData(parameter: "missionTaker", parameterString: userInfo.uid) { result in
        
        switch result {
        case .success(let taskInfo):
          completion(.success(taskInfo[0]))
        case .failure:
          completion(.failure(FireBaseUpdateError.updateError))
        }
      }
    } else if userInfo.status == 0 {
      completion(.failure(MissionError.completeMission))
    }
  }
  
  func  readJudgeData(uid: String, completion: @escaping (Result<[JudgeInfo], Error>) -> Void) {
  
    dbF.collection("Judge").whereField("owner", isEqualTo: uid).getDocuments { quarySnapShot, error in
      
      if error != nil {
        completion(.failure(FireBaseDownloadError.downloadError))
      }
      
      guard let judgeData = quarySnapShot else { return }
      
      var dataStore: [JudgeInfo] = []
      
      for quary in judgeData.documents {
        
        guard let owner = quary["owner"] as? String,
             let judge = quary["judge"] as? String,
             let star = quary["star"] as? Double,
             let classified = quary["classified"] as? Int else { return }
        
          let data = JudgeInfo(owner: owner, judge: judge, star: star, classified: classified)
          dataStore.append(data)
      }
      
      completion(.success(dataStore))
    
    }
  }
  
}
