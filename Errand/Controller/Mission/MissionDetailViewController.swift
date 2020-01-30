//
//  MissionDetailViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/30.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Kingfisher

class MissionDetailViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUp()
    
//    setUpImageView()
    // Do any additional setup after loading the view.
  }
  
  var detailData: TaskInfo?
  
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
    
    var taskImage = UIImageView()
    
    for count in 0 ..< data.taskPhoto.count {
      
      guard let url = URL(string: data.taskPhoto[count]) else { return }
      
      taskImage = UIImageView(frame: CGRect(x: 0, y: 0, width: fullSize.width, height: 400))
      
      taskImage.contentMode = .scaleAspectFill
      
      taskImage.clipsToBounds = true
      
      taskImage.center = CGPoint(x: fullSize.width * (0.5 + CGFloat(count)), y: 200)
      
      taskViewCollectionView.addSubview(taskImage)
      
      taskImage.kf.setImage(with: url)
      
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
