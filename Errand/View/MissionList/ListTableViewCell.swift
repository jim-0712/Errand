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
  
  func detailData(tableViewCell: ListTableViewCell, nickName: String, time: Int)
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
  
  func setUp(missionImage: String, author: String, missionLabel: String, price: Int, time: String, timeInt: Int) {
    
    backgorundVisibleView.layer.shadowOpacity = 0.3
  
    backgorundVisibleView.layer.shadowOffset = CGSize(width: 3, height: 3)
    
    backgorundVisibleView.layer.shadowColor = UIColor.black.cgColor
    
    backgorundVisibleView.clipsToBounds = false
  
    backgorundVisibleView.layer.cornerRadius = 10
    
    self.timeStorage = timeInt
    
    self.author = author
    
    missionGroupImage.image = UIImage(named: missionImage)
    
    authorLabel.text = "發文者 : \(author)"
    
    missionGroupLabel.text = "任務種類 : \(missionLabel)"
    
    priceLabel.text = "價格 : \(price)"
    
    timeLabel.text = "發布時間 : \(time)"
    
    seeDetailBtn.layer.borderWidth = 1.0
    
    seeDetailBtn.layer.borderColor = UIColor(red: 110.0/255.0, green: 181.0/255.0, blue: 188.0/255.0, alpha: 1.0).cgColor
    
    seeDetailBtn.layer.cornerRadius = 10
  }
  
  @IBAction func seeDetailAction(_ sender: Any) {
    
    guard let author = self.author else { return }
    
    self.delegate?.detailData(tableViewCell: self, nickName: author, time: self.timeStorage)
  }
  
}
