//
//  WhiteSpace.swift
//  Errand
//
//  Created by Jim on 2020/2/6.
//  Copyright © 2020 Jim. All rights reserved.
//

import Foundation

extension String {
    func isEmptyOrWhitespace() -> Bool {

        // Check empty string
        if self.isEmpty {
            return true
        }
        // Trim and check empty string
        return (self.trimmingCharacters(in: .whitespaces) == "")
    }
}
