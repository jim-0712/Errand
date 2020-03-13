//
//  StartMissionViewController.swift
//  Errand
//
//  Created by Jim on 2020/2/7.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Cosmos
import KMPlaceholderTextView
import FirebaseAuth
import Firebase
import FirebaseFirestore

class JudgeMissionViewController: UIViewController {
  
  @IBOutlet weak var judgePicker: UIPickerView!
  
  @IBOutlet weak var judgeLabel: UILabel!
  
  @IBOutlet weak var judgeTextView: KMPlaceholderTextView!
  
  @IBOutlet weak var starView: CosmosView!
  
  @IBOutlet weak var backBtn: UIButton!
  
  @IBOutlet weak var finishJudgeBtn: UIButton!
  
  @IBOutlet weak var backView: UIView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setUpall()
  }
  
  func setUpall() {
    setUpStar()
    setUpPicker()
    setUpBtn()
    setUpTextField()
    setUplistener()
  }
  
  var destination = ""
  
  let judgeByOwner = ["認真服務", "態度優良", "服務惡劣", "態度不佳"]
  
  let judgeByRequester = ["給錢大方", "任務簡單", "吹毛求疵", "圖文不符"]
  
  let dbF = Firestore.firestore()
  
  var receiveTime: String?
  
  var detailData: TaskInfo?
  
  @IBAction func backAct(_ sender: Any) {
    
  guard let taskData = self.detailData,
       let judge = judgeTextView.text else { return }
    
    let date = Int(Date().timeIntervalSince1970)
    let status = UserManager.shared.statusJudge
    var judgerOwner = ""
    if status == 1 {
      judgerOwner = taskData.missionTaker
    } else {
      judgerOwner = taskData.uid
    }
    
    let group = DispatchGroup()
    LKProgressHUD.show(controller: self)
    group.enter()
    group.enter()
    
    let judgeInfo = JudgeInfo(owner: judgerOwner, judge: judge, star: -0.1, classified: taskData.classfied, date: date)
    
    TaskManager.shared.updateJudge(judge: judgeInfo) { (result) in
      switch result {
      case .success:
        group.leave()
      case .failure:
        print("error")
      }
    }
    
    UserManager.shared.readUserInfo(uid: judgerOwner, isSelf: false) { result in
      switch result {
      case .success(var accountInfo):
        accountInfo.taskCount += 1
        accountInfo.noJudgeCount += 1
        UserManager.shared.updateOppoInfo(userInfo: accountInfo) { result in
          switch result {
          case .success:
            group.leave()
          case .failure:
            print("error")
          }
        }
      case .failure:
        print("error")
      }
    }
    
    addFriendJudge(taskInfo: taskData)
    
    group.notify(queue: DispatchQueue.main) {
      LKProgressHUD.dismiss()
      let mapView = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(withIdentifier: "tab")
      
      self.view.window?.rootViewController = mapView
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    UserManager.shared.statusJudge = 0
  }
  
  @IBOutlet weak var addFriendBtn: UIButton!
  
  @IBAction func addFriendsBtn(_ sender: Any) {
    
    guard let taskInfo = self.detailData else { return }
    
    var reFaceData = taskInfo
    
    var nameRef: DocumentReference?
    
    let status = UserManager.shared.statusJudge
    
    if status == 1 {
      reFaceData.ownerAskFriend = true
      nameRef = self.dbF.collection("Users").document(taskInfo.missionTaker)
    }
    if status == 2 {
      reFaceData.takerAskFriend = true
      nameRef = self.dbF.collection("Users").document(taskInfo.uid)
    }
    
    guard let nameReference = nameRef else { return }
    
    UserManager.shared.checkFriends(nameRef: nameReference) { result in
      switch result {
      case .success(let isFriends):
        
        if !isFriends {
          if status == 1 && taskInfo.ownerAskFriend || status == 2 && taskInfo.takerAskFriend {
            TaskManager.shared.showAlert(title: "等待中", message: "您已送出邀請", viewController: self)
          } else {
            let controller = UIAlertController(title: "好友", message: "確定送出好友邀請？", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "ok", style: .default) { _ in
              LKProgressHUD.show(controller: self)
              self.refreshTask(task: reFaceData, uid: reFaceData.uid)
            }
            let cancelAct = UIAlertAction(title: "cancel", style: .cancel, handler: nil)
            controller.addAction(okAction)
            controller.addAction(cancelAct)
            self.present(controller, animated: true, completion: nil)
          }
        } else {
          SwiftMes.shared.showErrorMessage(body: "此用戶已在好友名單", seconds: 0.8)
        }
        
      case .failure:
        print("error")
      }
    }
  }
  
  func setUplistener() {
    guard let data = detailData else { return }
    dbF.collection("Tasks").document(data.uid).addSnapshotListener { querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
        return
      }
      
      TaskManager.shared.reFactDataSpec(quary: snapshot) { result in
        switch result {
        case .success(let taskInfo):
          self.detailData = taskInfo
          
        case .failure(let error):
          print(error.localizedDescription)
        }
      }
    }
  }
  
  func addFriendJudge(taskInfo: TaskInfo) {
    
    let statusss = UserManager.shared.statusJudge
    if taskInfo.takerAskFriend && taskInfo.ownerAskFriend && !taskInfo.isFrirndsNow {
      
      UserManager.shared.fetchFriends { result in
        switch result {
        case .success(let friends):
          
          var nameRef: DocumentReference?
          var alreadyFriend = false
          
          if statusss == 1 {
            nameRef = self.dbF.collection("Users").document(taskInfo.missionTaker)
          }
          if statusss == 2 {
            nameRef = self.dbF.collection("Users").document(taskInfo.uid)
          }
          
          guard let nameRe = nameRef else { return }
          for friend in friends where friend.nameREF == nameRe {
            alreadyFriend = true
          }
          
          if !alreadyFriend {
            self.addFriendsAct(taskInfo: taskInfo)
          }
        case .failure:
          print("friendsError")
        }
      }
    }
  }
  
  func addFriendsAct(taskInfo: TaskInfo) {
    var reFaceData = taskInfo
    let chatRoomID = UUID().uuidString
    TaskManager.shared.createChatRoom(chatRoomID: chatRoomID) { result in
      switch result {
      case .success:
        UserManager.shared.updatefreinds(ownerUid: taskInfo.uid, takerUid: taskInfo.missionTaker, chatRoomID: chatRoomID) { result in
          switch result {
          case .success :
            LKProgressHUD.dismiss()
          case .failure :
            print("Fail on update friends")
          }
        }
        
        reFaceData.isFrirndsNow = true
        self.refreshTask(task: reFaceData, uid: taskInfo.uid)
        
      case .failure:
        print("Fail on create chatroom")
      }
    }
  }
  
  @IBAction func finishJudgeAct(_ sender: Any) {
    
    guard let taskData = self.detailData,
      let judge = judgeTextView.text else { return }
    
    let date = Int(Date().timeIntervalSince1970)
    let status = UserManager.shared.statusJudge
    var judgerOwner = ""
    if status == 1 {
      judgerOwner = taskData.missionTaker
    } else {
      judgerOwner = taskData.uid
    }
    
    let group = DispatchGroup()
    group.enter()
    
    let judgeInfo = JudgeInfo(owner: judgerOwner, judge: judge, star: starView.rating, classified: taskData.classfied, date: date)
    
    TaskManager.shared.updateJudge(judge: judgeInfo) { (result) in
      switch result {
      case .success:
        print("Success on update judge")
        group.leave()
      case .failure:
        print("Fail on update judge")
      }
    }
    
    group.enter()
    UserManager.shared.readUserInfo(uid: judgerOwner, isSelf: false) { [weak self]result in
      guard let strongSelf = self else { return }
      switch result {
      case .success(var judgeOwnerInfo):
        judgeOwnerInfo.totalStar += strongSelf.starView.rating
        judgeOwnerInfo.taskCount += 1
        
        UserManager.shared.updateOppoInfo(userInfo: judgeOwnerInfo) { result in
          switch result {
          case .success:
            group.leave()
          case .failure:
            print("Fail on update userInfo")
          }
        }
      case .failure:
        print("Fail on read userInfo")
      }
    }
    
    addFriendJudge(taskInfo: taskData)
    
    let controller = UIAlertController(title: "恭喜", message: "已完成評分", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "ok", style: .default) { _ in
      
      let mapView = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(withIdentifier: "tab")
      
      self.view.window?.rootViewController = mapView
    }
    controller.addAction(okAction)
    
    group.notify(queue: DispatchQueue.main) {
      self.present(controller, animated: true, completion: nil)
    }
  }
  
  // swiftlint:enable cyclomatic_complexity
  func setUpTextField() {
    if UserManager.shared.statusJudge == 1 {
      judgeTextView.text = judgeByOwner[0]
    } else {
      judgeTextView.text = judgeByRequester[0]
    }
    judgeTextView.layer.cornerRadius = judgeTextView.bounds.width / 20
    judgeTextView.layer.shadowOpacity = 0.6
    judgeTextView.layer.shadowOffset = .zero
    judgeTextView.layer.shadowColor = UIColor.black.cgColor
    judgeTextView.clipsToBounds = false
  }
  
  func setUpBtn() {
    backBtn.layer.cornerRadius = backBtn.bounds.height / 2
    finishJudgeBtn.layer.cornerRadius = finishJudgeBtn.bounds.height /  10
    finishJudgeBtn.layer.shadowOpacity = 0.5
    finishJudgeBtn.layer.shadowOffset = .zero
    backView.layer.cornerRadius = backView.bounds.width / 30
    backView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
  }
  
  func setUpPicker() {
    judgePicker.delegate = self
    judgePicker.dataSource = self
  }
  
  func setUpStar() {
    starView.rating = 2.5
    starView.backgroundColor = .clear
    starView.settings.starSize = 40
    starView.settings.totalStars = 5
    starView.settings.starMargin = 20
    starView.settings.updateOnTouch = true
    starView.settings.fillMode = .precise
    starView.settings.emptyImage = UIImage(named: "star-2")?.withRenderingMode(.alwaysOriginal)
    starView.settings.filledImage = UIImage(named: "star-3")?.withRenderingMode(.alwaysOriginal)
  }
  
  func refreshTask(task: TaskInfo, uid: String) {
    TaskManager.shared.updateWholeTask(task: task, uid: uid) { result in
      switch result {
      case .success:
        print("Success on update Task")
        LKProgressHUD.dismiss()
      case .failure:
        print("Fail on update Task")
      }
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "chat" {
      guard let chatVC = segue.destination as? ChatViewController,
        let taskInfo = detailData else { return }
      chatVC.detailData = taskInfo
    }
  }
}

extension JudgeMissionViewController: UIPickerViewDelegate, UIPickerViewDataSource {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return 4
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    
    let status = UserManager.shared.statusJudge
    
    if status == 1 {
      return judgeByOwner[row]
    } else {
      return judgeByRequester[row]
    }
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    
    let status = UserManager.shared.statusJudge
    
    if status == 1 {
      self.judgeTextView.text = judgeByOwner[row]
    } else {
      self.judgeTextView.text = judgeByRequester[row]
    }
  }
}
