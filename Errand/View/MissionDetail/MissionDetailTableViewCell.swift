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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
  
  @IBOutlet weak var detailLabel: UILabel!
  
  @IBOutlet weak var lineView: UIView!
  
  @IBOutlet weak var contentLabel: UILabel!
}
