//
//  PostTaskViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/16.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import FirebaseAuth

class MissionListViewController: UIViewController {
  
  var refreshControl: UIRefreshControl!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    LKProgressHUD.show(controller: self)
    setUpSearch()
    setUp()
    setUpindicatorView()
    
    NotificationCenter.default.addObserver(self, selector: #selector(reloadTable), name: Notification.Name("postMission"), object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(reloadTable), name: Notification.Name("takeMission"), object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(reloadTable), name: Notification.Name("acceptRequester"), object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(reloadTable), name: Notification.Name("finishSelf"), object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(reloadTable), name: Notification.Name("getMissionList"), object: nil)
  
  }
  
  var currentBtnSelect = false
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setUpBtn()
    getTaskData()
    startAnimate(sender: allMissionBtn)
    NotificationCenter.default.post(name: Notification.Name("onTask"), object: nil)
  }
  
  @objc func reloadTable() {
    if currentBtnSelect {
       getMissionStartData()
    } else {
       getTaskData()
    }
  }
  
   var indicatorCon: NSLayoutConstraint?
  
  func getMissionStartData() {
    
    guard let user = UserManager.shared.currentUserInfo else { return }
    
    if user.status == 1 {
      
      guard let uid = UserManager.shared.currentUserInfo?.uid else { return }
      
      taskMan.readSpecificData(parameter: "uid", parameterString: uid) {[weak self](result) in
             
             guard let strongSelf = self else { return }
             
             switch result {
               
             case .success(let dataReturn):
               
               strongSelf.taskDataReturn = dataReturn
               
             case .failure(let error):
               
               LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
             }
           }
      
    } else if user.status == 2 {
      
      guard let uid = UserManager.shared.currentUserInfo?.uid else { return }
      
      taskMan.readSpecificData(parameter: "missionTaker", parameterString: uid) { [weak self](result) in
        
        guard let strongSelf = self else { return }
        
        switch result {
          
        case .success(let dataReturn):
          
          strongSelf.taskDataReturn = dataReturn
          
        case .failure(let error):
          
          LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
        }
      }
    } else {
      
      showAlert(title: "注意", message: "當前沒有進行中任務")
      return
    }
  }
  
  func showAlert(title: String, message: String) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default) { _ in
      
      self.startAnimate(sender: self.allMissionBtn)
    }
    controller.addAction(okAction)
    self.present(controller, animated: true, completion: nil)
  }
  
  func startAnimate(sender: UIButton) {
    let move = UIViewPropertyAnimator(duration: 0.1, curve: .easeInOut) {
      self.indicatorCon?.isActive = false
      self.indicatorCon = self.indicatorView.centerXAnchor.constraint(equalTo: sender.centerXAnchor)
      self.indicatorCon?.isActive = true
      self.view.layoutIfNeeded()
    }
    move.startAnimation()
  }
  
  func setUpindicatorView() {
    self.view.addSubview(indicatorView)
    indicatorView.backgroundColor = .G1
    indicatorView.translatesAutoresizingMaskIntoConstraints = false
    indicatorCon = indicatorView.centerXAnchor.constraint(equalTo: allMissionBtn.centerXAnchor)
    
    NSLayoutConstraint.activate([
      indicatorView.topAnchor.constraint(equalTo: btnStackView.bottomAnchor, constant: 0),
      indicatorView.heightAnchor.constraint(equalToConstant: 2),
      indicatorView.widthAnchor.constraint(equalToConstant: allMissionBtn.bounds.width * 0.6),
      indicatorCon!
      ])
  }
  @IBOutlet weak var allMissionBtn: UIButton!
  
  @IBOutlet weak var currentBtn: UIButton!
  
  @IBOutlet weak var btnStackView: UIStackView!
  
  @IBAction func allMissionAct(_ sender: UIButton) {
    currentBtnSelect = false
    LKProgressHUD.show(controller: self)
    getTaskData()
    UserManager.shared.checkDetailBtn = !UserManager.shared.checkDetailBtn
    startAnimate(sender: sender)
  }
  
  @IBAction func currentMission(_ sender: UIButton) {
    currentBtnSelect = true
    UserManager.shared.checkDetailBtn = !UserManager.shared.checkDetailBtn
    startAnimate(sender: sender)
    getMissionStartData()
  }
  
  let indicatorView = UIView()
  
  let taskMan = TaskManager.shared
  
  var detailData: TaskInfo?
  
  var data: TaskInfo?
  
  var timeString: String?
  
  var shouldShowSearchResults = false {
    didSet {
      self.taskListTable.reloadData()
    }
  }
  
  let searchCustom = UISearchController(searchResultsController: nil)
  
  var taskDataReturn = [TaskInfo]() {
    didSet {
      if taskDataReturn.isEmpty {
        self.postMissionBtn.isHidden = true
        LKProgressHUD.dismiss()
        self.taskListTable.reloadData()
      } else {
        DispatchQueue.main.async {
          self.postMissionBtn.isHidden = false
          
          guard let status = UserManager.shared.currentUserInfo?.status else { return }
          if status == 0 || status == 1 {
            self.postMissionBtn.isHidden = false
          } else {
            self.postMissionBtn.isHidden = true
          }
          self.refreshControl.endRefreshing()
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
    if UserManager.shared.currentUserInfo?.status == 0 {
      performSegue(withIdentifier: "post", sender: nil)
    } else if UserManager.shared.currentUserInfo?.status == 1 {
      
      LKProgressHUD.show(controller: self)
      TaskManager.shared.setUpStatusData { result in
        
        switch result {
        case .success(let taskInfo):
          
          if taskInfo.missionTaker.isEmpty {
            TaskManager.shared.showAlert(title: "警告", message: "任務已被接受，不能隨意更改", viewController: self)
          } else {
            guard let editVC = self.storyboard?.instantiateViewController(identifier: "post") as? PostMissionViewController,
                 let status = UserManager.shared.currentUserInfo?.status else { return }
            if status == 1 {
              editVC.isEditing = true
            } else {
              editVC.isEditing = false
            }
             self.present(editVC, animated: true, completion: nil)
          }
        case .failure:
          print("error")
        }
      }
    } else {
      TaskManager.shared.showAlert(title: "任務進行中", message: "請完成當前任務", viewController: self)
    }
  }
  
  func setUpSearch() {
    refreshControl = UIRefreshControl()
    taskListTable.addSubview(refreshControl)
    refreshControl.addTarget(self, action: #selector(reloadTable), for: .valueChanged)
    self.navigationItem.searchController = searchCustom
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
        TaskManager.shared.taskData = []
        LKProgressHUD.dismiss()
        
      case .failure(let error):
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
      }
    }
  }
  
  func setUp() {
    taskListTable.delegate = self
    taskListTable.dataSource = self
    taskListTable.translatesAutoresizingMaskIntoConstraints = false
    taskListTable.rowHeight = UITableView.automaticDimension
    taskListTable.estimatedRowHeight = 200
  }
  
  func setUpBtn() {
    guard let status = UserManager.shared.currentUserInfo?.status else { return }
    
    if status == 1 {
      postMissionBtn.isHidden = false
      postMissionBtn.setImage(UIImage(named: "wheel-2"), for: .normal)
    } else if status == 2 {
      postMissionBtn.isHidden = true
    } else {
      postMissionBtn.isHidden = false
      postMissionBtn.setImage(UIImage(named: "plus"), for: .normal)
    }
  }
}

extension MissionListViewController: UITableViewDataSource, UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     if UserManager.shared.currentUserInfo?.status != 0 {
      TaskManager.shared.showAlert(title: "任務進行中", message: "請完成當前任務", viewController: self)
     }
  }

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
    self.timeString = TaskManager.shared.timeConverter(time: data.time)
    guard let time = timeString else { return UITableViewCell() }
    let missionText = TaskManager.shared.filterClassified(classified: data.classfied + 1)
    let priceAndTimeInt = [data.money, data.time]
    
    cell.setUp(missionImage: missionText[1], author: data.nickname, missionLabel: missionText[0], priceTimeInt: priceAndTimeInt, time: time)
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    
    let spring = UISpringTimingParameters(dampingRatio: 0.5, initialVelocity: CGVector(dx: 1.0, dy: 0.2))
    let animator = UIViewPropertyAnimator(duration: 1.0, timingParameters: spring)
          cell.alpha = 0
          cell.transform = CGAffineTransform(translationX: 0, y: 100 * 0.6)
          animator.addAnimations {
              cell.alpha = 1
              cell.transform = .identity
            self.taskListTable.layoutIfNeeded()
          }
          animator.startAnimation(afterDelay: 0.3 * Double(indexPath.item))
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == "detail" {
      
      guard let detailVC = segue.destination as? MissionDetailViewController,
           let time = self.timeString else { return }
      detailVC.detailData = detailData
      detailVC.receiveTime = time
    } else if segue.identifier == "startMission"{
      
      guard let detailVC = segue.destination as? StartMissionViewController,
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
    
    self.timeString = TaskManager.shared.timeConverter(time: time)
    
    guard let data = detailData else { return }
    if data.status == 0 {
     self.performSegue(withIdentifier: "detail", sender: nil)
    } else {
      self.performSegue(withIdentifier: "startMission", sender: nil)
    }
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
    
    self.filteredArray = taskDataReturn.filter({ (info) -> Bool in
      
      let nickname = info.nickname
      let isMatch = nickname.localizedCaseInsensitiveContains(searchString)
      return isMatch
    })
    taskListTable.reloadData()
  }
}
