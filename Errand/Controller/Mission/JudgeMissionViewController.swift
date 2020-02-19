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
  
  let judge = ["認真服務", "態度優良", "服務惡劣", "態度不佳"]
  
  let dbF = Firestore.firestore()
  
  var receiveTime: String?
  
  var detailData: TaskInfo?
  
  @IBOutlet weak var judgePicker: UIPickerView!
  
  @IBOutlet weak var judgeLabel: UILabel!
  
  @IBOutlet weak var judgeTextView: KMPlaceholderTextView!
  
  @IBOutlet weak var starView: CosmosView!
  
  @IBOutlet weak var backBtn: UIButton!
  
  @IBOutlet weak var finishJudgeBtn: UIButton!
  
  @IBOutlet weak var backView: UIView!
  
  @IBAction func backAct(_ sender: Any) {
    
    let mapView = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab")
    
    self.view.window?.rootViewController = mapView
    
  }
  
  @IBOutlet weak var addFriendBtn: UIButton!
  
  // swiftlint:disable cyclomatic_complexity
  @IBAction func addFriendsBtn(_ sender: Any) {
    
    guard let status = UserManager.shared.currentUserInfo?.status,
      let taskInfo = self.detailData else { return }
    
    var reFaceData = taskInfo
    
    if status == 1 {
      reFaceData.ownerAskFriend = true
    } else if status == 2 {
      reFaceData.takerAskFriend = true
    } else { print("friend") }
    
    if status == 1 && taskInfo.ownerAskFriend {
      TaskManager.shared.showAlert(title: "等待中", message: "您已送出邀請", viewController: self)
    } else if status == 2 && taskInfo.takerAskFriend {
      TaskManager.shared.showAlert(title: "等待中", message: "您已送出邀請", viewController: self)
    } else {
      let controller = UIAlertController(title: "好友", message: "確定送出好友邀請？", preferredStyle: .alert)
      let okAction = UIAlertAction(title: "ok", style: .default) { _ in
        LKProgressHUD.show(controller: self)
        TaskManager.shared.updateWholeTask(task: reFaceData, uid: reFaceData.uid) { result in
          
          switch result {
          case .success:
            LKProgressHUD.dismiss()
            print("ya")
          case .failure:
            print("fuck")
          }
        }
      }
      let cancelAct = UIAlertAction(title: "cancel", style: .cancel, handler: nil)
      controller.addAction(okAction)
      controller.addAction(cancelAct)
      self.present(controller, animated: true, completion: nil)
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
          self.addFriendJudge(taskInfo: taskInfo)
          
        case .failure(let error):
          print(error.localizedDescription)
        }
      }
    }
  }
  
  func addFriendJudge(taskInfo: TaskInfo) {
    
    guard let status = UserManager.shared.currentUserInfo?.status else { return }

    var reFaceData = taskInfo
    
    if taskInfo.takerAskFriend && taskInfo.ownerAskFriend && !taskInfo.isFrirndsNow {
      
      if !taskInfo.isFrirndsNow {
        let chatRoomID = UUID().uuidString
        
        UserManager.shared.getFriends { result in
          switch result {
          case .success(let friends):
            
            var nameRef: DocumentReference?
            var alreadyFriend = false
            
            if status == 1 {
              nameRef = self.dbF.collection("Users").document(taskInfo.missionTaker)
            } else if status == 2 {
              nameRef = self.dbF.collection("Users").document(taskInfo.uid)
            } else { }
            
            guard let nameRe = nameRef else { return }
            
            for count in 0 ..< friends.count {
              if friends[count].nameREF == nameRe {
                alreadyFriend = true
              }
            }
            
            if !alreadyFriend {
              
              TaskManager.shared.createChatRoom(chatRoomID: chatRoomID) { result in
                switch result {
                case .success:
                  print("ChatRoomOK")
                  UserManager.shared.updatefreinds(ownerUid: taskInfo.uid, takerUid: taskInfo.missionTaker, chatRoomID: chatRoomID) { result in
                    switch result {
                    case .success:
                      LKProgressHUD.dismiss()
                    case .failure:
                      print("no")
                    }
                  }
                  
                  reFaceData.isFrirndsNow = true
                  
                  TaskManager.shared.updateWholeTask(task: reFaceData, uid: taskInfo.uid) { result in
                    switch result {
                    case .success:
                      print("ya")
                    case .failure:
                      print("error")
                    }
                  }
                  
                case .failure:
                  print("no")
                }
              }
              
            }
            
          case .failure:
            print("friendsError")
          }
        }
      }
    } else { }
    
  }
  
  @IBAction func finishJudgeAct(_ sender: Any) {
    
    guard let taskData = self.detailData,
      let status = UserManager.shared.currentUserInfo?.status,
      let judge = judgeTextView.text else { return }
    var judgerOwner = ""
    if status == 1 {
      judgerOwner = taskData.missionTaker
    } else {
      judgerOwner = taskData.uid
    }
    
    TaskManager.shared.updateJudge(owner: judgerOwner, classified: taskData.classfied, judge: judge, star: starView.rating) { (result) in
      switch result {
      case .success:
        print("ok")
      case .failure:
        print("error")
      }
    }
    
    let controller = UIAlertController(title: "恭喜", message: "已完成評分", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "ok", style: .default) { _ in
      
      let mapView = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab")
      
      self.view.window?.rootViewController = mapView
    }
    controller.addAction(okAction)
    self.present(controller, animated: true, completion: nil)
  }
  // swiftlint:enable cyclomatic_complexity
  func setUpTextField() {
    judgeTextView.text = judge[0]
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
    return judge[row]
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    self.judgeTextView.text = judge[row]
  }
}
