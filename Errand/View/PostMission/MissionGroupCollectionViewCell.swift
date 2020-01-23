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
  
  override init(frame: CGRect) {
    
    super.init(frame: frame)
  }
  
  required init?(coder: NSCoder) {
    
    super.init(coder: coder)
  }

}
