//
//  MissionDetailViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/30.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import AVKit
import Kingfisher

class MissionDetailViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    URLSessionConfiguration.default.multipathServiceType = .handover
    
    setUp()
    
    setUpImageView()
    // Do any additional setup after loading the view.
  }
  
  var detailData: TaskInfo?
  
  var arrangementPhoto: [String] = []
  
  var arrangementVideo: [String] = []
  
  let fullSize = UIScreen.main.bounds.size
  
  @IBOutlet weak var pageControl: UIPageControl!
  
  @IBOutlet weak var taskViewCollectionView: UICollectionView!
  
  func setUp() {
    
    guard let data = detailData else { return }
    
    taskViewCollectionView.delegate = self
    
    taskViewCollectionView.dataSource = self
    
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
      
      taskVideoView.contentMode = .scaleAspectFill
      
      taskVideoView.clipsToBounds = true
      
      taskVideoView.center = CGPoint(x: fullSize.width * (0.5 + CGFloat(arrangementPhoto.count + count)), y: 200)
      
      let player = AVPlayer(url: url)
      
      let playerLayer = AVPlayerLayer(player: player)
      
      playerLayer.frame = taskVideoView.bounds
      
      taskVideoView.layer.addSublayer(playerLayer)
      
      player.play()
      
    }
  }
  
//  let player = AVPlayer(url: videoTransferUrl)
//
//  let playerLayer = AVPlayerLayer(player: player)
//
//  playerLayer.frame = strongSelf.videoView[strongSelf.fileURL.count].bounds
//
//  strongSelf.videoView[strongSelf.fileURL.count].layer.addSublayer(playerLayer)
//
//  player.play()
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
