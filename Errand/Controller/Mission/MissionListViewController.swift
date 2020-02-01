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
    
    NotificationCenter.default.addObserver(self, selector: #selector(reloadTable), name: Notification.Name("postMission"), object: nil)
    
    setUp()
    getTaskData()
    setUpSearch()
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    shouldShowSearchResults = false
  }
  
  @objc func reloadTable() {
    
    TaskManager.shared.taskData = []
    taskDataReturn = []
    getTaskData()
  }
  
  var detailData: TaskInfo?
  
  var data: TaskInfo?
  
  var timeString: String?
  
  var shouldShowSearchResults = false {
    
    didSet {
      
      self.taskListTable.reloadData()
    }
  }
  
  let searchCustom = UISearchController(searchResultsController: nil)
  
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
  
  var filteredArray = [TaskInfo]() {
    
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
  
  func setUpSearch() {
    
    self.navigationItem.searchController = searchCustom
    self.navigationController?.navigationBar.prefersLargeTitles = true
    searchCustom.searchBar.searchBarStyle = .prominent
    searchCustom.searchBar.delegate = self
    searchCustom.searchBar.placeholder = "搜尋發文主"
    searchCustom.searchResultsUpdater = self
    searchCustom.searchBar.sizeToFit()
    searchCustom.obscuresBackgroundDuringPresentation = false
  }
  
  func getTaskData() {
    
    TaskManager.shared.readData { [weak self] result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success(let taskData):
        
        strongSelf.taskDataReturn = taskData
        
        strongSelf.postMissionBtn.isHidden = false
        
        LKProgressHUD.dismiss()
        
      case .failure(let error):
        
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
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
    
    if shouldShowSearchResults {
      return filteredArray.count
      
    } else {
      return taskDataReturn.count
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "list", for: indexPath) as? ListTableViewCell else { return UITableViewCell() }
    
    cell.delegate = self
    
    if shouldShowSearchResults {
      
      self.data = filteredArray[indexPath.row]
      
    } else {
      
      self.data = taskDataReturn[indexPath.row]
    }
    
    guard let data = self.data else { return UITableViewCell() }
    
    let time = Date.init(timeIntervalSince1970: TimeInterval((data.time)))
    
    let dateFormatter = DateFormatter()
    
    dateFormatter.dateFormat = "yyyy-MM-dd hh:mm"
    
    let timeConvert = dateFormatter.string(from: time)
    
    self.timeString = timeConvert
    
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
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == "detail" {
      
      guard let detailVC = segue.destination as? MissionDetailViewController,
        let time = self.timeString else { return }
      
      detailVC.detailData = detailData
      
      detailVC.receiveTime = time
    }
  }
}

extension MissionListViewController: DetailManager {
  
  func detailData(tableViewCell: ListTableViewCell, nickName: String, time: Int) {
    
    for count in 0 ..< taskDataReturn.count {
      
      if taskDataReturn[count].time == time && taskDataReturn[count].nickname == nickName {
        
        self.detailData = taskDataReturn[count]
        break
      }
    }
    self.performSegue(withIdentifier: "detail", sender: nil)
  }
}

extension MissionListViewController: UISearchBarDelegate {
  
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    
    shouldShowSearchResults = true
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    
    shouldShowSearchResults = false
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    
    if !shouldShowSearchResults {
      shouldShowSearchResults = true
      
    }
    searchCustom.searchBar.resignFirstResponder()
  }
}

extension MissionListViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    
    guard let searchString = searchCustom.searchBar.text else { return }
    
    self.filteredArray = taskDataReturn.filter({ (country) -> Bool in
      let countryText: NSString = country.nickname as NSString
      
      return (countryText.range(of: searchString, options: NSString.CompareOptions.caseInsensitive).location) != NSNotFound
    })
    taskListTable.reloadData()
  }
}
