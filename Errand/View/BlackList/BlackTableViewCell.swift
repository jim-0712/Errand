//
//  BlackTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/3/1.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class BlackTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
  @IBOutlet weak var personImageView: UIImageView!
  
  @IBOutlet weak var nickNameLabel: UILabel!
  
  @IBOutlet weak var emailLabel: UILabel!
  
  @IBOutlet weak var seperateLine: UIView!
  
  func setUpcell(image: String, nickname: String, email: String) {
    emailLabel.text = email
    nickNameLabel.text = nickname
    personImageView.contentMode = .scaleAspectFill
    personImageView.layer.cornerRadius = personImageView.bounds.width / 2
    personImageView.loadImage(image, placeHolder: UIImage(named: "photographer"))
  }
  
}
