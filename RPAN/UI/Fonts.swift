//
//  HomeViewController.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

enum Fonts: String {
    case regular
    case bold
    case italic
    
    // default font sizes when Dynamic Type is at default settings
    private static let textStyleSizeMappings: [UIFont.TextStyle: CGFloat] = [
        .largeTitle: 34.0,
        .title1: 26.0,
        .title2: 22.0,
        .title3: 20.0,
        .body: 18.0,
        .callout: 16.0,
        .subheadline: 14.0,
        .footnote: 12.0,
        .caption1: 11.0,
        .caption2: 10.0,
    ]
    
    var size34: UIFont { return self.style(.largeTitle) }
    var size26: UIFont { return self.style(.title1) }
    var size22: UIFont { return self.style(.title2) }
    var size20: UIFont { return self.style(.title3) }
    var size18: UIFont { return self.style(.body) }
    var size16: UIFont { return self.style(.callout) }
    var size14: UIFont { return self.style(.subheadline) }
    var size12: UIFont { return self.style(.footnote) }
    var size11: UIFont { return self.style(.caption1) }
    var size10: UIFont { return self.style(.caption2) }

    /// Returns a font scaled to match the user's Dynamic Type setting
    private func style(_ style: UIFont.TextStyle) -> UIFont {
        let font = UIFont.preferredFont(forTextStyle: style)
        
        switch self {
        case .regular:
            return font
        case .bold:
            return font.bold()
        case .italic:
            return font.italic()
        }
    }
}

extension UIFont {
    func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: 0) //size 0 means keep the size as it is
    }

    func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }

    func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }
}
