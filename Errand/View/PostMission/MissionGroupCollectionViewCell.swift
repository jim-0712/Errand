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
  
  override var isSelected: Bool {
      didSet {
        layer.borderColor = isSelected ? UIColor.clear.cgColor : UIColor.white.cgColor
        
        self.contentView.backgroundColor = isSelected ? UIColor(red: 246.9/255.0, green: 212.0/255.0, blue: 95.0/255.0, alpha: 1.0) : UIColor.white
      
        layer.borderWidth = isSelected ? 1.0 : 0.0
      }
  }
  
  func setUpContent(label: String, color: UIColor) {
    
    self.layer.cornerRadius = UIScreen.main.bounds.width / 40
    
    groupLabel.text = label
    
    groupColorBlock.backgroundColor = color
    
    groupColorBlock.layer.cornerRadius = UIScreen.main.bounds.width / 40
  }

}
