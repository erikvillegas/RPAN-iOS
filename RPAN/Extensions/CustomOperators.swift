//
//  CustomOperators.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

/// This makes it possible to use `+=` when adding elements into an array
/// Otherwise we have to use the .append function which doesn't look as pretty
func += <V> ( left: inout [V], right: V) {
    left.append(right)
}

/// Sames as above, but this will ignore nil elements when attempting to insert them
/// into a non-nil array.
func += <V> ( left: inout [V], right: V?) {
    if let right = right {
        left.append(right)
    }
}
