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
