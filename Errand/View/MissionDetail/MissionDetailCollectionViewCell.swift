//
//  MissionDetailCollectionViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/20.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class MissionDetailCollectionViewCell: UICollectionViewCell {

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
  
  @IBOutlet weak var detailImage: UIImageView!
  
  @IBOutlet weak var backView: UIView!
}
