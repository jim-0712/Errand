//
//  MissionDetailViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/30.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Kingfisher
import FirebaseAuth
import Firebase
import CoreLocation

class MissionDetailViewController: UIViewController {
  
  var isRequester = false
  
  var isMissionON = false
  
  var destination = ""
  
  let myLocationManager = CLLocationManager()
  
  let dbF = Firestore.firestore()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if isMissionON {
      missionStackView.isHidden = false
      takeMissionBtn.isHidden = true
      startMissionSetupBtn()
    } else {
      missionStackView.isHidden = true
      takeMissionBtn.isHidden = false
      setUpBtnEnable()
    }
    setUpData()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NotificationCenter.default.post(name: Notification.Name("hide"), object: nil)
  }
  
  func setUpData() {
    guard let userInfo = UserManager.shared.currentUserInfo else {
      backBtn.isHidden = false
      guard let uid = Auth.auth().currentUser?.uid else { return }
      UserManager.shared.readData(uid: uid) { result in
        switch result {
        case .success:
          self.callTaskData()
        case .failure:
          print("error")
        }
      }
      return
    }
    NotificationCenter.default.post(name: Notification.Name("hide"), object: nil)
    
    if userInfo.status == 0 {
      setUpall()
    } else {
      self.callTaskData()
    }
    //    backBtn.isHidden = true
  }
  
  func callTaskData() {
    TaskManager.shared.setUpStatusData { result in
      switch result {
      case .success(let taskInfo):
        self.detailData = taskInfo
        self.receiveTime = TaskManager.shared.timeConverter(time: taskInfo.time)
        self.getPhoto()
        self.setUpall()
        if self.isMissionON {
          self.setUpListener()
        }
        
      case .failure(let error):
        print(error.localizedDescription)
      }
    }
  }
  
  func setUpall() {
    setUp()
    setUpBtn()
    setUppageControll()
    detailTableView.reloadData()
  }
  
  override func viewDidLayoutSubviews() {
    
    super.viewDidLayoutSubviews()
    pageControl.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
  }
  
  @IBOutlet weak var takeMissionBtn: UIButton!
  
  @IBOutlet weak var detailTableView: UITableView!
  
  @IBOutlet weak var backBtn: UIButton!
  
  @IBOutlet weak var missionStackView: UIStackView!
  
  @IBOutlet weak var finishMissionBtn: UIButton!
  
  @IBOutlet weak var giveUpmissionBtn: UIButton!
  
  @IBAction func giveUpmissionAct(_ sender: Any) {
    
    let controller = UIAlertController(title: "您確定要放棄任務？", message: "將會扣您星星評分", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "ok", style: .default) { _ in
      guard var taskInfo = self.detailData,
        let user = UserManager.shared.currentUserInfo  else { return }
      LKProgressHUD.show(controller: self)
      let group = DispatchGroup()
      group.enter()
      group.enter()
      group.enter()
      let taker = taskInfo.missionTaker
      taskInfo.missionTaker = ""
      taskInfo.status = 0
      taskInfo.ownerOK = false
      taskInfo.takerOK = false
      
      //如果是owner要刪除任務並且把雙方的status射程0
      if user.status == 1 {
        
        group.enter()
        self.destination = taker
        TaskManager.shared.deleteTask(uid: user.uid) { result in
          switch result {
          case .success:
            group.leave()
          case .failure:
            group.leave()
          }
        }
        
        UserManager.shared.updateStatus(uid: user.uid, status: 0) { result in
          switch result {
          case .success:
            group.leave()
          case .failure:
            group.leave()
          }
        }
      } else {
        //如果是taker要把任務重置並且把自己的status射程0
        self.destination = taskInfo.uid
        TaskManager.shared.updateWholeTask(task: taskInfo, uid: taskInfo.uid) { result in
          switch result {
          case .success:
            group.leave()
          case .failure:
            group.leave()
          }
        }
      }
      
      UserManager.shared.updateStatus(uid: taker, status: 0) { result in
        switch result {
        case .success:
          group.leave()
        case .failure:
          group.leave()
        }
      }
      
      UserManager.shared.readData(uid: user.uid) { result in
        switch result {
        case .success(var accountInfo):
          accountInfo.totalStar += 5.0
          UserManager.shared.currentUserInfo = accountInfo
          UserManager.shared.updateUserInfo { result in
            switch result {
            case .success:
              group.leave()
            case .failure:
              group.leave()
            }
          }
        case .failure:
          print("error")
        }
      }
      
      group.notify(queue: DispatchQueue.main) {
        let sender = PushNotificationSender()
        sender.sendPushNotification(to: self.destination, body: "對方放棄任務")
      }
    }
    let cancelAct = UIAlertAction(title: "back", style: .cancel, handler: nil)
    controller.addAction(okAction)
    controller.addAction(cancelAct)
    self.present(controller, animated: true, completion: nil)
    
  }
  @IBAction func finishMissionAct(_ sender: Any) {
    
    guard let taskData = self.detailData,
      let status = UserManager.shared.currentUserInfo?.status else { return }
    var owner = ""
    var judgerOwner = ""
    if status == 1 {
      owner = "ownerOK"
      judgerOwner = taskData.missionTaker
    } else {
      owner = "takerOK"
      judgerOwner = taskData.uid
    }
    
    let group = DispatchGroup()
    
    group.enter()
    group.enter()
    
    //  這邊再處理ownerOK 或者 takerOK
    TaskManager.shared.taskUpdateData(uid: taskData.uid, status: true, identity: owner) {(result) in
      switch result {
      case .success:
        group.leave()
      case .failure:
        print("error")
      }
    }
    
    if status == 1 {
      
      guard let userInfo = UserManager.shared.currentUserInfo else { group.leave()
        return }
      
      UserManager.shared.readData(uid: taskData.missionTaker) { result in
        
        switch result {
          
        case .success(let info):
          
          self.destination = info.fcmToken
          UserManager.shared.currentUserInfo = userInfo
          group.leave()
          
        case .failure:
          print("error")
          group.leave()
        }
      }
      
    } else if status == 2 {
      destination = taskData.fcmToken
      group.leave()
    } else { group.leave() }
    
    group.notify(queue: DispatchQueue.main) {
      let sender = PushNotificationSender()
      sender.sendPushNotification(to: self.destination, body: "對方任務完成")
      
      let controller = UIAlertController(title: "恭喜", message: "等待對方完成", preferredStyle: .alert)
      let okAction = UIAlertAction(title: "ok", style: .default) { _ in
        
        guard let judgeVC = self.storyboard?.instantiateViewController(identifier: "judge") as? JudgeMissionViewController,
          let taskInfo = self.detailData else { return }
        
        judgeVC.detailData = taskInfo
        NotificationCenter.default.post(name: Notification.Name("getMissionList"), object: nil)
        self.present(judgeVC, animated: true, completion: nil)
      }
      controller.addAction(okAction)
      self.present(controller, animated: true, completion: nil)
      self.finishMissionBtn.isEnabled = false
      self.finishMissionBtn.backgroundColor = UIColor.LG1
      self.finishMissionBtn.setTitle("等待對方完成", for: .normal)
      self.giveUpmissionBtn.isEnabled = false
    }
  }
  
  @IBAction func backAct(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func takeMissionAct(_ sender: Any) {
    
    LKProgressHUD.show(controller: self)
    
    guard let taskInfo = detailData else { return }
    
    TaskManager.shared.updateTaskRequest(owner: taskInfo.uid) { [weak self ]result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success:
        
        NotificationCenter.default.post(name: Notification.Name("takeMission"), object: nil)
        
        let sender = PushNotificationSender()
        sender.sendPushNotification(to: taskInfo.fcmToken, body: "趕快開啟查看")
        
        strongSelf.setUpBtnEnable()
        LKProgressHUD.dismiss()
        
      case .failure(let error):
        
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
        
      }
    }
    
  }
  var receiveTime: String?
  
  var detailData: TaskInfo?
  
  var reversePhoto = ""
  
  var arrangementPhoto: [String] = []
  
  var arrangementVideo: [String] = []
  
  let missionDetail = ["任務內容", "懸賞價格", "發布時間", "任務細節"]
  
  let pageControl = UIPageControl()
  
  let fullSize = UIScreen.main.bounds.size
  
  func setUp() {
    testcollection.delegate = self
    testcollection.dataSource = self
    detailTableView.delegate = self
    detailTableView.dataSource = self
    detailTableView.rowHeight = UITableView.automaticDimension
    detailTableView.register(UINib(nibName: "StartMissionTableViewCell", bundle: nil), forCellReuseIdentifier: "startMission")
    testcollection.register(UINib(nibName: "MissionDetailCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "detail")
    headerView.addSubview(testcollection)
    detailTableView.tableHeaderView = headerView
    
  }
    
  var testcollection :UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    let collection = UICollectionView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300), collectionViewLayout: layout)
    layout.scrollDirection = .horizontal
    collection.translatesAutoresizingMaskIntoConstraints = false
    collection.showsVerticalScrollIndicator = false
    collection.showsHorizontalScrollIndicator = false
    collection.register(MissionDetailCollectionViewCell.self, forCellWithReuseIdentifier: "detail")
    collection.backgroundColor = .red
    return collection
  }()
  
  let headerView: UIView = {
    let header = UIView()
    header.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300)
    header.backgroundColor = .pink
    return header
  }()
  
  // swiftlint:disable cyclomatic_complexity
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
            
            strongSelf.finishMissionAlert(title: "恭喜", message: "任務完成", viewController: strongSelf)
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
  // swiftlint:enable cyclomatic_complexity
  func finishMissionAlert(title: String, message: String, viewController: UIViewController) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "ok", style: .default) { [weak self]_ in
      NotificationCenter.default.post(name: Notification.Name("finishTask"), object: nil)
      guard let strongSelf = self else { return }
      guard let task = strongSelf.detailData,
        let  currentUserStatus = UserManager.shared.currentUserInfo?.status else { return }
      
      LKProgressHUD.show(controller: strongSelf)
      
      let group = DispatchGroup()
      group.enter()
      group.enter()
      group.enter()
      group.enter()
      TaskManager.shared.taskUpdateData(uid: task.uid, status: true, identity: "isComplete") { (result) in
        switch result {
        case .success:
          group.leave()
        case .failure:
          print("error")
        }
      }
      
      UserManager.shared.updateStatus(uid: task.uid, status: 0) { result in
        switch result {
        case .success:
          group.leave()
        case .failure:
          print("no")
          group.leave()
        }
      }
      
      UserManager.shared.updateStatus(uid: task.missionTaker, status: 0) { result in
        switch result {
        case .success:
          group.leave()
        case .failure:
          print("no")
          group.leave()
        }
      }
      
      if currentUserStatus == 1 {
        
        guard let userInfo = UserManager.shared.currentUserInfo else { group.leave()
          return }
        
        UserManager.shared.readData(uid: task.missionTaker) { result in
          
          switch result {
            
          case .success(let info):
            
            strongSelf.destination = info.fcmToken
            UserManager.shared.currentUserInfo = userInfo
            group.leave()
            
          case .failure:
            print("error")
            group.leave()
          }
        }
        
      } else if currentUserStatus == 2 {
        strongSelf.destination = task.fcmToken
        group.leave()
      } else {  group.leave() }
      
      group.notify(queue: DispatchQueue.main) {
        
        let sender = PushNotificationSender()
        sender.sendPushNotification(to: strongSelf.destination, body: "對方任務完成")
        LKProgressHUD.dismiss()
        
        guard let judgeVC = strongSelf.storyboard?.instantiateViewController(identifier: "judge") as? JudgeMissionViewController,
          let taskInfo = strongSelf.detailData else { return }
        
        judgeVC.detailData = taskInfo
        NotificationCenter.default.post(name: Notification.Name("getMissionList"), object: nil)
        strongSelf.present(judgeVC, animated: true, completion: nil)
        
      }
    }
    
    controller.addAction(okAction)
    viewController.present(controller, animated: true, completion: nil)
  }
  
  func startMissionSetupBtn() {
    
    guard let task = detailData,
      let status = UserManager.shared.currentUserInfo?.status else { return }
    
    if status == 1 && task.ownerOK {
      finishMissionBtn.isEnabled = false
      finishMissionBtn.backgroundColor = UIColor.LG1
      giveUpmissionBtn.isEnabled = false
      giveUpmissionBtn.setTitle("已經完成", for: .normal)
      finishMissionBtn.setTitle("等待對方完成", for: .normal)
    } else if status == 2 && task.takerOK {
      finishMissionBtn.isEnabled = false
      finishMissionBtn.backgroundColor = UIColor.LG1
      giveUpmissionBtn.isEnabled = false
      giveUpmissionBtn.setTitle("已經完成", for: .normal)
      finishMissionBtn.setTitle("等待對方完成", for: .normal)
    } else {
      finishMissionBtn.isEnabled = true
      giveUpmissionBtn.isEnabled = true
      finishMissionBtn.backgroundColor = UIColor.Y1
      giveUpmissionBtn.setTitle("放棄任務", for: .normal)
      finishMissionBtn.setTitle("提交任務", for: .normal)
    }
  }
  
  func setUpBtnEnable() {
    
    guard let user = UserManager.shared.currentUserInfo?.status else { return }
    let state = UserManager.shared.checkDetailBtn
    
    if user == 1 && state || user == 2 && state {
      
      takeMissionBtn.backgroundColor = .lightGray
      takeMissionBtn.setTitle("任務進行中", for: .normal)
      takeMissionBtn.tintColor = .black
      takeMissionBtn.isEnabled = false
      
    } else if user == 1 && !state || user == 2 && !state {
      
      takeMissionBtn.backgroundColor = .lightGray
      takeMissionBtn.setTitle("請先完成當前任務", for: .normal)
      takeMissionBtn.tintColor = .black
      takeMissionBtn.isEnabled = false
    } else {
      takeMissionBtn.backgroundColor = UIColor(red: 246.0/255.0, green: 212/255.0, blue: 95/255.0, alpha: 1.0)
      takeMissionBtn.setTitle("接受任務", for: .normal)
      takeMissionBtn.tintColor = .black
      takeMissionBtn.isEnabled = true
      
    }
  }
  
  func setUpBtn() {
    setUpBtnEnable()
    takeMissionBtn.layer.shadowOpacity = 0.5
    finishMissionBtn.layer.shadowOpacity = 0.5
    giveUpmissionBtn.layer.shadowOpacity = 0.5
    backBtn.layer.cornerRadius = backBtn.bounds.height / 2
    takeMissionBtn.layer.shadowOffset = .zero
    finishMissionBtn.layer.shadowOffset = .zero
    giveUpmissionBtn.layer.shadowOffset = .zero
    takeMissionBtn.layer.cornerRadius = takeMissionBtn.bounds.height / 5
    finishMissionBtn.layer.cornerRadius = takeMissionBtn.bounds.height / 5
    giveUpmissionBtn.layer.cornerRadius = takeMissionBtn.bounds.height / 5
  }
  
  func setUppageControll() {
    
    guard let data = detailData else { return }
    self.headerView.addSubview(pageControl)
    pageControl.translatesAutoresizingMaskIntoConstraints = false
    pageControl.currentPage = 0
    pageControl.layer.cornerRadius = 10
    pageControl.pageIndicatorTintColor = .lightGray
    pageControl.numberOfPages = data.taskPhoto.count
    pageControl.currentPageIndicatorTintColor = .black
    pageControl.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
    NSLayoutConstraint.activate([
      pageControl.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: 0),
      pageControl.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0),
      pageControl.heightAnchor.constraint(equalToConstant: 30),
      pageControl.widthAnchor.constraint(equalToConstant: 100)
    ])
  }
  
  func getPhoto() {
    guard let status = UserManager.shared.currentUserInfo?.status,
      let taskinfo = detailData,
      let accountCurrent = UserManager.shared.currentUserInfo else { return }
    if status == 1 {
      UserManager.shared.readData(uid: taskinfo.missionTaker) { result in
        switch result {
        case .success(let accountInfo):
          self.reversePhoto = accountInfo.photo
          UserManager.shared.currentUserInfo = accountCurrent
        case .failure:
          print("error")
        }
      }
    } else if status == 2 {
      UserManager.shared.readData(uid: taskinfo.uid) { result in
        switch result {
        case .success(let accountInfo):
          self.reversePhoto = accountInfo.photo
          UserManager.shared.currentUserInfo = accountCurrent
        case .failure:
          print("error")
        }
      }
    }
  }
  
  @objc func videoPlay(sender: UIButton) {
    guard let layer = sender.superview?.layer as? AVPlayerLayer else { return }
    layer.player?.play()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == "chat" {
      guard let chatVC = segue.destination as? ChatViewController,
        let taskInfo = detailData else { return }
      chatVC.detailData = taskInfo
      chatVC.receiverPhoto = reversePhoto
    }
  }
}

