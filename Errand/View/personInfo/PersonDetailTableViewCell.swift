//
//  PersonDetailTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/6.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

protocol ProfileManager: AnyObject {
  
  func changeName(tableViewCell: PersonDetailTableViewCell, name: String?, isEdit: Bool)
}

class PersonDetailTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
  
  @IBOutlet weak var detailLabel: UILabel!
  
  @IBOutlet weak var contentText: UITextView!
  
  @IBOutlet weak var botLineView: UIView!
  
  weak var delegate: ProfileManager?
  
  func setUpView(isSetting: Bool, detailTitle: String, content: String) {
    contentText.text = content
    contentText.delegate = self
    detailLabel.text = detailTitle
    contentText.layer.borderWidth = 1.0
    contentText.isScrollEnabled = false
    contentText.isEditable = isSetting ? true : false
    contentText.layer.cornerRadius = contentText.bounds.width / 25
    contentText.layer.borderColor = isSetting ? UIColor.lightGray.cgColor : UIColor.clear.cgColor
  }
}

extension PersonDetailTableViewCell: UITextViewDelegate {
  func textViewDidEndEditing(_ textView: UITextView) {
    self.delegate?.changeName(tableViewCell: self, name: textView.text, isEdit: false)
  }
  func textViewDidChange(_ textView: UITextView) {
    self.delegate?.changeName(tableViewCell: self, name: textView.text, isEdit: false)
  }
}
