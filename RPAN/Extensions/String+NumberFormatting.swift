//
//  String+NumberFormatting.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

extension String {
    public var stringWithOnlyNumericValues: String {
        return self.replacingOccurrences( of: "[^0-9.]", with: "", options: .regularExpression)
    }

    /// Helper methods to return nil when a nil is inputted into a to-string initializer
    init?(_ intValue: Int?) {
        guard let intValue = intValue else {
            return nil
        }
        self.init(intValue)
    }

    init?(_ substring: Substring?) {
        guard let substringValue = substring else {
            return nil
        }
        self.init(substringValue)
    }
}

extension String.SubSequence {
    public var stringWithOnlyNumericValues: String {
        return self.replacingOccurrences( of: "[^0-9.]", with: "", options: .regularExpression)
    }

    /// Helper method to return nil when a nil is inputted into a to-string initializer
    init?(_ intValue: Int?) {
        if let intValue = intValue {
            self.init(intValue)
        }
        return nil
    }
}
