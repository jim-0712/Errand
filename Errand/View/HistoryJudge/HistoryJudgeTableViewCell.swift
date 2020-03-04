//
//  HistoryJudgeTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/26.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Cosmos

class HistoryJudgeTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
      
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
  @IBOutlet weak var classifiedImage: UIImageView!
  
  @IBOutlet weak var judgeTextView: UITextView!
  
  @IBOutlet weak var starView: CosmosView!
  
  @IBOutlet weak var noCommentLabel: UILabel!
  
  @IBOutlet weak var seperateLine: UIView!
  
  @IBOutlet weak var timeLabel: UILabel!
  
  
  func setUp(starCount: Double, judge: String, classified: String, time: String) {
    
    if starCount == -0.1 {
      noCommentLabel.isHidden = false
      noCommentLabel.text = "此任務未評論"
      starView.isHidden = true
      judgeTextView.isHidden = true
    } else {
      starView.isHidden = false
      judgeTextView.isHidden = false
      noCommentLabel.isHidden = true
    }
    
    timeLabel.text = time
    
    judgeTextView.text = judge
    
    classifiedImage.image = UIImage(named: classified)
    
    classifiedImage.translatesAutoresizingMaskIntoConstraints = false
    
    seperateLine.backgroundColor = UIColor.darkGray
    
    starView.settings.updateOnTouch = false
    
    starView.rating = starCount
    
    starView.settings.totalStars = 5
    
    starView.settings.starSize = 17
    
    starView.settings.starMargin = 5
    
    starView.settings.fillMode = .precise
    
    starView.settings.emptyImage = UIImage(named: "star-2")?.withRenderingMode(.alwaysOriginal)
    
    starView.settings.filledImage = UIImage(named: "star-3")?.withRenderingMode(.alwaysOriginal)
    
  }
}
