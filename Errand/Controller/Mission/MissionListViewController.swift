//
//  PostTaskViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/16.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import FirebaseAuth

class MissionListViewController: UIViewController, UIViewControllerTransitioningDelegate {
  
  var observation: NSKeyValueObservation?
  
  override func viewDidLoad() {
    super.viewDidLoad()

    setUpSearch()
    setUp()
    setUpindicatorView()
    searchingLabel.isHidden = true
    getTaskData()
    
    observation = UserManager.shared.observe(\.isChange) { [weak self] (_, _) in
      guard let strongSelf = self else { return }
      strongSelf.getTaskData()
    }
    NotificationCenter.default.addObserver(self, selector: #selector(reloadTable), name: Notification.Name("getMissionList"), object: nil)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    currentBtnSelect = false
    getTaskData()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    currentBtnSelect = false
    setUpBtn()
    startBtnAnimate(sender: allMissionBtn)
  }
  
  @IBOutlet weak var searchingLabel: UILabel!
  
  @IBOutlet weak var allMissionBtn: UIButton!
  
  @IBOutlet weak var currentBtn: UIButton!
  
  @IBOutlet weak var btnStackView: UIStackView!
  
  @IBAction func allMissionAct(_ sender: UIButton) {
    currentBtnSelect = false
    preventTap()
    getTaskData()
    UserManager.shared.checkDetailBtn = !UserManager.shared.checkDetailBtn
    startBtnAnimate(sender: sender)
  }
  
  @IBAction func currentMission(_ sender: UIButton) {
    startBtnAnimate(sender: sender)
    currentBtnSelect = true
    UserManager.shared.checkDetailBtn = !UserManager.shared.checkDetailBtn
    if UserManager.shared.currentUserInfo?.status == 0 {
      
    } else {
      preventTap()
    }
    getMissionStartData()
  }
  
  @IBOutlet weak var taskListTable: UITableView!
  
  @IBOutlet weak var postMissionBtn: UIButton!
  
  let circleAnimation = CircularTransition()
  
  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    
    circleAnimation.transitionMode = .dismiss
    
    circleAnimation.startingPoint = CGPoint(x: 0, y: 0)
    
    circleAnimation.circleColor = .lightGray
    
    return circleAnimation
  }
  
  func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    
    circleAnimation.transitionMode = .present
    
    circleAnimation.circleColor = .lightGray
    
    circleAnimation.startingPoint = postMissionBtn.center

