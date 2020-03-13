//
//  MissionGroupCollectionViewCell.swift
//  Errand
//
//  Created by Jim on 2020/1/23.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class MissionGroupCollectionViewCell: UICollectionViewCell {
  
  @IBOutlet weak var groupLabel: UILabel!
    
  @IBOutlet weak var groupColorBlock: UIView!
  
  func setUpContent(label: String, color: UIColor) {
    
    groupLabel.text = label
    
    groupColorBlock.backgroundColor = color
    
    self.layer.cornerRadius = UIScreen.main.bounds.width / 40
    
    groupColorBlock.layer.cornerRadius = UIScreen.main.bounds.width / 40
  }

}
