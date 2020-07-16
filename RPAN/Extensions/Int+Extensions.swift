//
//  Int+Extensions.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

extension Int {
    /// Helper methods to return nil when a nil is inputted into a to-int initializer
    init?(_ stringValue: String?) {
        guard let stringValue = stringValue else {
            return nil
        }
        self.init(stringValue)
    }

    init?(_ doubleValue: Double?) {
        guard let doubleValue = doubleValue else {
            return nil
        }
        self.init(doubleValue)
    }

    var stringValue: String? {
        return "\(self)" // Using the constructor caused some ambiguous init errors
    }
    
    var roundedDescription: String {
        if self < 1000 {
            return String(self)
        }
        else {
            return String(format: "%.1f", Double(self)/1000.0) + "k"
        }
    }
}
