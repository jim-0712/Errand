//
//  PersonStarTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/25.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Cosmos

class PersonStarTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
  
  @IBOutlet weak var newUserLabel: UILabel!
  
  @IBOutlet weak var detailLabel: UILabel!
  
  @IBOutlet weak var starView: CosmosView!
  
  func setUp(isFirst: Bool, averageStar: Double, titleLabel: String) {
    
    starView.settings.updateOnTouch = false
    starView.rating = averageStar
    starView.settings.totalStars = 5
    starView.settings.fillMode = .precise
    starView.settings.emptyImage = UIImage(named: "star-2")?.withRenderingMode(.alwaysOriginal)
    starView.settings.filledImage = UIImage(named: "star-3")?.withRenderingMode(.alwaysOriginal)
    detailLabel.text = titleLabel
    
    if isFirst {
      newUserLabel.isHidden = false
      starView.isHidden = true
    } else {
      newUserLabel.isHidden = true
      starView.isHidden = false
    }
    
    if averageStar == 0.01 {
      newUserLabel.text = "尚未被評價"
    }
    
    if UserManager.shared.isTourist {
      newUserLabel.text = "遊客"
    } else {
      newUserLabel.text = "此用戶為新用戶"
    }
  }
    
}
