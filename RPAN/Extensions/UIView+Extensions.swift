//
//  UIView+Extensions.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

extension UIView {
    static var reuseId: String {
        return String(describing: self.self)
    }
}
