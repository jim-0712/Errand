//
//  LogoutTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/25.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class LogoutTableViewCell: UITableViewCell {
  
  var touchHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func tapOnLogOut(_ sender: Any) {
      self.touchHandler?()
  }
}
