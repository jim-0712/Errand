//
//  UIStoryboard+Extension.swift
//  Errand
//
//  Created by Jim on 2020/2/2.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation
import UIKit

private struct StoryboardCategory {

    static let map = "Map"

    static let missionList = "Mission"

    static let profile = "Profile"
  
    static let requester = "Requester"
}

extension UIStoryboard {

  static var map: UIStoryboard { return stStoryboard(name: StoryboardCategory.map) }

  static var missionList: UIStoryboard { return stStoryboard(name: StoryboardCategory.missionList) }

  static var profile: UIStoryboard { return stStoryboard(name: StoryboardCategory.profile) }
  
  static var requester: UIStoryboard { return stStoryboard(name: StoryboardCategory.requester) }

  private static func stStoryboard(name: String) -> UIStoryboard {

        return UIStoryboard(name: name, bundle: nil)
    }
}