extension MissionDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let offSet = scrollView.contentOffset.x
    let width = scrollView.frame.width
    let horizontalCenter = width / 2
    pageControl.currentPage = Int(offSet + horizontalCenter) / Int(width)
    
    testcollection.alpha = 1 - scrollView.bounds.origin.y / 300
    
    if scrollView.bounds.origin.y < 0 {
      print("2")
    }
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    guard let data = detailData else { return 0 }
    return data.taskPhoto.count
  }
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "detail", for: indexPath) as? MissionDetailCollectionViewCell,
      let data = detailData else { return UICollectionViewCell() }
    
    let typeManager = data.taskPhoto[indexPath.row].components(separatedBy: "mov")
    
    if typeManager.count > 1 {
      
      cell.detailImage.isHidden = true
      guard let video = URL(string: data.taskPhoto[indexPath.row]) else { return UICollectionViewCell() }
      let player = AVPlayer(url: video)
      let playerLayer = AVPlayerLayer(player: player)
      playerLayer.frame = cell.contentView.bounds
      cell.layer.addSublayer(playerLayer)
      
    } else {
      
      cell.detailImage.isHidden = false
      guard let layers = cell.layer.sublayers else { return UICollectionViewCell() }
      for layer in layers {
        if let avPlayerLayer = layer as? AVPlayerLayer {
          avPlayerLayer.removeFromSuperlayer()
        }
      }
      cell.detailImage.loadImage(data.taskPhoto[indexPath.row])
      cell.detailImage.contentMode = .scaleAspectFill
    }
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
}

