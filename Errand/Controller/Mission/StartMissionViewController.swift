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
import GoogleMaps
import CoreLocation
import FirebaseAuth
import Firebase
import FirebaseFirestore

class StartMissionViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = UIColor.LG1
    setUpBtn()
    setUpStar()
    setUpTable()
    setUpPicker()
    setUpTextField()
    setUpListener()
  }
  
  let myLocationManager = CLLocationManager()
  let polyline = GMSPolyline()
  let directionManager = MapManager.shared
  
  @IBOutlet weak var infoTableView: UITableView!
  
  let judge = ["認真服務", "態度優良", "服務惡劣", "態度不佳"]
  
  let dbF = Firestore.firestore()
  
  var receiveTime: String?
  
  var detailData: TaskInfo?
  
  var reference: CollectionReference?
  
  private var messageListener: ListenerRegistration?
  
  @IBOutlet weak var judgePicker: UIPickerView!
  
  @IBOutlet weak var judgeLabel: UILabel!
  
  @IBOutlet weak var judgeTextView: KMPlaceholderTextView!
  
  @IBOutlet weak var starView: CosmosView!
  
  @IBOutlet weak var finishBtn: UIButton!
  
  @IBAction func finishAct(_ sender: Any) {
    
    guard let taskData = self.detailData,
      let status = UserManager.shared.currentUserInfo?.status,
      let judge = judgeTextView.text else { return }
    var owner = ""
    var judgerOwner = ""
    if status == 1 {
      owner = "ownerOK"
      judgerOwner = taskData.missionTaker
    } else {
      owner = "taskOK"
      judgerOwner = taskData.uid
    }
    
    let group = DispatchGroup()
    
    group.enter()
    group.enter()
    
    TaskManager.shared.updateJudge(owner: judgerOwner, classified: taskData.classfied, judge: judge, star: starView.rating) { (result) in
      switch result {
      case .success:
        group.leave()
      case .failure:
        print("error")
      }
    }
    
    TaskManager.shared.taskUpdateData(uid: taskData.uid, status: true, identity: owner)  { (result) in
      switch result {
      case .success:
        group.leave()
      case .failure:
        print("error")
      }
    }
    
    group.notify(queue: DispatchQueue.main) {
      
      TaskManager.shared.showAlert(title: "恭喜", message: "正在等待對方完成", viewController: self)
    }
    
  }
  func setUpTable() {
    infoTableView.delegate = self
    infoTableView.dataSource = self
    infoTableView.backgroundColor = .clear
    infoTableView.register(UINib(nibName: "StartMissionTableViewCell", bundle: nil), forCellReuseIdentifier: "startMission")
  }
  
  func setUpTextField() {
    judgeTextView.text = judge[0]
    judgeTextView.layer.cornerRadius = judgeTextView.bounds.width / 20
    judgeTextView.layer.shadowOpacity = 0.4
    judgeTextView.layer.shadowColor = UIColor.black.cgColor
    judgeTextView.clipsToBounds = false
    judgeTextView.layer.shadowOffset = CGSize(width: 5, height: 5)
  }
  
  func setUpBtn() {
    let alertBtn = UIBarButtonItem(image: UIImage(named: "alert"), style: .plain, target: self, action: #selector(report))
    self.navigationItem.rightBarButtonItem = alertBtn
    finishBtn.layer.cornerRadius = finishBtn.bounds.height / 5
    finishBtn.layer.shadowOpacity = 0.4
    finishBtn.layer.shadowColor = UIColor.black.cgColor
    finishBtn.layer.shadowOffset = CGSize(width: 3, height: 3)
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
  
  @objc func report () {
    
    
  }
  
  func setUpListener() {
    guard let data = detailData else { return }
    dbF.collection("Tasks").document(data.uid).addSnapshotListener { querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
        return
      }
      
      TaskManager.shared.reFactDataSpec(quary: snapshot) { [weak self] result in
        
        guard let strongSelf = self else { return }
        
        switch result {
          
        case .success(let dataReturn):
          
          strongSelf.detailData = dataReturn
          
          guard let taskData = strongSelf.detailData,
            let status = UserManager.shared.currentUserInfo?.status else { return }
          
          if taskData.takerOK && taskData.ownerOK {
            
          } else if status == 1 && taskData.takerOK {
            TaskManager.shared.showAlert(title: "注意", message: "對方已完成任務", viewController: strongSelf)
          } else if status == 2 && taskData.ownerOK {
            TaskManager.shared.showAlert(title: "注意", message: "對方已完成任務", viewController: strongSelf)
          } else { }
          
        case .failure:
          print("error")
        }
      }
    }
  }
  
  func showAlert(title: String, message: String, viewController: UIViewController) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "ok", style: .default) { [weak self]_ in
      
      guard let strongSelf = self else { return }
      guard let task = strongSelf.detailData else { return }
      
      let group
      
      TaskManager.shared.taskUpdateData(uid: task.uid, status: true, identity: "isComplete") { (result) in
        switch result {
        case .success:
          strongSelf.dismiss(animated: true, completion: nil)
        case .failure:
          print("error")
        }
      }
      LKProgressHUD.dismiss()
     }
    controller.addAction(okAction)
    viewController.present(controller, animated: true, completion: nil)
  }
}

extension StartMissionViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "startMission", for: indexPath) as? StartMissionTableViewCell,
      let taskData = detailData  else { return UITableViewCell() }
    
    let classified = TaskManager.shared.filterClassified(classified: taskData.classfied + 1)
    
    cell.setUp(ownerImage: taskData.personPhoto, author: taskData.nickname, classified: classified[0], price: taskData.money)
    
    cell.backgroundColor = .clear
    
    cell.tapOnButton = { 
      
      self.performSegue(withIdentifier: "chat", sender: nil)
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 140
  }
}

extension StartMissionViewController: UIPickerViewDelegate, UIPickerViewDataSource {
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
