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
  @IBOutlet weak var leftBeeImage: UIImageView!
  
  @IBOutlet weak var rightBeeImage: UIImageView!
  
  @IBOutlet weak var personPhotoImage: UIImageView!
  
  @IBOutlet weak var choosePhotoBtn: UIButton!
  
  @IBOutlet weak var nickNameLabel: UILabel!
  
  @IBOutlet weak var emailLabel: UILabel!
  
  func setUpView(isRequester: Bool, personPhoto: String, nickName: String, email: String) {
    
    emailLabel.text = email
    nickNameLabel.text = nickName
    choosePhotoBtn.isHidden = isRequester
    personPhotoImage.contentMode = .scaleAspectFill
    personPhotoImage.layer.cornerRadius = personPhotoImage.bounds.width / 2
    personPhotoImage.loadImage(personPhoto, placeHolder: UIImage(named: "photographer"))
  }
}
