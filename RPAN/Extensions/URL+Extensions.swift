//
//  URL+Extensions.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

extension URL {

    /// Allows optional argument when creating a URL
    init?(string: String?) {
        guard let s = string else {
            return nil
        }
        self.init(string: s)
    }
}