    return circleAnimation
  }
  
  @IBAction func postMissionBtn(_ sender: Any) {
    
    if UserManager.shared.isTourist {
      
      UserManager.shared.goSignInPage(viewController: self)
      
    } else if UserManager.shared.currentUserInfo?.status == 0 {
      
      performSegue(withIdentifier: "post", sender: nil)
    } else if UserManager.shared.currentUserInfo?.status == 1 {
      
      TaskManager.shared.setUpStatusData { result in
        
        switch result {
        case .success(let taskInfo):
          
          if taskInfo.missionTaker != "" {
            TaskManager.shared.showAlert(title: "警告", message: "任務已被接受，不能隨意更改", viewController: self)
          } else {
            guard let editVC = self.storyboard?.instantiateViewController(withIdentifier: "post") as? PostMissionViewController,
              let status = UserManager.shared.currentUserInfo?.status else { return }
            if status == 1 {
              editVC.isEditing = true
            } else {
              editVC.isEditing = false
            }
            
            editVC.transitioningDelegate = self
            editVC.modalPresentationStyle = .custom
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
  
  var indicatorCon: NSLayoutConstraint?
  
  let indicatorView = UIView()
  
  var refreshControl: UIRefreshControl!
  
  let taskMan = TaskManager.shared
  
  var detailData: TaskInfo?
  
  var containerrTask: TaskInfo?
  
  var timeString: String?
  
  var currentBtnSelect = false
  
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
          LKProgressHUD.dismiss()
          self.refreshControl.endRefreshing()
        }
        self.taskListTable.reloadData()
      } else {
        DispatchQueue.main.async {
          self.postMissionBtn.isHidden = false
          self.refreshControl.endRefreshing()
          self.taskListTable.reloadData()
          LKProgressHUD.dismiss()
          guard let status = UserManager.shared.currentUserInfo?.status else { return }
          if status == 0 || status == 1 {
            self.postMissionBtn.isHidden = false
          } else {
            self.postMissionBtn.isHidden = true
          }
        }
      }
    }
  }
  
  var filteredArray = [TaskInfo]() {
    
    didSet {
      if taskDataReturn.isEmpty {
        self.postMissionBtn.isHidden = true
        LKProgressHUD.dismiss()
      } else {
        DispatchQueue.main.async {
          self.postMissionBtn.isHidden = false
          self.taskListTable.reloadData()
          LKProgressHUD.dismiss()
        }
      }
    }
  }
  
  @objc func reloadTable() {
    if currentBtnSelect {
      getMissionStartData()
    } else {
      getTaskData()
    }
  }
  
  func preventTap() {
    guard let tabVC = self.view.window?.rootViewController as? TabBarViewController else { return }
    LKProgressHUD.show(controller: tabVC)
  }
  
  func getMissionStartData() {
    
    guard let user = UserManager.shared.currentUserInfo else {
      LKProgressHUD.dismiss()
      SwiftMes.shared.showWarningMessage(body: "當前沒有登入", seconds: 1.0)
      taskDataReturn = []
      return }
    
    guard let uid = UserManager.shared.currentUserInfo?.uid else { return }
    
    if user.status == 1 {
      
      readCurrentUserTaskData(parameter: "uid", uid: uid)
      
    } else if user.status == 2 {
      
      readCurrentUserTaskData(parameter: "missionTaker", uid: uid)
      
    } else {
      LKProgressHUD.dismiss()
      SwiftMes.shared.showErrorMessage(body: "當前沒有任務", seconds: 1.0)
      taskDataReturn = []
      return
    }
  }
  
  func readCurrentUserTaskData(parameter: String, uid: String) {
    taskMan.readSpecificData(parameter: parameter, parameterString: uid) { [weak self](result) in
      guard let strongSelf = self else { return }
      switch result {
        
      case .success(let dataReturn):
        
        strongSelf.taskDataReturn = dataReturn
        
      case .failure(let error):
        LKProgressHUD.dismiss()
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
      }
    }
  }
  
  func startBtnAnimate(sender: UIButton) {
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
        
        if UserManager.shared.isTourist {
          
          strongSelf.taskDataReturn = taskData
          
        } else {
          guard let userinfo = UserManager.shared.currentUserInfo else { return }
          
          let filterData = taskData.filter { taskInfo in
            var isMatch = false
            for badMan in userinfo.blacklist where badMan == taskInfo.uid {
               isMatch =  true
            }
            
            for oppoBadman in userinfo.oppoBlacklist where oppoBadman == taskInfo.uid {
               isMatch = true
            }
            if isMatch { return false } else { return true}
          }
          
          strongSelf.taskDataReturn = filterData
          strongSelf.postMissionBtn.isHidden = false
          TaskManager.shared.taskData = []
          LKProgressHUD.dismiss()
        }
        
      case .failure(let error):
        LKProgressHUD.dismiss()
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
      self.containerrTask = filteredArray[indexPath.row]
    } else {
      self.containerrTask = taskDataReturn[indexPath.row]
    }
    
    guard let data = self.containerrTask else { return UITableViewCell() }
    self.timeString = TaskManager.shared.timeConverter(time: data.time)
    guard let time = timeString else { return UITableViewCell() }
    let missionText = TaskManager.shared.filterClassified(classified: data.classfied + 1)
    let priceAndTimeInt = [data.money, data.time]
    
    cell.setUp(missionImage: missionText[1], author: data.nickname, missionLabel: missionText[0], priceTimeInt: priceAndTimeInt, time: time)
    
    cell.uid = data.uid
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    
    let spring = UISpringTimingParameters(dampingRatio: 0.6, initialVelocity: CGVector(dx: 1.0, dy: 0.2))
    let animator = UIViewPropertyAnimator(duration: 0.8, timingParameters: spring)
    cell.alpha = 0
    cell.transform = CGAffineTransform(translationX: 0, y: 100 * 0.6)
    animator.addAnimations {
      cell.alpha = 1
      cell.transform = .identity
      self.taskListTable.layoutIfNeeded()
    }
    animator.startAnimation(afterDelay: 0.1 * Double(indexPath.item))
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
  
  func detailData(tableViewCell: ListTableViewCell, uid: String, time: Int) {
    
    for count in 0 ..< taskDataReturn.count {
      if taskDataReturn[count].time == time && taskDataReturn[count].uid == uid {
        self.detailData = taskDataReturn[count]
        break
      }
    }
    
    self.timeString = TaskManager.shared.timeConverter(time: time)
    self.performSegue(withIdentifier: "detail", sender: nil)
  }
}

extension MissionListViewController: UISearchBarDelegate {
  
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    shouldShowSearchResults = true
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchingLabel.isHidden = true
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
    
    searchingLabel.isHidden = true
    
    self.filteredArray = taskDataReturn.filter({ (info) -> Bool in
      
      let nickname = info.nickname
      let isMatch = nickname.localizedCaseInsensitiveContains(searchString)
      return isMatch
    })
    
    if filteredArray.isEmpty && shouldShowSearchResults {
      searchingLabel.isHidden = false
    } else {
      searchingLabel.isHidden = true
      taskListTable.reloadData()
    }
  }
}
