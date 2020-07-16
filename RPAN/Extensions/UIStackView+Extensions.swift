//
//  UIStackView+Extensions.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import TinyConstraints

extension UIStackView {
    /// This method should really have been included out of the box!
    func addArrangedSubviews(_ views: [UIView]) {
        for view in views {
            self.addArrangedSubview(view)
        }
    }

    func applyInsets(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) {
        self.layoutMargins = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        self.isLayoutMarginsRelativeArrangement = true
    }

    /// Inserts a background view with the specified color
    func addBackground(color: UIColor, cornerRadius: CGFloat) {
        let subView = UIView(frame: self.bounds)
        subView.backgroundColor = color
        subView.layer.cornerRadius = cornerRadius
        subView.layer.masksToBounds = true
        self.insertSubview(subView, at: 0)
        subView.edgesToSuperview()
    }
}
