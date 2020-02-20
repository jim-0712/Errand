//
//  SignOutTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/19.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class SignOutTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
  
  var taponSignOut: (() -> Void)?
  
  @IBOutlet weak var signOutBtn: UIButton!
  
  @IBAction func tapOnSignOut(_ sender: Any) {
    
    self.taponSignOut?()
  }
  
}
