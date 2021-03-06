//
//  PersonAboutTableViewCellTableViewCell.swift
//  Errand
//
//  Created by Jim on 2020/2/6.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit

protocol ProfileAboutManager: AnyObject {
  
  func changeAbout(tableViewCell: PersonAboutTableViewCell, about: String?, isEdit: Bool)
}

class PersonAboutTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
  @IBOutlet weak var detailLabel: UILabel!
  
  @IBOutlet weak var contTextView: UITextView!
  
  weak var delegate: ProfileAboutManager?
  
  func setUpView(isSetting: Bool, titleLabel: String, content: String) {
    contTextView.text = content
    contTextView.delegate = self
    detailLabel.text = titleLabel
    contTextView.isEditable = isSetting
    contTextView.layer.borderWidth = 1.0
    contentView.layer.cornerRadius = contentView.bounds.height / 6
    contTextView.layer.cornerRadius = contTextView.bounds.width / 25
    contTextView.layer.borderColor = isSetting ? UIColor.lightGray.cgColor : UIColor.clear.cgColor
  }
}

extension PersonAboutTableViewCell: UITextViewDelegate {
  
  func textViewDidEndEditing(_ textView: UITextView) {
    self.delegate?.changeAbout(tableViewCell: self, about: textView.text, isEdit: false)
  }
}
