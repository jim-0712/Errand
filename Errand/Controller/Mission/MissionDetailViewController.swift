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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    URLSessionConfiguration.default.multipathServiceType = .handover
    
    setUp()
    
    setUpBtn()
    
    setUppageControll()
    
    setUpImageView()
    // Do any additional setup after loading the view.
  }
  
  @IBOutlet weak var takeMissionBtn: UIButton!
  
  @IBOutlet weak var pageControl: UIPageControl!
  
  @IBOutlet weak var detailTableView: UITableView!
  
  @IBOutlet weak var taskViewCollectionView: UICollectionView!
  
  @IBAction func takeMissionAct(_ sender: Any) {
  }
  
  var detailData: TaskInfo?
  
  var arrangementPhoto: [String] = []
  
  var arrangementVideo: [String] = []
  
  let missionGroup = ["搬運物品", "清潔打掃", "水電維修", "科技維修", "驅趕害蟲", "一日陪伴", "交通接送", "其他種類"]
  
  let fullSize = UIScreen.main.bounds.size
  
  func setUp() {
    
    taskViewCollectionView.delegate = self
    
    taskViewCollectionView.dataSource = self
    
    detailTableView.delegate = self
    
    detailTableView.dataSource = self
    
  }
  
  func setUpBtn() {
    
    takeMissionBtn.layer.cornerRadius = 20
    
    takeMissionBtn.layer.shadowOpacity = 0.5
    
    takeMissionBtn.layer.shadowOffset = CGSize(width: 3, height: 3)
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
      
      guard let url = URL(string: arrangementPhoto[count]) else { return }
      
      taskImage = UIImageView(frame: CGRect(x: 0, y: 0, width: fullSize.width, height: 400))
      
      taskImage.contentMode = .scaleAspectFill
      
      taskImage.clipsToBounds = true
      
      taskImage.center = CGPoint(x: fullSize.width * (0.5 + CGFloat(count)), y: 200)
      
      taskViewCollectionView.addSubview(taskImage)
      
      taskImage.kf.setImage(with: url)
      
    }
    
    for count in 0 ..< arrangementVideo.count {
      
      guard let url = URL(string: arrangementVideo[count]) else { return }
      
      taskVideoView = UIView(frame: CGRect(x: 0, y: 0, width: fullSize.width, height: 400))
      
      taskVideoView.contentMode = .center
      
      taskVideoView.center = CGPoint(x: fullSize.width * (0.5 + CGFloat(arrangementPhoto.count + count)), y: 200)
      
      taskViewCollectionView.addSubview(taskVideoView)
      
      let player = AVPlayer(url: url)

      let playerLayer = AVPlayerLayer(player: player)

      playerLayer.frame = taskVideoView.bounds

      taskVideoView.layer.addSublayer(playerLayer)

      player.play()
      
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
    
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "missionDetail", for: indexPath) as? MissionDetailTableViewCell else { return UITableViewCell() }
    
    guard let data = detailData else { return UITableViewCell() }
    
    switch indexPath.row {
      
    case 0 :
      switch data.classfied {
        
      case 0 :
        
        cell.contentLabel.text = missionGroup[0]
        
      case 1 :
        
        cell.contentLabel.text = missionGroup[1]
        
      case 2 :
        
        cell.contentLabel.text = missionGroup[2]
      case 3 :
        
        cell.contentLabel.text = missionGroup[3]
      case 4 :
        
        cell.contentLabel.text = missionGroup[4]
      case 5 :
        
        cell.contentLabel.text = missionGroup[5]
      case 6 :
        
        cell.contentLabel.text = missionGroup[6]
      default:
        
        cell.contentLabel.text = missionGroup[7]
      }
      cell.detailLabel.text = "任務內容"
      
    default:
      
      return UITableViewCell()
    }
    
    return cell
  }
  
}
