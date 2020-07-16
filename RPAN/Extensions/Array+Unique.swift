//
//  Array+Unique.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

extension Array {
    // Returns an uniqued array by a specific property in each object
    // Credit: https://stackoverflow.com/a/45023706/2125328
    func unique<T: Hashable>(by: ((Element) -> (T)), favoringLatter: Bool = false) -> [Element] {
        var set = Set<T>() //the unique list kept in a Set for fast retrieval
        var arrayOrdered = [Element]() //keeping the unique list of elements but ordered

        let input = favoringLatter ? self.reversed() : self

        for value in input {
            if !set.contains(by(value)) {
                set.insert(by(value))
                arrayOrdered.append(value)
            }
        }

        return arrayOrdered
    }
}
