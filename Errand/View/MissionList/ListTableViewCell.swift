//
//  ListTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/1/30.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Kingfisher

protocol DetailManager: AnyObject {
  
  func detailData(tableViewCell: ListTableViewCell, uid: String, time: Int)
}

class ListTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
  
        // Configure the view for the selected state
    }
  
  @IBOutlet weak var seeDetailBtn: UIButton!
  
  @IBOutlet weak var backgorundVisibleView: UIView!
  
  @IBOutlet weak var missionGroupImage: UIImageView!
  
  @IBOutlet weak var authorLabel: UILabel!
  
  @IBOutlet weak var missionGroupLabel: UILabel!
  
  @IBOutlet weak var priceLabel: UILabel!
  
  @IBOutlet weak var timeLabel: UILabel!
  
  weak var delegate: DetailManager?
  
  var timeStorage = 1
  
  var author: String?
  
  var uid = ""
  
  func setUp(missionImage: String, author: String, missionLabel: String, priceTimeInt: [Int], time: String) {
    
    self.author = author
    
    self.timeStorage = priceTimeInt[1]
    
    timeLabel.text = "發布時間 : \(time)"
    
    seeDetailBtn.layer.borderWidth = 1.0
    
    seeDetailBtn.layer.cornerRadius = 10
    
    authorLabel.text = "發文者 : \(author)"
    
    priceLabel.text = "價格 : \(priceTimeInt[0])"
    backgorundVisibleView.clipsToBounds = false
    
    backgorundVisibleView.layer.cornerRadius = 10
    
    backgorundVisibleView.layer.shadowOpacity = 0.3
    
    missionGroupLabel.text = "任務種類 : \(missionLabel)"
    
    seeDetailBtn.layer.borderColor = UIColor.G1?.cgColor
    
    missionGroupImage.image = UIImage(named: missionImage)
    
    backgorundVisibleView.layer.shadowColor = UIColor.black.cgColor
  
    backgorundVisibleView.layer.shadowOffset = CGSize(width: 3, height: 3)
    
  }
  
  @IBAction func seeDetailAction(_ sender: Any) {
    
    self.delegate?.detailData(tableViewCell: self, uid: uid, time: self.timeStorage)
  }
  
}
