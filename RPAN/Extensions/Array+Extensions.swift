//
//  Array+Extensions.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

extension Array {
    /// Splits an array into halves, favoring left side when odd
    /// https://stackoverflow.com/a/32074739/2125328
    func splitInHalf() -> (left: [Element], right: [Element]) {
        let count = self.count
        let half = Int(round(Double(count) / 2.0))
        let leftSplit = self[0 ..< half]
        let rightSplit = self[half ..< count]
        return (left: Array(leftSplit), right: Array(rightSplit))
    }

    /// Chunks an array into groups of similar size
    /// Source: https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }

    func nilIfEmpty() -> [Element]? {
        return self.isEmpty ? nil : self
    }

    /// Flattens an array of arrays of the same element into a single array
    static func flatten(_ arrays: [Element]...) -> [Element] {
        var result = [Element]()

        for array in arrays {
            result += array // custom operator, see CustomOperators.swift
        }

        return result
    }

    func grouped<T>(by criteria: (Element) -> T) -> [T: [Element]] {
        var groups = [T: [Element]]()
        for element in self {
            let key = criteria(element)
            if groups.keys.contains(key) == false {
                groups[key] = [Element]()
            }
            groups[key]?.append(element)
        }
        return groups
    }
}

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}
