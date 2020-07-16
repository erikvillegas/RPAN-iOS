//
//  KeyedDecodingContainerExtensions.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

extension KeyedDecodingContainer {
    /// Simplified decode API. Transforms this:
    /// self.myString = try container.decode(String.self, key: .myStringKey)
    /// to this:
    /// self.myString = try container.decode(.myStringKey)
    /// type inference FTW
    public func decode<T>(_ key: KeyedDecodingContainer.Key) throws -> T where T: Decodable {
        return try decode(T.self, forKey: key)
    }

    public func decodeIfPresent<T>(_ key: KeyedDecodingContainer.Key) throws -> T? where T: Decodable {
        return try decodeIfPresent(T.self, forKey: key)
    }
}
