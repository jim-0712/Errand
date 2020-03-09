//
//  MissionDetailCollectionViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/20.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class MissionDetailCollectionViewCell: UICollectionViewCell {
  
  var playerLooper: AVPlayerLooper?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
      self.contentView.backgroundColor = .white
      backView.layer.shadowOffset = CGSize(width: 0, height: 5)
      backView.layer.shadowColor = UIColor.lightGray.cgColor
      backView.layer.shadowOpacity = 1.0
      backView.layer.cornerRadius = backView.bounds.width / 25
      backView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
      detailImage.layer.cornerRadius = detailImage.bounds.width / 25
      detailImage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
  
  func setUpLooper(video: URL) {
    let playQueue = AVQueuePlayer()
    let platItem = AVPlayerItem(url: video)
    playerLooper = AVPlayerLooper(player: playQueue, templateItem: platItem)
    let playerLayer = AVPlayerLayer(player: playQueue)
    
    playerLayer.frame = self.contentView.bounds
    self.layer.addSublayer(playerLayer)
    playQueue.play()
  }
  
  @IBOutlet weak var detailImage: UIImageView!
  
  @IBOutlet weak var backView: UIView!
}
