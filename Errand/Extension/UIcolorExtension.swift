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
  
    case LG1
}
extension UIColor {

    static let G1 = GHColor(.G1)
  
    static let LG1 = GHColor(.LG1)

    // swiftlint:enable identifier_name
    private static func GHColor(_ color: GHColor) -> UIColor? {
        return UIColor(named: color.rawValue)
    }
    
}
