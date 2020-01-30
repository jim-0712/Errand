//
//  PostTaskViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/16.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class MissionListViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUp()
    getTaskData()
    
  }
  
  var detailData: TaskInfo?
  
  let missionGroup = ["搬運物品", "清潔打掃", "水電維修", "科技維修", "驅趕害蟲", "一日陪伴", "交通接送", "其他種類"]
  
  var taskDataReturn = [TaskInfo]() {
    
    didSet {
      if taskDataReturn.isEmpty {
        
        self.postMissionBtn.isHidden = true
        
        LKProgressHUD.show(controller: self)
        
      } else {
        DispatchQueue.main.async {
          
          self.postMissionBtn.isHidden = false
          
          self.taskListTable.reloadData()
          
          LKProgressHUD.dismiss()
        }
      }
    }
  }
  
  @IBOutlet weak var taskListTable: UITableView!
  
  @IBOutlet weak var postMissionBtn: UIButton!
  
  @IBAction func postMissionBtn(_ sender: Any) {
    
    performSegue(withIdentifier: "post", sender: nil)
    
  }
  
  func getTaskData() {
    
    TaskManager.shared.readData { result in
      
      switch result {
        
      case .success(let taskData):
        
        self.taskDataReturn = taskData
        
      case .failure(let error):
        
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: self)
      }
    }
  }
  
  func setUp() {
    
    postMissionBtn.isHidden = true
    
    taskListTable.delegate = self
    
    taskListTable.dataSource = self
    
    taskListTable.translatesAutoresizingMaskIntoConstraints = false
    
    taskListTable.rowHeight = UITableView.automaticDimension
    
    taskListTable.estimatedRowHeight = 200
  }
  
}

extension MissionListViewController: UITableViewDataSource, UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return taskDataReturn.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    if taskDataReturn.isEmpty {
      
      return UITableViewCell()
    } else {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "list", for: indexPath) as? ListTableViewCell else { return UITableViewCell() }
      
      cell.delegate = self
      
      let data = taskDataReturn[indexPath.row]
      
      let time = Date.init(timeIntervalSince1970: TimeInterval((data.time)))
      
      let dateFormatter = DateFormatter()
      
      dateFormatter.dateFormat = "dd-MM-yyyy hh:mm"
      
      let timeConvert = dateFormatter.string(from: time)
      
      switch data.classfied {
        
      case 0 :
        
        cell.setUp(missionImage: "trucks", author: data.nickname, missionLabel: missionGroup[0], price: data.money, time: timeConvert, timeInt: data.time)
        
      case 1 :
        
        cell.setUp(missionImage: "broom", author: data.nickname, missionLabel: missionGroup[1], price: data.money, time: timeConvert, timeInt: data.time)
        
      case 2 :
        
        cell.setUp(missionImage: "fix", author: data.nickname, missionLabel: missionGroup[2], price: data.money, time: timeConvert, timeInt: data.time)
      case 3 :
        
        cell.setUp(missionImage: "tools", author: data.nickname, missionLabel: missionGroup[3], price: data.money, time: timeConvert, timeInt: data.time)
      case 4 :
        
        cell.setUp(missionImage: "bug", author: data.nickname, missionLabel: missionGroup[4], price: data.money, time: timeConvert, timeInt: data.time)
      case 5 :
        
        cell.setUp(missionImage: "develop", author: data.nickname, missionLabel: missionGroup[5], price: data.money, time: timeConvert, timeInt: data.time)
      case 6 :
        
        cell.setUp(missionImage: "drive", author: data.nickname, missionLabel: missionGroup[6], price: data.money, time: timeConvert, timeInt: data.time)
      default:
        
        cell.setUp(missionImage: "questions", author: data.nickname, missionLabel: missionGroup[7], price: data.money, time: timeConvert, timeInt: data.time)
      }
      
      return cell
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == "detail" {
        
        guard let detailVC = segue.destination as? MissionDetailViewController else { return }

        detailVC.detailData = detailData
    }
  }
}

extension MissionListViewController: DetailManager {
  
  func detailData(tableViewCell: ListTableViewCell, nickName: String, time: Int) {
    
    for count in 0 ..< taskDataReturn.count {
      
      if taskDataReturn[count].time == time && taskDataReturn[count].nickname == nickName {
        
        self.detailData = taskDataReturn[count]
        
        self.performSegue(withIdentifier: "detail", sender: nil)
      }
    }
  }
}
