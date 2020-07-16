//
//  UIColor+Extensions.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

// https://stackoverflow.com/a/38435309/2125328
public extension UIColor {
    /// Lightens a colour by a `percentage`.
    ///
    /// - Parameters:
    ///     - percentage: the amount to lighten a colour by.
    ///
    /// - Returns: A colour lightened by a `percentage`.
    ///
    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage))
    }

    /// Darkens a colour by a `percentage`.
    ///
    /// - Parameters:
    ///     - percentage: the amount to darken a colour by.
    ///
    /// - Returns: A colour darkened by a `percentage`.
    ///
    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage))
    }

    /// Adjusts a colour by a `percentage`.
    ///
    /// Lightening → positive percentage
    ///
    /// Darkening → negative percentage
    ///
    /// - Parameters:
    ///     - percentage: the amount to either lighten or darken a colour by.
    ///
    /// - Returns: A colour either lightened or darkened by a `percentage`.
    ///
    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                           green: min(green + percentage/100, 1.0),
                           blue: min(blue + percentage/100, 1.0),
                           alpha: alpha)
        } else {
            return nil
        }
    }
}
