//
//  PersonRateTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/6.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Cosmos

class PersonRateTableViewCell: UITableViewCell {

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
  
  func setUp(averageStar: Double, titleLabel: String) {
    
    starView.settings.updateOnTouch = false
    starView.rating = averageStar
    starView.settings.totalStars = 5
    starView.settings.fillMode = .precise
    starView.settings.emptyImage = UIImage(named: "star-2")?.withRenderingMode(.alwaysOriginal)
    starView.settings.filledImage = UIImage(named: "star-3")?.withRenderingMode(.alwaysOriginal)
    detailLabel.text = titleLabel
  }
}