extension MissionDetailViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    return CGSize(width: UIScreen.main.bounds.width, height: 300)
  }
}

extension MissionDetailViewController: UITableViewDelegate, UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 4
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let data = detailData,
      let time = self.receiveTime else { return UITableViewCell() }
    
    if indexPath.row == 0 {
      
      if !isMissionON {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "person", for: indexPath) as? MissionPersonTableViewCell else { return UITableViewCell() }
        
        cell.setUp(personURL: data.personPhoto, name: data.nickname)
        
        return cell
        
      } else {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "startMission", for: indexPath) as? StartMissionTableViewCell,
          let taskData = detailData,
          let status = UserManager.shared.currentUserInfo?.status else { return UITableViewCell() }
        
        let classified = TaskManager.shared.filterClassified(classified: taskData.classfied + 1)
        
        cell.setUp(ownerImage: taskData.personPhoto, author: taskData.nickname, classified: classified[0], price: taskData.money)
        
        cell.tapReprt = {
          
          let alert = UIAlertController(title: "檢舉系統", message: "請選擇要做的行動", preferredStyle: .actionSheet)
          
          let report = UIAlertAction(title: "檢舉", style: .default) { _ in
            LKProgressHUD.showSuccess(text: "系統已到您的通知", controller: self)
          }
          let blackList = UIAlertAction(title: "加入黑名單", style: .default) { [weak self] _ in
            
            guard let strongSelf = self else { return }
            guard var userInfo = UserManager.shared.currentUserInfo,
              let taskInfo = strongSelf.detailData else { return }
            
            LKProgressHUD.show(controller: strongSelf)
            
            if userInfo.status == 1 {
              userInfo.blacklist.append(taskInfo.missionTaker)
            } else {
              userInfo.blacklist.append(taskInfo.uid)
            }
            UserManager.shared.currentUserInfo = userInfo
            
            UserManager.shared.updateUserInfo { result in
              
              switch result {
              case .success:
                print("yes")
                LKProgressHUD.dismiss()
              case .failure:
                print("no")
              }
            }
          }
          
          let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
          alert.addAction(report)
          alert.addAction(blackList)
          alert.addAction(cancelAction)
          
          self.present(alert, animated: true, completion: nil)
        }
        
        cell.tapOnButton = {
          
          self.performSegue(withIdentifier: "chat", sender: nil)
        }
        
        cell.tapOnNavi = {
          guard let originalLocation = self.myLocationManager.location?.coordinate,
            let taskInfo = self.detailData else { return }
          
          let originCor = "\(originalLocation.latitude),\(originalLocation.longitude)"
          let destination = "\(taskInfo.lat),\(taskInfo.long)"
          
          let url = URL(string: "comgooglemaps://?saddr=\(originCor)&daddr=\(destination)&directionsmode=driving")
          
          if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
          } else {
            // 若手機沒安裝 Google Map App 則導到 App Store(id443904275 為 Google Map App 的 ID)
            let appStoreGoogleMapURL = URL(string: "itms-apps://itunes.apple.com/app/id585027354")!
            UIApplication.shared.open(appStoreGoogleMapURL, options: [:], completionHandler: nil)
          }
        }
        
        cell.backgroundColor = .clear
        return cell
      }
      
    } else if indexPath.row != 3 {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "missionDetail", for: indexPath) as? MissionDetailTableViewCell else { return UITableViewCell() }
      
      switch indexPath.row {
        
      case 1:
        cell.setUp(title: missionDetail[indexPath.row], content: "\(data.money)")
        
      default:
        cell.setUp(title: "\(missionDetail[indexPath.row])", content: time)
      }
      
      return cell
      
    } else {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "content", for: indexPath) as? MissionContentTableViewCell else { return UITableViewCell() }
      
      cell.setUp(title: missionDetail[3], content: data.detail)
      
      return cell
    }
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    
    if isMissionON && indexPath.row == 0 {
      return 170
    } else if indexPath.row == 0 {
      return 90
    } else {
      return 60
    }
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    let spring = UISpringTimingParameters(dampingRatio: 0.5, initialVelocity: CGVector(dx: 1.0, dy: 0.2))
    let animator = UIViewPropertyAnimator(duration: 1.0, timingParameters: spring)
          cell.alpha = 0
          cell.transform = CGAffineTransform(translationX: 0, y: 100 * 0.6)
          animator.addAnimations {
              cell.alpha = 1
              cell.transform = .identity
            self.detailTableView.layoutIfNeeded()
          }
          animator.startAnimation(afterDelay: 0.1 * Double(indexPath.item))
  }
}
