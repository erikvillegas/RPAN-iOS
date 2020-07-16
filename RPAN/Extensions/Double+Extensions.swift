//
//  Double+Extensions.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

extension Double {
    /// Helper methods to return nil when a nil is inputted into a to-double initializer
    init?(_ intValue: Int?) {
        guard let intValue = intValue else {
            return nil
        }
        self.init(intValue)
    }

    /// Rounds the double to decimal places value
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
