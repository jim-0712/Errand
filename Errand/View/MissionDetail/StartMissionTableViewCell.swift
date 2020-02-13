//
//  StartMissionTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/10.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

class StartMissionTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
  
  var tapOnButton: (() -> Void)?
  
  var tapAddFriend: (() -> Void)?
  
  @IBOutlet weak var missionOwnerImage: UIImageView!
  
  @IBOutlet weak var authorImage: UIImageView!
  
  @IBOutlet weak var authorLabel: UILabel!
  
  @IBOutlet weak var classifiedImage: UIImageView!
  
  @IBOutlet weak var classifiedLabel: UILabel!
  
  @IBOutlet weak var priceImage: UIImageView!
  
  @IBOutlet weak var priceLabel: UILabel!
  
  @IBOutlet weak var chatBtn: UIButton!
  
  @IBOutlet weak var addFriendBtn: UIButton!
  
  @IBOutlet weak var pageView: UIView!
  
  func setUp(ownerImage: String, author: String, classified: String, price: Int) {
    missionOwnerImage.loadImage(ownerImage, placeHolder: UIImage(named: "photographer"))
    authorLabel.text = author
    classifiedLabel.text = classified
    priceLabel.text = "\(price)元"
    pageView.layer.cornerRadius = pageView.bounds.height / 10
    pageView.layer.shadowOpacity = 0.3
    pageView.layer.shadowOffset = CGSize(width: 3, height: 3)
    pageView.layer.shadowColor = UIColor.black.cgColor
    pageView.backgroundColor = UIColor.G1
    self.contentView.backgroundColor = .clear
  }
  
  @IBAction func chatAct(_ sender: Any) {
    self.tapOnButton?()
  }
  
  @IBAction func addFriends(_ sender: Any) {
    
    self.tapAddFriend?()
  }
  
}
