//
//  MissionPersonTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/1.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Kingfisher

class MissionPersonTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
  
  @IBOutlet weak var personImage: UIImageView!
  
  @IBOutlet weak var nickName: UILabel!
  
  func setUp(personURL: String, name: String) {
    
    personImage.layer.cornerRadius = personImage.bounds.height / 3
    
    personImage.loadImage(personURL, placeHolder: UIImage(named: "photographer"))
    
    nickName.text = name
  }
}
