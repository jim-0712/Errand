//
//  UIcolorExtension.swift
//  Errand
//
//  Created by Jim on 2020/2/7.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation
import UIKit

private enum GHColor: String {
    // swiftlint:disable identifier_name
    case G1
  
    case Y1
  
    case LG1
  
    case B1
  
    case LG2
  
    case DB1
    
    case BB1
  
    case LB1
  
    case CG1
}
extension UIColor {

    static let G1 = GHColor(.G1)
  
    static let LG1 = GHColor(.LG1)
  
    static let Y1 = GHColor(.Y1)
  
    static let B1 = GHColor(.B1)
  
    static let LG2 = GHColor(.LG2)
  
    static let DB1 = GHColor(.DB1)
  
    static let BB1 = GHColor(.BB1)
  
    static let LB1 = GHColor(.LB1)

    static let CG1 = GHColor(.CG1)
    // swiftlint:enable identifier_name
    private static func GHColor(_ color: GHColor) -> UIColor? {
        return UIColor(named: color.rawValue)
    }
  
  static var primary: UIColor {
    return UIColor(red: 1 / 255, green: 93 / 255, blue: 48 / 255, alpha: 1)
    
  }
  
  static var incomingMessage: UIColor {
    return UIColor(red: 230 / 255, green: 230 / 255, blue: 230 / 255, alpha: 1)
  }
    
}
