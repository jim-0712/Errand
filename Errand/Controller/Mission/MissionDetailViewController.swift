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

class MissionDetailViewController: UIViewController {
  
  var isRequester = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    URLSessionConfiguration.default.multipathServiceType = .handover
    setUp()
    setUpBtn()
    setUppageControll()
    setUpImageView()
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
  
    TaskManager.shared.updateTaskRequest(owner: taskInfo.email) { [weak self ]result in
      
      guard let strongSelf = self else { return }
      
      switch result {
        
      case .success:
        
        NotificationCenter.default.post(name: Notification.Name("takeMission"), object: nil)
        
        let sender = PushNotificationSender()
        sender.sendPushNotification(to: taskInfo.fcmToken, body: "趕快開啟查看")
//        strongSelf.isRequester = true
        
        strongSelf.setUpBtnEnable()
        LKProgressHUD.dismiss()
        
      case .failure(let error):
        
        LKProgressHUD.showFailure(text: error.localizedDescription, controller: strongSelf)
        
      }
    }
    
  }
  
  var detailData: TaskInfo?
  
  var arrangementPhoto: [String] = []
  
  var arrangementVideo: [String] = []
  
  var receiveTime: String?
  
  let missionDetail = ["任務內容", "懸賞價格", "發布時間", "任務細節"]
  
  let fullSize = UIScreen.main.bounds.size
  
  func setUp() {
    taskViewCollectionView.delegate = self
    taskViewCollectionView.dataSource = self
    detailTableView.delegate = self
    detailTableView.dataSource = self
    detailTableView.rowHeight = UITableView.automaticDimension
  }
  
  func setUpBtnEnable() {
    
    guard let taskdata = detailData,
            let user = UserManager.shared.currentUserInfo?.email else { return }

       for count in 0 ..< taskdata.requester.count {
         
         if taskdata.requester[count] == user {
           isRequester = true
         } else {
           isRequester = false
         }
       }
       
       if isRequester {
         
         takeMissionBtn.backgroundColor = .lightGray
         takeMissionBtn.setTitle("等待接受中", for: .normal)
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
    
    backBtn.layer.cornerRadius = backBtn.bounds.width / 2
    takeMissionBtn.layer.cornerRadius = 20
    takeMissionBtn.layer.shadowOpacity = 0.5
    takeMissionBtn.layer.shadowOffset = CGSize(width: 3, height: 3)
    setUpBtnEnable()
  }
  
  func setUppageControll() {
    
    guard let data = detailData else { return }

    pageControl.currentPage = 0
    pageControl.currentPageIndicatorTintColor = .black
    pageControl.pageIndicatorTintColor = .lightGray
    pageControl.layer.cornerRadius = 10
    pageControl.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
    pageControl.numberOfPages = data.taskPhoto.count
  }
  
  func setUpImageView() {
    
    guard let data = detailData else { return }
    
    for count in 0 ..< data.fileType.count {
      
      if data.fileType[count] == 0 {
        
        self.arrangementPhoto.append(data.taskPhoto[count])
        
      } else {
        
        self.arrangementVideo.append(data.taskPhoto[count])
      }
    }
    
    var taskImage = UIImageView()
    
    var taskVideoView = UIView()
    
    for count in 0 ..< arrangementPhoto.count {
      taskImage = UIImageView(frame: CGRect(x: 0, y: 0, width: fullSize.width, height: 350))
      taskImage.contentMode = .scaleAspectFill
      taskImage.clipsToBounds = true
      taskImage.center = CGPoint(x: fullSize.width * (0.5 + CGFloat(count)), y: 175)
      taskViewCollectionView.addSubview(taskImage)
      taskImage.loadImage(arrangementPhoto[count])
    }
    
    for count in 0 ..< arrangementVideo.count {
      
      let playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "play-button"), for: .normal)
        button.backgroundColor = .red
        button.addTarget(self, action: #selector(videoPlay(sender:)), for: .touchUpInside)
        return button
      }()
      
      guard let url = URL(string: arrangementVideo[count]) else { return }
      
      taskVideoView = UIView(frame: CGRect(x: 0, y: 0, width: fullSize.width, height: 350))
      taskVideoView.contentMode = .center
      taskVideoView.center = CGPoint(x: fullSize.width * (0.5 + CGFloat(arrangementPhoto.count + count)), y: 175)
      taskViewCollectionView.addSubview(taskVideoView)
      
      let player = AVPlayer(url: url)
      let playerLayer = AVPlayerLayer(player: player)
      playerLayer.frame = taskVideoView.bounds
      taskVideoView.layer.addSublayer(playerLayer)
      
      taskVideoView.addSubview(playButton)
      NSLayoutConstraint.activate([
        playButton.centerXAnchor.constraint(equalTo: taskVideoView.centerXAnchor),
        playButton.centerYAnchor.constraint(equalTo: taskVideoView.centerYAnchor),
        playButton.widthAnchor.constraint(equalToConstant: 50),
        playButton.heightAnchor.constraint(equalToConstant: 50)
      ])
      
    }
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
    
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "detailView", for: indexPath) as? MissionDetailCollectionViewCell else { return UICollectionViewCell() }
    
    cell.backgroundColor = .gray
    
    return cell
  }
}

extension MissionDetailViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    return CGSize(width: UIScreen.main.bounds.width, height: 400)
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
        cell.setUp(title: "\(missionDetail[indexPath.row])元", content: time)
      }

    return cell
    
  } else {
      
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "content", for: indexPath) as? MissionContentTableViewCell else { return UITableViewCell() }
      
      cell.setUp(title: missionDetail[3], content: data.detail)
      
      return cell
    }
  }
}
