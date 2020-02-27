//
//  PhotoTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/6.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class PhotoTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
  
  @IBOutlet weak var personPhotoImage: UIImageView!
  
  @IBOutlet weak var choosePhotoBtn: UIButton!
  
  @IBOutlet weak var nickNameLabel: UILabel!
  
  @IBOutlet weak var emailLabel: UILabel!
  
  func setUpView(personPhoto: String, nickName: String, email: String) {
    personPhotoImage.loadImage(personPhoto, placeHolder: UIImage(named: "photographer"))
    personPhotoImage.layer.cornerRadius = personPhotoImage.bounds.width / 2
    personPhotoImage.contentMode = .scaleAspectFill
    nickNameLabel.text = nickName
    emailLabel.text = email
  }
}
