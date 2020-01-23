//
//  PostMissionViewController.swift
//  Errand
//
//  Created by Jim on 2020/1/23.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class PostMissionViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUp()
  }
  
  @IBOutlet weak var missionGroupCollectionView: UICollectionView!
  
  let backgroundManager = BackgroundManager.shared
  
  let missionGroup = ["搬運物品", "清潔打掃", "水電維修", "科技維修", "驅趕害蟲", "一日陪伴", "交通接送", "其他種類"]
  
  func setUp() {
    
    let backView = backgroundManager.setUpView(view: self.view)
    
    self.view.layer.insertSublayer(backView, at: 0)
    
    missionGroupCollectionView.delegate = self
    
    missionGroupCollectionView.dataSource = self
  
  }
}

extension PostMissionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    return 8
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "group", for: indexPath) as? MissionGroupCollectionViewCell else { return UICollectionViewCell() }
    
    cell.layer.cornerRadius = 10
    
    cell.groupLabel.text = missionGroup[indexPath.row]
    
    return cell
  }
  
}

extension PostMissionViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let screenwidth = UIScreen.main.bounds.width
    
    let screenheight = UIScreen.main.bounds.height
    
    return CGSize(width: screenwidth / 3, height: screenheight / 20)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    
    return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
  }
}
