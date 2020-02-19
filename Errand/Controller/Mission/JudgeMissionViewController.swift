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
    self.view.backgroundColor = UIColor.LG1
    setUpall()
  }
  
  func setUpall() {
    setUpStar()
    setUpPicker()
    setUpBtn()
    setUpTextField()
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
