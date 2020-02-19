//
//  FriendsTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/17.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class FriendsTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
  
  var tapOnButton: (() -> Void)?
  
  @IBOutlet weak var friendPhotoImage: UIImageView!
  
  @IBOutlet weak var friendsNameLabel: UILabel!
  
  @IBOutlet weak var friendsAccountLabel: UILabel!
  
  @IBOutlet weak var chatBtn: UIButton!
  
  @IBAction func goChatBtn(_ sender: Any) {
    
    self.tapOnButton?()
    
  }
  
  func setUpCell(image: String, nickName: String, account: String) {
    friendPhotoImage.loadImage(image, placeHolder: UIImage(named: "photographer"))
    friendsNameLabel.text = nickName
    friendsAccountLabel.text = account
    friendPhotoImage.layer.cornerRadius = friendPhotoImage.bounds.width / 2
  }
  
}
