//
//  SwiftMessage.swift
//  Errand
//
//  Created by Jim on 2020/2/22.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation
import SwiftMessages

class SwiftMes {
  
  static let shared = SwiftMes()
  
  private init() { }
  
  func showErrorMessage(body: String, seconds: Double) {
    let view = MessageView.viewFromNib(layout: .cardView)
    view.configureContent(title: "注意", body: body)
    view.button?.isHidden = true
    view.configureTheme(.error)
    view.configureDropShadow()
    var config = SwiftMessages.Config()
    config.presentationStyle = .bottom
    config.duration = .seconds(seconds: seconds)
    config.interactiveHide = false
    config.preferredStatusBarStyle = .lightContent
    SwiftMessages.show(config: config, view: view)
  }
  
  func showWarningMessage(body: String, seconds: Double) {
    let view = MessageView.viewFromNib(layout: .cardView)
    view.configureContent(title: "注意", body: body)
    view.button?.isHidden = true
    view.configureTheme(.warning)
    view.configureDropShadow()
    var config = SwiftMessages.Config()
    config.presentationStyle = .bottom
    config.duration = .seconds(seconds: seconds)
    config.interactiveHide = false
    config.preferredStatusBarStyle = .lightContent
    SwiftMessages.show(config: config, view: view)
  }
}
