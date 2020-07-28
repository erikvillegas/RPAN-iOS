//
//  Colors.swift
//  RPAN
//
//  Created by Erik Villegas on 7/10/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

struct Colors {
    /// #FF4500
    static let primaryOrange = #colorLiteral(red: 1, green: 0.2705882353, blue: 0, alpha: 1)
    
    /// #00E018
    static let primaryGreen = #colorLiteral(red: 0, green: 0.8784313725, blue: 0.09411764706, alpha: 1)

    /// #202125
    static var reallyDarkGray = #colorLiteral(red: 0.1254901961, green: 0.1294117647, blue: 0.1450980392, alpha: 1)
    /// #757989
    static let darkGray = #colorLiteral(red: 0.4588235294, green: 0.4745098039, blue: 0.537254902, alpha: 1)
    /// #AAB1C7
    static let mediumGray = #colorLiteral(red: 0.6666666667, green: 0.6941176471, blue: 0.7803921569, alpha: 1)
    /// #D9DDE9
    static let regularGray = #colorLiteral(red: 0.8509803922, green: 0.8666666667, blue: 0.9137254902, alpha: 1)
    /// #F4F8FA
    static let lightGray = #colorLiteral(red: 0.9568627451, green: 0.9725490196, blue: 0.9803921569, alpha: 1)
    /// #FCFCFC
    static let eggshellWhite = #colorLiteral(red: 0.9882352941, green: 0.9882352941, blue: 0.9882352941, alpha: 1)
    /// #EEEEEE
    static let chalkWhite = #colorLiteral(red: 0.9333333333, green: 0.9333333333, blue: 0.9333333333, alpha: 1)

    static let white = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    static let black = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    static let clear = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
    
    static var dynamicSystemTitle: UIColor {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.keyWindow!.traitCollection.userInterfaceStyle == .dark ? #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1) : #colorLiteral(red: 0.1254901961, green: 0.1294117647, blue: 0.1450980392, alpha: 1)
        }
        else {
            return #colorLiteral(red: 0.1254901961, green: 0.1294117647, blue: 0.1450980392, alpha: 1)
        }
    }
    
    static var dynamicCellSelected: UIColor {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.keyWindow!.traitCollection.userInterfaceStyle == .dark ? #colorLiteral(red: 0.1254901961, green: 0.1294117647, blue: 0.1450980392, alpha: 1) : #colorLiteral(red: 0.8887297924, green: 0.9022736502, blue: 0.9130346439, alpha: 1)
        }
        else {
            return #colorLiteral(red: 0.8887297924, green: 0.9022736502, blue: 0.9130346439, alpha: 1)
        }
    }
    
    static var dynamicThumbnailHighlight: UIColor {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.keyWindow!.traitCollection.userInterfaceStyle == .dark ? #colorLiteral(red: 0.1851377778, green: 0.1911447847, blue: 0.2161189265, alpha: 1) : #colorLiteral(red: 0.9568627451, green: 0.9725490196, blue: 0.9803921569, alpha: 1)
        }
        else {
            return #colorLiteral(red: 0.9568627451, green: 0.9725490196, blue: 0.9803921569, alpha: 1)
        }
    }
}
