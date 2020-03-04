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
  
  var category: [CellContent] = [CellContent(type: .miniPhoto, title: "大頭貼"),
                            CellContent(type: .normal, title: "懸賞價格"),
                            CellContent(type: .normal, title: "發布時間"),
                            CellContent(type: .purpose, title: "任務細節") ]
  
  var isRequester = false
  
  var isMissionON = false
  
  var alreadyReport = false
  
  var destination = ""
  
  var reverse = ""
  
  let myLocationManager = CLLocationManager()
  
  var plaverLooper: AVPlayerLooper?
  
  var isNavi = false
  
  var receiveTime: String?
  
  var detailData: TaskInfo?
  
  var reversePhoto = ""
  
  var arrangementPhoto: [String] = []
  
  var arrangementVideo: [String] = []
  
  let pageControl = UIPageControl()
  
  let fullSize = UIScreen.main.bounds.size
  
  let dbF = Firestore.firestore()
  
  lazy var testcollection: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    let collection = UICollectionView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300), collectionViewLayout: layout)
    layout.scrollDirection = .horizontal
    collection.translatesAutoresizingMaskIntoConstraints = false
    collection.showsVerticalScrollIndicator = false
    collection.showsHorizontalScrollIndicator = false
    return collection
  }()
  
  let headerView: UIView = {
    let header = UIView()
    header.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300)
    header.backgroundColor = .pink
    return header
  }()
  
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
    
    if isNavi {
      backBtn.isHidden = false
    } else {
      backBtn.isHidden = true
    }
    navigationItem.setHidesBackButton(true, animated: true)
    navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Icons_24px_Back02"), style: .plain, target: self, action: #selector(backToList))
    navigationItem.leftBarButtonItem?.tintColor = .black
    
    guard detailData != nil else {
      setUpData()
      return }
    guard let status = UserManager.shared.currentUserInfo?.status else {
      setUpData()
      return }
    UserManager.shared.statusJudge = status
    getPhoto()
    setUpall()
    setUpListener()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.setToolbarHidden(true, animated: true)
    NotificationCenter.default.post(name: Notification.Name("hide"), object: nil)
  }
  
  @objc func backToList() {
    self.navigationController?.popViewController(animated: true)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    guard let taskData = detailData else { return }
    
    if taskData.ownerOK && taskData.takerOK {
      changeStatus()
    }
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
    
    let controller = UIAlertController(title: "您確定要放棄任務？", message: "將會扣您星星總評分1分", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "ok", style: .default) { [weak self]_ in
      guard let strongSelf = self,
           let user = UserManager.shared.currentUserInfo,
           var taskInfo = strongSelf.detailData else { return }
      LKProgressHUD.show(controller: strongSelf)
      let group = DispatchGroup()
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
        strongSelf.destination = taker
        TaskManager.shared.deleteTask(uid: user.uid) { result in
          switch result {
          case .success:
            group.leave()
          case .failure:
            group.leave()
          }
        }
        
        group.enter()
        strongSelf.readUserInfo(uid: taker, isSelf: false) { accountInfo in
          guard let account = accountInfo else { return }
          strongSelf.destination = account.fcmToken
          group.leave()
        }

        
        strongSelf.updateStatus(uid: user.uid, status: 0) {
          group.leave()
        }
        
        strongSelf.updateStatus(uid: taker, status: 0) {
          group.leave()
        }
        
      } else {
        //如果是taker要把任務重置並且把自己的status射程0
        strongSelf.destination = taskInfo.fcmToken
        TaskManager.shared.updateWholeTask(task: taskInfo, uid: taskInfo.uid) { result in
          switch result {
          case .success:
            group.leave()
          case .failure:
            group.leave()
          }
        }
        
        strongSelf.updateStatus(uid: taker, status: 0) {
          group.leave()
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
                print("Ya")
              case .failure:
                print("error")
              }
            }
            
          case .failure:
            print("error")
          }
        }
        
        let sender = PushNotificationSender()
        sender.sendPushNotification(to: strongSelf.destination, body: "對方放棄任務")
        LKProgressHUD.dismiss()
        let mapView = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab")
        strongSelf.view.window?.rootViewController = mapView
      }
    }
    let cancelAct = UIAlertAction(title: "back", style: .cancel, handler: nil)
    controller.addAction(okAction)
    controller.addAction(cancelAct)
    self.present(controller, animated: true, completion: nil)
    
  }
  @IBAction func finishMissionAct(_ sender: Any) {
    
 guard var taskData = self.detailData,
      let status = UserManager.shared.currentUserInfo?.status else { return }
    var owner = ""
    if status == 1 {
      owner = "ownerOK"
      taskData.ownerOK = true
    } else {
      owner = "takerOK"
      taskData.takerOK = true
    }
    
    let group = DispatchGroup()
    
    //  這邊再處理ownerOK 或者 takerOK
    group.enter()
    updateTaskData(uid: taskData.uid, status: true, identity: owner) {
      group.leave()
    }

    if status == 1 {
      group.enter()
      readUserInfo(uid: taskData.missionTaker, isSelf: false) { [weak self] accountInfo in
        guard let account = accountInfo,
             let strongSelf = self else { return }
        strongSelf.destination = account.fcmToken
        group.leave()
      }
      
    } else if status == 2 {
      group.enter()
      destination = taskData.fcmToken
      group.leave()
    } else { group.leave() }
    
    group.notify(queue: DispatchQueue.main) {
      
      guard let task = self.detailData else { return }
      if task.ownerOK && task.takerOK {
        self.finishMissionAlert(title: "恭喜", message: "任務完成", viewController: self)
      } else {
        let sender = PushNotificationSender()
        sender.sendPushNotification(to: self.destination, body: "對方任務完成")
        
        let controller = UIAlertController(title: "恭喜", message: "等待對方完成", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "ok", style: .default) { [weak self] _ in
          guard let strongSelf = self else { return }
          
          guard let judgeVC = strongSelf.storyboard?.instantiateViewController(identifier: "judge") as? JudgeMissionViewController,
            let taskInfo = strongSelf.detailData  else { return }
          
          judgeVC.detailData = taskInfo
          NotificationCenter.default.post(name: Notification.Name("getMissionList"), object: nil)
          strongSelf.present(judgeVC, animated: true, completion: nil)
        }
        controller.addAction(okAction)
        self.present(controller, animated: true, completion: nil)
        self.finishMissionBtn.isEnabled = false
        self.finishMissionBtn.backgroundColor = UIColor.LG1
        self.finishMissionBtn.setTitle("等待對方完成", for: .normal)
        self.giveUpmissionBtn.isEnabled = false
      }
    }
  }
  
  @IBAction func backAct(_ sender: Any) {
    NotificationCenter.default.post(name: Notification.Name("hide"), object: nil)
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func takeMissionAct(_ sender: Any) {
    
    LKProgressHUD.show(controller: self)
    
    guard let taskInfo = detailData else { return }
    
    TaskManager.shared.updateTaskRequest(owner: taskInfo.uid) { [weak self ]result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success:
        
        let sender = PushNotificationSender()
        sender.sendPushNotification(to: taskInfo.fcmToken, body: "有人申請任務")
        strongSelf.setUpBtnEnable()
        
        let controller = UIAlertController(title: "恭喜", message: "您已申請", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "ok", style: .default) { (_) in
          self?.navigationController?.popViewController(animated: true)
        }
        controller.addAction(okAction)
        strongSelf.present(controller, animated: true, completion: nil)
        
        LKProgressHUD.dismiss()
        
      case .failure(let error):
        
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
        
      }
    }
  }
  
  func setUpData() {
    
    if UserManager.shared.isTourist {
      missionStackView.isHidden = true
      setUpall()
      
    } else {
      guard let userInfo = UserManager.shared.currentUserInfo else {
        backBtn.isHidden = false
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        readUserInfo(uid: uid, isSelf: true) { [weak self] _ in
          guard let strongSelf = self else { return }
         if Auth.auth().currentUser == nil {
           SwiftMes.shared.showWarningMessage(body: "請先登入", seconds: 1.0)
           DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
             let signInVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "main") as? ViewController
             
             UserManager.shared.isTourist = true
             UserDefaults.standard.removeObject(forKey: "login")
             strongSelf.view.window?.rootViewController = signInVC
           }
         }
         
         guard let status = UserManager.shared.currentUserInfo?.status else { return }
         
         if status == 0 {
           SwiftMes.shared.showSuccessMessage(body: "該任務已經完成", seconds: 1.0)
           DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
             let mapView = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab")
             strongSelf.view.window?.rootViewController = mapView
           }
         } else {
           UserManager.shared.statusJudge = status
           strongSelf.callTaskData()
         }
        }
        return
      }
      
      NotificationCenter.default.post(name: Notification.Name("hide"), object: nil)
      
      if userInfo.status == 0 {
        setUpall()
      } else {
        UserManager.shared.statusJudge = userInfo.status
        self.callTaskData()
      }
    }
  }
  
  func callTaskData() {
    TaskManager.shared.setUpStatusData { [weak self] result in
      guard let strongSelf = self else { return }
      switch result {
      case .success(let taskInfo):
        strongSelf.detailData = taskInfo
        strongSelf.receiveTime = TaskManager.shared.timeConverter(time: taskInfo.time)
        strongSelf.getPhoto()
        strongSelf.setUpall()
        if strongSelf.isMissionON {
          strongSelf.setUpListener()
        }
        
      case .failure(let error):
        let handler = error.localizedDescription.components(separatedBy: "MissionError")
        
        if handler.count > 1 {
          
          let alert = UIAlertController(title: "注意", message: "本次任務已完成", preferredStyle: .alert)
          let okAction = UIAlertAction(title: "ok", style: .default) { _ in
            let mapView = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(identifier: "tab")
            
            strongSelf.view.window?.rootViewController = mapView
          }
          alert.addAction(okAction)
          strongSelf.present(alert, animated: true, completion: nil)
          
        } else {
          print(error.localizedDescription)
        }
      }
    }
  }
  
  func readUserInfo(uid: String, isSelf: Bool, completion: @escaping ((AccountInfo?) -> Void )) {
    UserManager.shared.readUserInfo(uid: uid, isSelf: isSelf) { result in
      switch result {
      case .success(let takerAccount):
        
        completion(takerAccount)

      case .failure:
        completion(nil)
      }
    }
  }
  
  func updateStatus(uid: String, status: Int, completion: @escaping (() -> Void)) {
    UserManager.shared.updateStatus(uid: uid, status: status) { result in
      switch result {
      case .success:
        completion()
      case .failure:
        completion()
      }
    }
  }
  
  func updateTaskData(uid: String, status: Bool, identity: String, completion: @escaping (() -> Void)) {
    TaskManager.shared.taskUpdateData(uid: uid, status: status, identity: identity) { (result) in
      switch result {
      case .success:
        print("1")
        completion()
      case .failure:
        print("2")
        completion()
      }
    }
  }
  
  func setUpall() {
    setUp()
    setUpBtn()
    setUppageControll()
    detailTableView.reloadData()
  }
  
  func setUp() {
    testcollection.delegate = self
    testcollection.dataSource = self
    detailTableView.delegate = self
    detailTableView.dataSource = self
    testcollection.isPagingEnabled = true
    detailTableView.rowHeight = UITableView.automaticDimension
    detailTableView.register(UINib(nibName: "StartMissionTableViewCell", bundle: nil), forCellReuseIdentifier: "startMission")
    testcollection.register(UINib(nibName: "MissionDetailCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "detail")
    headerView.addSubview(testcollection)
    detailTableView.tableHeaderView = headerView
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
          
//          guard let taskData = strongSelf.detailData else { return }
          
//          if taskData.takerOK && taskData.ownerOK {
//            strongSelf.finishMissionAlert(title: "恭喜", message: "任務完成", viewController: strongSelf)
//          }
          
        case .failure:
          print("error")
        }
      }
    }
  }
  
  func changeStatus() {
    
    guard let task = detailData else { return }
    
    LKProgressHUD.show(controller: self)
    
    let group = DispatchGroup()
    group.enter()
    updateTaskData(uid: task.uid, status: true, identity: "isComplete") {
      group.leave()
    }
    
    group.enter()
    updateStatus(uid: task.uid, status: 0) {
      group.leave()
    }
    
    group.enter()
    updateStatus(uid: task.missionTaker, status: 0) {
      group.leave()
    }

    group.notify(queue: DispatchQueue.main) {
      LKProgressHUD.dismiss()
    }
  }
  
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
      strongSelf.updateTaskData(uid: task.uid, status: true, identity: "isComplete") {
        group.leave()
      }

      strongSelf.updateStatus(uid: task.uid, status: 0) {
        group.leave()
      }

      strongSelf.updateStatus(uid: task.missionTaker, status: 0) {
        group.leave()
      }
  
      if currentUserStatus == 1 {
        group.enter()
        
        strongSelf.readUserInfo(uid: task.missionTaker, isSelf: false) { accountInfo in
          guard let account = accountInfo else { return }
          strongSelf.destination = account.fcmToken
          group.leave()
        }
        
      } else if currentUserStatus == 2 {
        group.enter()
        strongSelf.destination = task.fcmToken
        group.leave()
      } else {  group.leave() }
      
      group.notify(queue: DispatchQueue.main) {
        
        let sender = PushNotificationSender()
        sender.sendPushNotification(to: strongSelf.destination, body: "任務完成")
        LKProgressHUD.dismiss()
        
        guard let judgeVC = strongSelf.storyboard?.instantiateViewController(identifier: "judge") as? JudgeMissionViewController,
          let taskInfo = strongSelf.detailData else { return }
        
        judgeVC.detailData = taskInfo
        NotificationCenter.default.post(name: Notification.Name("getMissionList"), object: nil)
        NotificationCenter.default.post(name: Notification.Name("hideMes"), object: nil)
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
    
    if UserManager.shared.isTourist {
      takeMissionBtn.isHidden = false
      takeMissionBtn.backgroundColor = .lightGray
      takeMissionBtn.setTitle("請先登入", for: .normal)
      takeMissionBtn.tintColor = .black
      takeMissionBtn.isEnabled = false
    }
    
    guard let user = UserManager.shared.currentUserInfo,
      let task = detailData else { return }
    
    var isRequseter = false
    
    for requester in task.requester where requester == user.uid {
      isRequseter = true
    }
    
    if UserManager.shared.isTourist {
      
      UserManager.shared.goSignInPage(viewController: self)
    } else if isRequseter {
      takeMissionBtn.isHidden = false
      takeMissionBtn.backgroundColor = .lightGray
      takeMissionBtn.setTitle("您已申請此任務", for: .normal)
      takeMissionBtn.tintColor = .black
      takeMissionBtn.isEnabled = false
    } else if user.status == 1  || user.status == 2 {
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
  
  func preventTap() {
    guard let tabVC = self.view.window?.rootViewController as? TabBarViewController else { return }
    LKProgressHUD.show(controller: tabVC)
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
      pageControl.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10),
      pageControl.heightAnchor.constraint(equalToConstant: 30),
      pageControl.widthAnchor.constraint(equalToConstant: 100)
    ])
  }
  
  func getPhoto() {
    guard let status = UserManager.shared.currentUserInfo?.status,
      let taskinfo = detailData else { return }
    if status == 1 {
      
      readUserInfo(uid: taskinfo.missionTaker, isSelf: false) { [weak self] accountInfo in
        guard let account = accountInfo,
             let strongSelf = self else { return }
        strongSelf.reversePhoto = account.photo
      }

    } else if status == 2 {
      
      readUserInfo(uid: taskinfo.uid, isSelf: false) { [weak self] accountInfo in
        guard let account = accountInfo,
             let strongSelf = self else { return }
        strongSelf.reversePhoto = account.photo
      }
    }
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
      cell.backView.backgroundColor = UIColor.black
      guard let video = URL(string: data.taskPhoto[indexPath.row]) else { return UICollectionViewCell() }
      
      let playQueue = AVQueuePlayer()
      let platItem = AVPlayerItem(url: video)
      plaverLooper = AVPlayerLooper(player: playQueue, templateItem: platItem)
      let playerLayer = AVPlayerLayer(player: playQueue)
      
      playerLayer.frame = cell.contentView.bounds
      cell.layer.addSublayer(playerLayer)
      
      playQueue.play()
      
    } else {
      
      cell.detailImage.isHidden = false
      guard let layers = cell.layer.sublayers else { return UICollectionViewCell() }
      for layer in layers {
        if let avPlayerLayer = layer as? AVPlayerLayer {
          avPlayerLayer.removeFromSuperlayer()
        }
      }
      cell.detailImage.loadImage(data.taskPhoto[indexPath.row], placeHolder: UIImage(named: "Image_PlaceHolder") )
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
  // swiftlint:disable cyclomatic_complexity
  // swiftlint:disable_rule:line_length
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let data = detailData,
         let time = self.receiveTime else { return UITableViewCell() }
    
    category[0].type = isMissionON ? .startMission : .miniPhoto
    
    let categorys = category[indexPath.item]
    
    switch categorys.type {
      
    case .miniPhoto:
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "person", for: indexPath) as? MissionPersonTableViewCell else { return UITableViewCell() }
      
      cell.setUp(personURL: data.personPhoto, name: data.nickname)
      
      return cell
      
    case .startMission:
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "startMission", for: indexPath) as? StartMissionTableViewCell,
        let taskData = detailData else { return UITableViewCell() }
      
      let classified = TaskManager.shared.filterClassified(classified: taskData.classfied + 1)
      
      cell.setUp(ownerImage: taskData.personPhoto, author: taskData.nickname, classified: classified[0], price: taskData.money)
      
      cell.tapReprt = { [weak self] in
        
        guard let user = UserManager.shared.currentUserInfo,
          let strongSelf = self else { return }
        
        var compare = ""
        
        if user.status == 1 {
          compare = taskData.missionTaker
        } else {
          compare = taskData.uid
        }
        
        for badMan in user.blacklist where badMan == compare {
          strongSelf.alreadyReport = true
        }
        
        let alert = UIAlertController(title: "檢舉系統", message: "請選擇要做的行動", preferredStyle: .actionSheet)
        
        let report = UIAlertAction(title: "檢舉", style: .default) { _ in
          LKProgressHUD.showSuccess(text: "系統已到您的通知", controller: strongSelf)
        }
        let blackList = UIAlertAction(title: "加入黑名單", style: .default) { [weak self] _ in
          
          guard let strongSelf = self else { return }
          guard var userInfo = UserManager.shared.currentUserInfo,
            let taskInfo = strongSelf.detailData else { return }
          
          if strongSelf.alreadyReport {
            SwiftMes.shared.showWarningMessage(body: "該用戶已在黑名單", seconds: 1.5)
          } else {
            
            strongSelf.preventTap()
            
            let group = DispatchGroup()
            group.enter()
            group.enter()
            
            if userInfo.status == 1 {
              userInfo.blacklist.append(taskInfo.missionTaker)
              strongSelf.reverse = taskInfo.missionTaker
            } else {
              userInfo.blacklist.append(taskInfo.uid)
              strongSelf.reverse = taskInfo.uid
            }
            
            UserManager.shared.updateOppoInfo(userInfo: userInfo) { result in
              
              switch result {
              case .success:
                print("yes")
                group.leave()
              case .failure:
                group.leave()
                print("no")
              }
            }
            
            UserManager.shared.updateReverseUid(uid: strongSelf.reverse, isSelf: false) { result in
              switch result {
              case .success:
                group.leave()
              case .failure:
                group.leave()
                print("error")
              }
            }
            
            group.notify(queue: DispatchQueue.main) {
              UserManager.shared.currentUserInfo = userInfo
              LKProgressHUD.dismiss()
            }
          }
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alert.addAction(report)
        alert.addAction(blackList)
        alert.addAction(cancelAction)
        strongSelf.present(alert, animated: true, completion: nil)
      }
      
      cell.tapOnButton = { [weak self ] in
        guard let strongSelf = self else { return }
        
        guard let chatVC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(identifier: "ChatViewController") as? ChatViewController,
          let taskInfo = strongSelf.detailData else { return }
        
        chatVC.detailData = taskInfo
        chatVC.receiverPhoto = strongSelf.reversePhoto
        strongSelf.show(chatVC, sender: nil)
      }
      
      cell.tapOnNavi = { [weak self ]in
        
        guard let strongSelf = self else { return }
        guard let originalLocation = strongSelf.myLocationManager.location?.coordinate,
          let taskInfo = strongSelf.detailData else { return }
        
        let originCor = "\(originalLocation.latitude),\(originalLocation.longitude)"
        let destination = "\(taskInfo.lat),\(taskInfo.long)"
        let url = URL(string: "comgooglemaps://?saddr=\(originCor)&daddr=\(destination)&directionsmode=driving")
        
        if UIApplication.shared.canOpenURL(url!) {
          UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        } else {
          let appStoreGoogleMapURL = URL(string: "itms-apps://itunes.apple.com/app/id585027354")!
          UIApplication.shared.open(appStoreGoogleMapURL, options: [:], completionHandler: nil)
        }
      }
      cell.backgroundColor = .clear
      return cell
    
    case .normal :
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "missionDetail", for: indexPath) as? MissionDetailTableViewCell else { return UITableViewCell() }
      cell.setUp(title: categorys.title, content: time)
      return cell
      
    case .purpose :
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "content", for: indexPath) as? MissionContentTableViewCell else { return UITableViewCell() }
      
      cell.setUp(title: categorys.title, content: data.detail)
      
      return cell
      
    default:
      return UITableViewCell()
    }
  }
  // swiftlint:enable_rule:line_length
  // swiftlint:enable cyclomatic_complexity
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    
    let spring = UISpringTimingParameters(dampingRatio: 0.7, initialVelocity: CGVector(dx: 1.0, dy: 0.2))
    let animator = UIViewPropertyAnimator(duration: 0.5, timingParameters: spring)
    cell.alpha = 0
    cell.transform = CGAffineTransform(translationX: 0, y: 100 * 0.6)
    animator.addAnimations {
      cell.alpha = 1
      cell.transform = .identity
      self.detailTableView.layoutIfNeeded()
    }
    animator.startAnimation(afterDelay: 0.05 * Double(indexPath.item))
  }
}
