//
//  JGProgressHUDWrapper.swift
//  Errand
//
//  Created by Jim on 2020/1/15.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation
import JGProgressHUD

class LKProgressHUD {

    static let shared = LKProgressHUD()

    private init() { }

    let hud = JGProgressHUD(style: .dark)

  static func showSuccess(text: String, controller: UIViewController) {

        if !Thread.isMainThread {

            DispatchQueue.main.async {
              showSuccess(text: text, controller: controller)
            }

            return
        }

        shared.hud.textLabel.text = text

        shared.hud.indicatorView = JGProgressHUDSuccessIndicatorView()

        shared.hud.show(in: controller.view)

        shared.hud.dismiss(afterDelay: 1.5)
    }

  static func showFailure(text: String, controller: UIViewController) {

        if !Thread.isMainThread {

            DispatchQueue.main.async {
              showFailure(text: text, controller: controller)
            }

            return
        }

        shared.hud.textLabel.text = text

        shared.hud.indicatorView = JGProgressHUDErrorIndicatorView()

        shared.hud.show(in: controller.view)

        shared.hud.dismiss(afterDelay: 1.5)
    }

  static func show(controller: UIViewController) {

        if !Thread.isMainThread {

            DispatchQueue.main.async {
                show(controller: controller)
            }

            return
        }

        shared.hud.indicatorView = JGProgressHUDIndeterminateIndicatorView()

        shared.hud.textLabel.text = "Loading"

        shared.hud.show(in: controller.view)
    }

    static func dismiss() {

        if !Thread.isMainThread {

            DispatchQueue.main.async {
                dismiss()
            }

            return
        }

        shared.hud.dismiss()
    }
}
