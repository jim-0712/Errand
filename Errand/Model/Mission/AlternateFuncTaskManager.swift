//
//  AlternateFuncTaskManager.swift
//  Errand
//
//  Created by Jim on 2020/3/5.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation

class MutipleFuncManager {
  
  static let shared = MutipleFuncManager()
  
  private init () { }
  
  func giveUpMission(taskData: TaskInfo, completion: @escaping (Result<String, Error>) -> Void) {
    
    var taskInfo = taskData
    
     var destinationFcmToken = ""
     
     guard let user = UserManager.shared.currentUserInfo else {
          return
       }
     
     let group = DispatchGroup()
     let missionTaker = taskInfo.missionTaker
     
     if user.status == 1 {
       group.enter()
       TaskManager.shared.deleteTask(uid: user.uid) { result in
         switch result {
         case .success:
          print("1")
           group.leave()
         case .failure:
           group.leave()
         }
       }
       
      group.enter()
      UserManager.shared.readUserInfo(uid: missionTaker, isSelf: false) { result in
        switch result {
        case .success(let takerAccountInfo):
          print("2")
          destinationFcmToken = takerAccountInfo.fcmToken
          group.leave()
        case .failure:
          group.leave()
        }
      }

      group.enter()
      UserManager.shared.updateStatus(uid: user.uid, status: 0) { result in
        switch result {
        case .success:
          print("3")
          group.leave()
        case .failure:
          group.leave()
        }
      }
      
      group.enter()
      UserManager.shared.updateStatus(uid: missionTaker, status: 0) { result in
        switch result {
        case .success:
          print("4")
          group.leave()
        case .failure:
          group.leave()
        }
      }
     } else {
       
       destinationFcmToken = taskInfo.fcmToken
       taskInfo.missionTaker = ""
       taskInfo.status = 0
       taskInfo.ownerCompleteTask = false
       taskInfo.takerCompleteTask = false
       
       group.enter()
       TaskManager.shared.updateWholeTask(task: taskInfo, uid: taskInfo.uid) { result in
         switch result {
         case .success:
           group.leave()
         case .failure:
           group.leave()
         }
       }
       
      group.enter()
      UserManager.shared.updateStatus(uid: missionTaker, status: 0) { result in
        switch result {
        case .success:
          group.leave()
        case .failure:
          group.leave()
        }
      }
    }
       
       group.notify(queue: DispatchQueue.main) {
         UserManager.shared.readUserInfo(uid: user.uid, isSelf: true) { result in
           switch result {
           case .success(var accountInfo):
             
             if accountInfo.totalStar != 0 {
                accountInfo.totalStar -= 1.0
             }
            
            UserManager.shared.updateOppoInfo(userInfo: accountInfo) { result in
              switch result {
              case .success:
                APImanager.shared.postNotification(to: destinationFcmToken, body: "對方放棄任務")
                completion(.success("good"))
              case .failure:
                completion(.failure(FireBaseUpdateError.updateError))
              }
            }
           case .failure:
             print("error")
           }
         }
       }
     }

  func completeMission(taskData: TaskInfo, completion: @escaping ((Result<String, Error>) -> Void)) {

    guard let status = UserManager.shared.currentUserInfo?.status else {
        return
    }
    
    var taskInfo = taskData
    var taskCompleteStatus = ""
    var destinationFcmToken = ""
    
    if status == 1 {
      taskCompleteStatus = "ownerCompleteTask"
      taskInfo.ownerCompleteTask = true
    } else {
      taskCompleteStatus = "takerCompleteTask"
      taskInfo.takerCompleteTask = true
    }
    
    let group = DispatchGroup()
    
    group.enter()
    group.enter()
    TaskManager.shared.taskUpdateData(uid: taskInfo.uid, status: true, identity: taskCompleteStatus) { (result) in
      switch result {
      case .success:
        group.leave()
      case .failure:
        group.leave()
      }
    }
    
    if status == 1 {
      UserManager.shared.readUserInfo(uid: taskInfo.missionTaker, isSelf: false) {result in
        switch result {
        case .success(let takerAccount):
          destinationFcmToken = takerAccount.fcmToken
          group.leave()
        case .failure:
          group.leave()
        }
      }
    } else if status == 2 {
      destinationFcmToken = taskInfo.fcmToken
      group.leave()
    } else { group.leave() }
    
    group.notify(queue: DispatchQueue.main) {
      completion(.success(destinationFcmToken))
    }
  }
  
