//
//  RequesterTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/5.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Cosmos

protocol CheckPersonalInfoManager: AnyObject {
  
  func checkTheInfo(tableViewCell: RequesterTableViewCell, index: Int)
}

class RequesterTableViewCell: UITableViewCell {
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  weak var delegate: CheckPersonalInfoManager?
  
  var index = 0
  
  @IBOutlet weak var peopleImageView: UIImageView!
  
  @IBOutlet weak var nickNameLabel: UILabel!
  
  @IBOutlet weak var backgroundPageView: UIView!
  
  @IBOutlet weak var starView: CosmosView!
  
  @IBOutlet weak var personBtn: UIButton!
  
  @IBOutlet weak var describeLabel: UILabel!
  
  @IBAction func goToPersonInfo(_ sender: Any) {
    
    self.delegate?.checkTheInfo(tableViewCell: self, index: index)
  }
  func setUp(nickName: String, starcount: Double, image: String, index: Int, taskCount: Int, noJudge: Bool) {
    
    if taskCount == 0 {
      describeLabel.text = "此用戶為新用戶"
      starView.isHidden = true
    }
    
    if noJudge {
      describeLabel.text = "此用戶尚未被評價"
      starView.isHidden = true
    } else {
      describeLabel.isHidden = true
    }
    
    self.index = index
    
    self.contentView.backgroundColor = UIColor.LG1
    
    personBtn.layer.borderColor = UIColor.G1?.cgColor
    
    personBtn.layer.borderWidth = 1.0
    
    personBtn.layer.cornerRadius = 10
    
    starView.settings.updateOnTouch = false
    
    starView.rating = starcount
    
    starView.settings.totalStars = 5
    
    starView.settings.starSize = 17
    
    starView.settings.starMargin = 5
    
    starView.settings.fillMode = .precise
    
    starView.settings.emptyImage = UIImage(named: "star-2")?.withRenderingMode(.alwaysOriginal)
    
    starView.settings.filledImage = UIImage(named: "star-3")?.withRenderingMode(.alwaysOriginal)
    
    nickNameLabel.text = nickName
    
    backgroundPageView.layer.cornerRadius =  backgroundPageView.bounds.height / 10
    
    backgroundPageView.layer.shadowOpacity = 0.5
    
    backgroundPageView.layer.shadowOffset = CGSize(width: 3, height: 3)
    
    peopleImageView.loadImage(image)
    
    peopleImageView.layer.cornerRadius = peopleImageView.bounds.width / 2
  }
}
