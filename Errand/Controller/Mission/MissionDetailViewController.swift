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

class MissionDetailViewController: UIViewController {
  
  var isRequester = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    URLSessionConfiguration.default.multipathServiceType = .handover

    loadUserInfo()
    setUp()
    setUpBtn()
    setUppageControll()
  }
  
  override func viewDidLayoutSubviews() {
    
    super.viewDidLayoutSubviews()
    pageControl.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
  }
  
  @IBOutlet weak var takeMissionBtn: UIButton!
  
  @IBOutlet weak var pageControl: UIPageControl!
  
  @IBOutlet weak var detailTableView: UITableView!
  
  @IBOutlet weak var taskViewCollectionView: UICollectionView!
  
  @IBOutlet weak var backBtn: UIButton!
  
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
  
  var arrangementPhoto: [String] = []
  
  var arrangementVideo: [String] = []
  
  let missionDetail = ["任務內容", "懸賞價格", "發布時間", "任務細節"]
  
  let fullSize = UIScreen.main.bounds.size
  
  func setUp() {
    taskViewCollectionView.delegate = self
    taskViewCollectionView.dataSource = self
    detailTableView.delegate = self
    detailTableView.dataSource = self
    detailTableView.rowHeight = UITableView.automaticDimension
  }
  
  func loadUserInfo() {
    
    if let uid = Auth.auth().currentUser?.uid {
      
      UserManager.shared.readData(uid: uid) {result in
        
        switch result {
            
        case .success(let dataReturn):
          UserManager.shared.isPostTask = dataReturn.onTask
          UserManager.shared.currentUserInfo = dataReturn
          
        case .failure:
          
          return
        }
      }
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
    backBtn.layer.cornerRadius = backBtn.bounds.height / 2
    takeMissionBtn.layer.shadowOffset = CGSize(width: 3, height: 3)
    takeMissionBtn.layer.cornerRadius = takeMissionBtn.bounds.height / 5
  }
  
  func setUppageControll() {
    
    guard let data = detailData else { return }
    pageControl.currentPage = 0
    pageControl.layer.cornerRadius = 10
    pageControl.pageIndicatorTintColor = .lightGray
    pageControl.numberOfPages = data.taskPhoto.count
    pageControl.currentPageIndicatorTintColor = .black
    pageControl.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
  }
  
  @objc func videoPlay(sender: UIButton) {
    guard let layer = sender.superview?.layer as? AVPlayerLayer else { return }
    layer.player?.play()
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
      cell.playBtn.addTarget(self, action: #selector(videoPlay(sender:)), for: .touchUpInside)
      guard let video = URL(string: data.taskPhoto[indexPath.row]) else { return UICollectionViewCell() }
      let player = AVPlayer(url: video)
      let playerLayer = AVPlayerLayer(player: player)
      playerLayer.frame = cell.contentView.bounds
      cell.layer.addSublayer(playerLayer)
      cell.playBtn.isHidden = false
      
    } else {
      cell.playBtn.isHidden = true
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
    
    return CGSize(width: UIScreen.main.bounds.width, height: 350)
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
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "person", for: indexPath) as? MissionPersonTableViewCell else { return UITableViewCell() }
      
      cell.setUp(personURL: data.personPhoto, name: data.nickname)
      
      return cell
      
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
}
