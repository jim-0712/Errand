//
//  PhotoCollectionViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/4.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

protocol UploadDataManager: AnyObject {
  
  func tapOnUpload(collectionViewCelll: PhotoCollectionViewCell)
  
  func tapOnDelete(collectionViewCelll: PhotoCollectionViewCell, indexRow: Int)
}

class PhotoCollectionViewCell: UICollectionViewCell {
  
  override init(frame: CGRect) {
    
    super.init(frame: frame)
    
//    self.contentView.layer.borderColor = UIColor.black.cgColor
////
//    self.contentView.layer.borderWidth = 1.0
  }
  
  var indexRow = 0
  
  var playerLooper: AVPlayerLooper?
  
  required init?(coder: NSCoder) {
    
    super.init(coder: coder)
    
    self.contentView.layer.borderColor = UIColor.black.cgColor

    self.contentView.layer.borderWidth = 1
  }
  
  weak var delegate: UploadDataManager?
    
  @IBOutlet weak var photoImageView: UIImageView!
  
  @IBOutlet weak var addPhotoBtn: UIButton!
  
  @IBOutlet weak var deleteBtn: UIButton!
  
  @IBAction func addPhoto(_ sender: Any) {
    self.delegate?.tapOnUpload(collectionViewCelll: self)
  }
  
  @IBAction func deleteAct(_ sender: Any) {
    self.delegate?.tapOnDelete(collectionViewCelll: self, indexRow: indexRow)
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
  
}
