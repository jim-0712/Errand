//
//  DoubleExtension.swift
//  Errand
//
//  Created by Jim on 2020/2/3.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation

extension Double {
    func toInt() -> Int? {
        if self >= Double(Int.min) && self < Double(Int.max) {
            return Int(self)
        } else {
            return nil
        }
    }
}
