//
//  Dictionary+Extensions.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

extension Dictionary where Key: Hashable, Value: Any {

    /// Un-nests a dictionary of dictionaries/arrays by moving nested values to the top level
    func flattened() -> Self {
        var result = Self()
        for (outerKey, outerValue) in self {
            if let innerDict = outerValue as? [Key: Value] {
                for (innerKey, innerValue) in innerDict.flattened() {
                    guard let key = "\(outerKey) / \(innerKey)" as? Key else { continue }
                    result[key] = innerValue
                }
            }
            else if let innerArray = outerValue as? [Value] {
                for (index, innerValue) in innerArray.enumerated() {
                    guard let key = "\(outerKey) [\(index)]" as? Key else { continue }
                    result[key] = innerValue
                }
            }
            else {
                result[outerKey] = outerValue
            }
        }

        print(result)

        return result
    }
}
