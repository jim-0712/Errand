//
//  PhotoCollectionViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/4.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

protocol UploadDataManager: AnyObject {
  
  func tapOnUpload(collectionViewCelll: PhotoCollectionViewCell)
}

class PhotoCollectionViewCell: UICollectionViewCell {
  
  weak var delegate: UploadDataManager?
    
  @IBOutlet weak var photoImageView: UIImageView!
  
  @IBOutlet weak var addPhotoBtn: UIButton!
  
  @IBAction func addPhoto(_ sender: Any) {
    
    self.delegate?.tapOnUpload(collectionViewCelll: self)
    
  }
  
}
