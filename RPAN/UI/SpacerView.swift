//
//  HomeViewController.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

/**
 This is a view that can be used in conjunction with a UIStackView to fill the remaining space.
 So if you'd like to leverage the ease/power of UIStackView but don't want things to take up the whole view (e.g. top align or bottom align),
 this is a useful thing to fill the remaining space to allow this to happen
*/
class SpacerView: UIView {

    init(_ axis: NSLayoutConstraint.Axis) {
        super.init(frame: .zero)

        self.setContentHuggingPriority(.defaultLow, for: axis)
        self.backgroundColor = UIColor.clear
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    class var horizontal: SpacerView {
        return SpacerView(.horizontal)
    }

    class var vertical: SpacerView {
        return SpacerView(.vertical)
    }
}
