//
//  RequesterRateTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/7.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Cosmos

class RequesterRateTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

  @IBOutlet weak var detailLabel: UILabel!
  
  @IBOutlet weak var starView: CosmosView!
  
  @IBOutlet weak var describeLabel: UILabel!
  
  func setUp(averageStar: Double, titleLabel: String, notYetJudge: Bool, taskCount: Int) {
    
    starView.rating = averageStar
    detailLabel.text = titleLabel
    starView.settings.totalStars = 5
    starView.settings.fillMode = .precise
    starView.settings.updateOnTouch = false
    starView.settings.emptyImage = UIImage(named: "star-2")?.withRenderingMode(.alwaysOriginal)
    starView.settings.filledImage = UIImage(named: "star-3")?.withRenderingMode(.alwaysOriginal)
    
    starView.isHidden = notYetJudge
    describeLabel.isHidden = !notYetJudge
    
    if taskCount == 0 {
      describeLabel.text = "此用戶為新用戶"
    } else {
      describeLabel.text = "此用戶尚未被評價"
    }
  }
}
