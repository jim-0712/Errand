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
  
  @IBOutlet weak var logOutBtn: UIButton!
  
    @IBAction func tapOnLogOut(_ sender: Any) {
      self.touchHandler?()
  }
  
  func setUp(isTourist: Bool) {
    
    let title = isTourist ? "登入" : "登出"
    
    logOutBtn.setTitle(title, for: .normal)
  
  }
}
