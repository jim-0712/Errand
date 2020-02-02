//
//  MissionContentTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/1.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class MissionContentTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
  @IBOutlet weak var titleLabel: UILabel!
  
  @IBOutlet weak var contentTextView: UITextView!
  
  func setUp(title: String, content: String) {
    
    titleLabel.text = title
    
    contentTextView.text = content
    
    contentTextView.isEditable = false
  }
}
