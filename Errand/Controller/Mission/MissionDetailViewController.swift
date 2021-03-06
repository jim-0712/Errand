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
        let taskInfo = strongSelf.detailData else { return }
      
      strongSelf.giveUpMission(taskInfo: taskInfo)
    }
    
    let cancelAct = UIAlertAction(title: "back", style: .cancel, handler: nil)
    controller.addAction(okAction)
    controller.addAction(cancelAct)
    self.present(controller, animated: true, completion: nil)
  }
  
  @IBAction func finishMissionAct(_ sender: Any) {
    completeMission()
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
        
        strongSelf.setUpBtnEnable()
        APImanager.shared.postNotification(to: taskInfo.fcmToken, body: "有人申請任務")
        
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
  
     var category: [CellContent] = [CellContent(type: .miniPhoto, title: "大頭貼"),
                                    CellContent(type: .normal, title: "懸賞價格"),
                                    CellContent(type: .normal, title: "發布時間"),
                                    CellContent(type: .purpose, title: "任務細節") ]
     
     var isRequester = false
     
     var isMissionON = false
  
     var isMap = false
     
     var destinationFcmToken = ""
     
     var reverse = ""
     
     let myLocationManager = CLLocationManager()
     
     var receiveTime: String?
     
     var detailData: TaskInfo?
     
     var reversePhoto = ""
     
     var arrangementPhoto: [String] = []
     
     var arrangementVideo: [String] = []
     
     let pageControl = UIPageControl()
     
     let fullSize = UIScreen.main.bounds.size
     
     let dbF = Firestore.firestore()
     
     lazy var missionPhotoCollectionView: UICollectionView = {
       let layout = UICollectionViewFlowLayout()
      let collection = UICollectionView(frame: CGRect(x: 0, y: 0, width: fullSize.width, height: fullSize.height * ( 300 / 896 )), collectionViewLayout: layout)
       layout.scrollDirection = .horizontal
       collection.translatesAutoresizingMaskIntoConstraints = false
       collection.showsVerticalScrollIndicator = false
       collection.showsHorizontalScrollIndicator = false
       return collection
     }()
     
     let headerView: UIView = {
       let header = UIView()
       header.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height * ( 300 / 896 ))
       header.backgroundColor = .pink
       return header
     }()
     
     override func viewDidLoad() {
       super.viewDidLoad()
       setBtnLAyer()
       navigationItem.setHidesBackButton(true, animated: true)
       navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Icons_24px_Back02"), style: .plain, target: self, action: #selector(backToList))
       navigationItem.leftBarButtonItem?.tintColor = .white
       
       guard detailData != nil else {
         fetchTaskData()
         return
       }
       
       guard let status = UserManager.shared.currentUserInfo?.status else {
         fetchTaskData()
         return
       }
       
       if detailData?.missionTaker != "" {
         isMissionON = true
         missionStackView.isHidden = false
         takeMissionBtn.isHidden = true
         startMissionSetupBtn()
       } else {
         missionStackView.isHidden = true
         takeMissionBtn.isHidden = false
         setUpBtnEnable()
       }
       
       UserManager.shared.statusJudge = status
       
       fetchTaskOwnerPhoto()
       setUpView()
       setUpListenerToTask()
     }
  
     func setBtnLAyer() {
      
      finishMissionBtn.layer.borderWidth = 1.0
      finishMissionBtn.layer.borderColor = UIColor.BB1?.cgColor
      giveUpmissionBtn.layer.borderWidth = 1.0
      giveUpmissionBtn.layer.borderColor = UIColor.BB1?.cgColor
      takeMissionBtn.layer.borderWidth = 1.0
      takeMissionBtn.layer.borderColor = UIColor.BB1?.cgColor
    
     }
     
     override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
      
          if isMap {
              backBtn.isHidden = false
              takeMissionBtn.isHidden = false
            } else if navigationController == nil {
             backBtn.isHidden = false
             takeMissionBtn.isHidden = true
           } else {
             backBtn.isHidden = true
           }
     }
     
     override func viewWillDisappear(_ animated: Bool) {
       super.viewWillDisappear(animated)
       guard let taskData = detailData else { return }
       if taskData.ownerCompleteTask && taskData.takerCompleteTask {
         MutipleFuncManager.shared.changeStatus(task: taskData) { result in
           switch result {
           case .success:
             print("mission complete")
           case .failure:
             print("mission fail")
           }
         }
       }
     }
     
     override func viewDidLayoutSubviews() {
       super.viewDidLayoutSubviews()
       pageControl.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
     }
     
     @objc func backToList() {
       self.navigationController?.popViewController(animated: true)
     }
    
    func backTosignIn() {
      let signInVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "main") as? ViewController
      UserManager.shared.isTourist = true
      UserDefaults.standard.removeObject(forKey: "login")
      self.view.window?.rootViewController = signInVC
    }
    
    func gotoJudgePage() {
      guard let judgeVC = storyboard?.instantiateViewController(withIdentifier: "judge") as? JudgeMissionViewController,
           let taskInfo = detailData  else { return }
           judgeVC.detailData = taskInfo
           NotificationCenter.default.post(name: Notification.Name("getMissionList"), object: nil)
           present(judgeVC, animated: true, completion: nil)
    }
    
    func giveUpMission(taskInfo: TaskInfo) {
      MutipleFuncManager.shared.giveUpMission(taskData: taskInfo) { [weak self]result in
        guard let strongSelf = self else { return }
        switch result {
        case .success:
          LKProgressHUD.dismiss()
          let mapView = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(withIdentifier: "tab")
          strongSelf.view.window?.rootViewController = mapView
        case .failure:
          LKProgressHUD.showFailure(text: "Can't give up", controller: strongSelf)
        }
      }
    }
    
    func completeMission() {
      guard let taskInfo = detailData else { return }
      MutipleFuncManager.shared.completeMission(taskData: taskInfo) { [weak self] result in
        guard let strongSelf = self else { return }
        switch result {
        case .success(let destinationFcmToken):
                guard let taskInfo = strongSelf.detailData else { return }
                if taskInfo.ownerCompleteTask && taskInfo.takerCompleteTask {
                  strongSelf.finishMissionAlert(title: "恭喜", message: "任務完成", viewController: strongSelf)
                } else {
                  
                APImanager.shared.postNotification(to: destinationFcmToken, body: "對方任務完成")
          
                  let controller = UIAlertController(title: "恭喜", message: "等待對方完成", preferredStyle: .alert)
                  let okAction = UIAlertAction(title: "ok", style: .default) { [weak self] _ in
                    guard let strongSelf = self else { return }
          
                    strongSelf.gotoJudgePage()
                  }
                  controller.addAction(okAction)
                  strongSelf.present(controller, animated: true, completion: nil)
                  strongSelf.finishMissionBtn.isEnabled = false
                  strongSelf.finishMissionBtn.backgroundColor = UIColor.LG1
                  strongSelf.finishMissionBtn.setTitle("等待對方完成", for: .normal)
                  strongSelf.giveUpmissionBtn.isEnabled = false
                  }
        case.failure:
          LKProgressHUD.showFailure(text: "error", controller: strongSelf)
        }
      }
    }
    
    func fetchTaskData() {
      
      if UserManager.shared.isTourist {
        missionStackView.isHidden = true
        setUpView()
        
      } else {
        guard let userInfo = UserManager.shared.currentUserInfo else {
          backBtn.isHidden = false
          guard let uid = Auth.auth().currentUser?.uid else { return }
          
          readUserInfo(uid: uid, isSelf: true) { [weak self] _ in
            guard let strongSelf = self else { return }
            if Auth.auth().currentUser == nil {
              SwiftMes.shared.showWarningMessage(body: "請先登入", seconds: 1.0)
              DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                guard let strongSelf = self else { return }
                strongSelf.backTosignIn()
              }
            }
            
            guard let status = UserManager.shared.currentUserInfo?.status else { return }
            
            if status == 0 {
              SwiftMes.shared.showSuccessMessage(body: "該任務已經完成", seconds: 1.0)
              DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let mapView = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(withIdentifier: "tab")
                strongSelf.view.window?.rootViewController = mapView
              }
            } else {
              UserManager.shared.statusJudge = status
              strongSelf.callTaskData()
            }
          }
          return
        }
        
        if userInfo.status == 0 {
          setUpView()
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
          strongSelf.fetchTaskOwnerPhoto()
          strongSelf.setUpView()
          if strongSelf.isMissionON {
            strongSelf.setUpListenerToTask()
          }
          
        case .failure(let error):
          let handler = error.localizedDescription.components(separatedBy: "MissionError")
          
          if handler.count > 1 {
            
            let alert = UIAlertController(title: "注意", message: "本次任務已完成", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "ok", style: .default) { _ in
              
              let mapView = UIStoryboard(name: "Content", bundle: nil).instantiateViewController(withIdentifier: "tab")
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

    func setUpView() {
      setUpCommectionAndTableView()
      setUpBtn()
      setUppageControll()
      detailTableView.reloadData()
    }
    
    func setUpCommectionAndTableView() {
      missionPhotoCollectionView.delegate = self
      missionPhotoCollectionView.dataSource = self
      detailTableView.delegate = self
      detailTableView.dataSource = self
      missionPhotoCollectionView.isPagingEnabled = true
      detailTableView.rowHeight = UITableView.automaticDimension
      detailTableView.register(UINib(nibName: "StartMissionTableViewCell", bundle: nil), forCellReuseIdentifier: "startMission")
      missionPhotoCollectionView.register(UINib(nibName: "MissionDetailCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "detail")
      headerView.addSubview(missionPhotoCollectionView)
      detailTableView.tableHeaderView = headerView
    }
    
    func setUpListenerToTask() {
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
          case .failure:
            print("error")
          }
        }
      }
    }

    func finishMissionAlert(title: String, message: String, viewController: UIViewController) {
      let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
      let okAction = UIAlertAction(title: "ok", style: .default) { [weak self]_ in
        guard let strongSelf = self else { return }
        
        strongSelf.gotoJudgePage()
      }
      
      controller.addAction(okAction)
      viewController.present(controller, animated: true, completion: nil)
    }
    
    func startMissionSetupBtn() {
      
      guard let task = detailData,
           let status = UserManager.shared.currentUserInfo?.status else { return }
      
      if status == 1 && task.ownerCompleteTask || status == 2 && task.takerCompleteTask {
        finishMissionBtn.isEnabled = false
        finishMissionBtn.backgroundColor = UIColor.LG1
        giveUpmissionBtn.isEnabled = false
        giveUpmissionBtn.setTitle("已經完成", for: .normal)
        finishMissionBtn.setTitle("等待對方完成", for: .normal)
      } else {
        finishMissionBtn.isEnabled = true
        giveUpmissionBtn.isEnabled = true
        finishMissionBtn.backgroundColor = UIColor.white
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
      
     if isRequseter {
        takeMissionBtn.isHidden = false
        takeMissionBtn.backgroundColor = .lightGray
        takeMissionBtn.setTitle("您已申請此任務", for: .normal)
        takeMissionBtn.tintColor = .black
        takeMissionBtn.isEnabled = false
      } else if user.status == 1 || user.status == 2 {
        takeMissionBtn.backgroundColor = .lightGray
        takeMissionBtn.setTitle("請先完成當前任務", for: .normal)
        takeMissionBtn.tintColor = .black
        takeMissionBtn.isEnabled = false
      } else {
      takeMissionBtn.backgroundColor = .white
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
    
    func fetchTaskOwnerPhoto() {
      guard let status = UserManager.shared.currentUserInfo?.status,
           let taskinfo = detailData else { return }
      
      var uid = ""
      
      switch status {
      case 1:
        uid = taskinfo.missionTaker
      case 2:
        uid = taskinfo.uid
      default:
        print("error")
      }
      
      readUserInfo(uid: uid, isSelf: false) { [weak self] accountInfo in
        guard let account = accountInfo,
          let strongSelf = self else { return }
        strongSelf.reversePhoto = account.photo
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
    
    func removeLayer(cell: MissionDetailCollectionViewCell) {
      guard let layers = cell.layer.sublayers else { return }
      for layer in layers {
        if let avPlayerLayer = layer as? AVPlayerLayer {
          avPlayerLayer.removeFromSuperlayer()
        }
      }
    }
    
    func addToBlackList(alreadyReport: Bool) {
      preventTap()
      guard let taskInfo = detailData else { return }
      
      MutipleFuncManager.shared.addToBlackList(alreadyReport: alreadyReport, taskInfo: taskInfo) { [weak self]result in
        guard let strongSelf = self else { return }
        switch result {
        case .success(let successMessage):
          if successMessage == "already" {
            LKProgressHUD.dismiss()
            SwiftMes.shared.showWarningMessage(body: "該用戶已在黑名單", seconds: 1.5)
          }
          LKProgressHUD.dismiss()
        case .failure:
          LKProgressHUD.showFailure(text: "Error", controller: strongSelf)
        }
      }
    }
    
    func reportUser() {
      guard let user = UserManager.shared.currentUserInfo,
           let taskInfo =  detailData else { return }
           
      var alreadyReport = false
      var compare = ""
      
      if user.status == 1 {
        compare = taskInfo.missionTaker
      } else {
        compare = taskInfo.uid
      }
      
      for badMan in user.blacklist where badMan == compare {
        alreadyReport = true
      }
      
      let alert = UIAlertController(title: "檢舉系統", message: "請選擇要做的行動", preferredStyle: .actionSheet)
      let report = UIAlertAction(title: "檢舉", style: .default) { _ in
        LKProgressHUD.showSuccess(text: "系統已到您的通知", controller: self)
      }
      let blackList = UIAlertAction(title: "加入黑名單", style: .default) { [weak self] _ in
        guard let strongSelf = self else { return }
        strongSelf.addToBlackList(alreadyReport: alreadyReport)
      }
      
      let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
      alert.addAction(report)
      alert.addAction(blackList)
      alert.addAction(cancelAction)
      present(alert, animated: true, completion: nil)
    }
    
    func gotoNavigation() {
      guard let originalLocation = myLocationManager.location?.coordinate,
           let taskInfo = detailData else { return }
      
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
      
      removeLayer(cell: cell)
      
      let typeManager = data.taskPhoto[indexPath.row].components(separatedBy: "mov")
      if typeManager.count > 1 {
        guard let video = URL(string: data.taskPhoto[indexPath.row]) else { return UICollectionViewCell() }
        cell.detailImage.isHidden = true
        cell.backView.backgroundColor = UIColor.black
        cell.setUpLooper(video: video)
        
      } else {
        cell.detailImage.isHidden = false
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
      return CGSize(width: fullSize.width, height: fullSize.height * ( 300 / 896 ))
    }
  }

  extension MissionDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return 4
    }
    
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
          
          guard let strongSelf = self else { return }
          strongSelf.reportUser()
        }
        
        cell.chatroomHandler = { [weak self ] in
          guard let strongSelf = self else { return }
          
          guard let chatVC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController,
               let taskInfo = strongSelf.detailData else { return }
          
          chatVC.detailData = taskInfo
          chatVC.receiverPhoto = strongSelf.reversePhoto
          strongSelf.show(chatVC, sender: nil)
        }
        
        cell.navigationHandler = { [weak self]in
          guard let strongSelf = self else { return }
          strongSelf.gotoNavigation()
        }
        
        cell.backgroundColor = .clear
        return cell
        
      case .normal :
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "missionDetail", for: indexPath) as? MissionDetailTableViewCell else { return UITableViewCell() }
        
        if indexPath.row == 1 {
          cell.setUp(title: categorys.title, content: "\(data.money)元")
        } else {
          cell.setUp(title: categorys.title, content: time)
        }
        return cell
        
      case .purpose :
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "content", for: indexPath) as? MissionContentTableViewCell else { return UITableViewCell() }
        
        cell.setUp(title: categorys.title, content: data.detail)
        
        return cell
        
      default:
        return UITableViewCell()
      }
    }

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
