//
//  UIviewControllerExtension.swift
//  Errand
//
//  Created by Jim on 2020/2/15.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation
import UIKit
import MarqueeLabel

extension UITabBarController {
  func showNotificationView(isON: Bool) {
    let notiView = UIView(frame: CGRect(x: 10, y: 35, width: self.view.frame.size.width, height: 50))
    notiView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
    notiView.backgroundColor = .clear
    self.view.addSubview(notiView)
    
    let alert = UIImageView()
    alert.image = UIImage(named: "bell")
    
    let lengthyLabel = MarqueeLabel()
    lengthyLabel.type = .continuous
    lengthyLabel.speed = .duration(3.0)
    lengthyLabel.animationCurve = .easeInOut
    lengthyLabel.fadeLength = 0.0
    lengthyLabel.leadingBuffer = 5.0
    lengthyLabel.trailingBuffer = 5.0
    lengthyLabel.backgroundColor = .white
    lengthyLabel.text = " 提醒親愛的用戶，您的任務進行中   "
    
    notiView.addSubview(lengthyLabel)
    lengthyLabel.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      lengthyLabel.centerXAnchor.constraint(equalTo: notiView.centerXAnchor, constant: 0),
      lengthyLabel.centerYAnchor.constraint(equalTo: notiView.centerYAnchor, constant: 0),
      lengthyLabel.heightAnchor.constraint(equalToConstant: 50),
      lengthyLabel.widthAnchor.constraint(equalToConstant: 280)
    ])
    
    notiView.addSubview(alert)
    alert.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      alert.trailingAnchor.constraint(equalTo: lengthyLabel.leadingAnchor, constant: 0),
      alert.centerYAnchor.constraint(equalTo: lengthyLabel.centerYAnchor),
      alert.widthAnchor.constraint(equalToConstant: 40),
      alert.heightAnchor.constraint(equalToConstant: 40)
    ])
    
    if isON {
      alert.isHidden = !isON
      notiView.isHidden = !isON
      lengthyLabel.isHidden = !isON
    } else {
      alert.isHidden = isON
      notiView.isHidden = isON
      lengthyLabel.isHidden = isON
    }
  }
}
