//
//  CategoryCollectionViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/1.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class CategoryCollectionViewCell: UICollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
  
    }
  
  override var isSelected: Bool {
      didSet {
        layer.borderColor = isSelected ? UIColor.black.cgColor : UIColor.white.cgColor
        
        self.contentView.backgroundColor = isSelected ? UIColor(red: 246.9/255.0, green: 212.0/255.0, blue: 95.0/255.0, alpha: 1.0) :  UIColor(red: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1.0)
      
        layer.borderWidth = isSelected ? 1.0 : 0.0
      }
  }
  
  @IBOutlet weak var colorBlock: UIView!
  
  @IBOutlet weak var groupLabel: UILabel!
  
  func setUpContent(label: String, color: UIColor) {
    
    self.layer.cornerRadius = UIScreen.main.bounds.width / 40
    
    groupLabel.text = label
    
    groupLabel.textColor = .darkGray
    
    colorBlock.backgroundColor = color
    
    colorBlock.layer.cornerRadius = UIScreen.main.bounds.width / 40
  
    self.contentView.backgroundColor = UIColor.G1
  }
  
}