  func addToBlackList(alreadyReport: Bool, taskInfo: TaskInfo, completion: @escaping ((Result<String, Error>) -> Void)) {
    
    guard var userInfo = UserManager.shared.currentUserInfo else { return }
    var reverse = ""
    
    if alreadyReport {
      completion(.success("already"))
    } else {
      
      let group = DispatchGroup()
      
      if userInfo.status == 1 {
        userInfo.blacklist.append(taskInfo.missionTaker)
        reverse = taskInfo.missionTaker
      } else {
        userInfo.blacklist.append(taskInfo.uid)
        reverse = taskInfo.uid
      }
      
      group.enter()
      UserManager.shared.updateOppoInfo(userInfo: userInfo) { result in
        switch result {
        case .success:
          group.leave()
        case .failure:
          group.leave()
          }
      }
      
      group.enter()
      UserManager.shared.updateOppoBlackList(uid: reverse, isSelf: false) { result in
        switch result {
        case .success:
          group.leave()
        case .failure:
          group.leave()
        }
      }
      
      group.notify(queue: DispatchQueue.main) {
        UserManager.shared.currentUserInfo = userInfo
        completion(.success("updateSuccess"))
      }
    }
  }
  
  func finishTask(taskInfo: TaskInfo, completion: @escaping ((Result<String, Error>) -> Void)) {
    
    guard let currentUserStatus = UserManager.shared.currentUserInfo?.status else { return }
    let group = DispatchGroup()
    
    var destinationFcmToken = ""
    
    group.enter()
    group.enter()
    group.enter()
    
    TaskManager.shared.taskUpdateData(uid: taskInfo.uid, status: true, identity: "isComplete") { (result) in
      switch result {
      case .success:
        group.leave()
      case .failure:
        group.leave()
      }
    }
    
    UserManager.shared.updateStatus(uid: taskInfo.uid, status: 0) { result in
      switch result {
      case .success:
        group.leave()
      case .failure:
        group.leave()
      }
    }
    
    if currentUserStatus == 1 {
      group.enter()
      UserManager.shared.readUserInfo(uid: taskInfo.missionTaker, isSelf: false) { result in
        switch result {
        case .success(let takerAccount):
          destinationFcmToken = takerAccount.fcmToken
          group.leave()
        case .failure:
          group.leave()
        }
      }
    } else if currentUserStatus == 2 {
      group.enter()
      destinationFcmToken = taskInfo.fcmToken
      group.leave()
    } else {  group.leave() }
    
    group.notify(queue: DispatchQueue.main) {
      APImanager.shared.postNotification(to: destinationFcmToken, body: "任務完成")
      completion(.success("good"))
    }
  }
  
  func changeStatus(task: TaskInfo, completion: @escaping ((Result<String, Error>) -> Void)) {
    let group = DispatchGroup()
    group.enter()
    TaskManager.shared.taskUpdateData(uid: task.uid, status: true, identity: "isComplete") { (result) in
      switch result {
      case .success:
        group.leave()
      case .failure:
        group.leave()
      }
    }

    group.enter()
    UserManager.shared.updateStatus(uid: task.uid, status: 0) { result in
      switch result {
      case .success:
        group.leave()
      case .failure:
        group.leave()
      }
    }
    
    group.enter()
    UserManager.shared.updateStatus(uid: task.missionTaker, status: 0) { result in
      switch result {
      case .success:
        group.leave()
      case .failure:
        group.leave()
      }
    }
    
    group.notify(queue: DispatchQueue.main) {
      completion(.success("good"))
    }
  }
  
}
