//
//  MissionDetailTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/1/31.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class MissionDetailTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
      
      botLine.layer.shadowOpacity = 0.5
        
      botLine.layer.shadowOffset = CGSize(width: 3, height: 3)
      
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        botLine.layer.shadowOpacity = 0.5
          
        botLine.layer.shadowOffset = CGSize(width: 3, height: 3)
    }
  
  @IBOutlet weak var botLine: UIView!
  
  @IBOutlet weak var titleLabel: UILabel!
  
  @IBOutlet weak var lineView: UIView!
  
  @IBOutlet weak var contentLabel: UILabel!
  
  func setUp(title: String? = "", content: String? = "") {
    
    titleLabel.text = title
    
    contentLabel.text = content
    
  }
}
