//
//  String+PurchaseID.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

extension String {
    var isAlphanumeric: Bool {
        return self.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil && self != ""
    }

    func trimmingWhitespace() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + self.lowercased().dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }

    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }

    // Adds padding to end of payload so it is in multiples of 4 (to make it a proper base64 string)
    var paddedBase64String: String {
        let remainder = self.count % 4
        if remainder > 0 {
            return self.padding(toLength: self.count + 4 - remainder, withPad: "=", startingAt: 0)
        }
        else {
            return self
        }
    }

    /// Attempts to convert an advocate's Carvana email to their name. 
    func advocateNameFromEmail() -> String {
        let username = self.replacingOccurrences(of: "@carvana.com", with: "")
        let components = username.split(separator: ".")

        guard components.count == 2 else {
            return self
        }

        return "\(components[0].capitalized) \(components[1].capitalized)"
    }

    func caseInsensitiveEquals(_ value: String) -> Bool {
        return self.caseInsensitiveCompare(value) == .orderedSame
    }

    enum TruncationPosition {
        case head
        case middle
        case tail
    }

    func truncated(limit: Int, position: TruncationPosition = .tail, leader: String = "") -> String {
        guard self.count > limit else { return self }

        switch position {
        case .head:
            return leader + self.suffix(limit)
        case .middle:
            let headCharactersCount = Int(ceil(Float(limit - leader.count) / 2.0))

            let tailCharactersCount = Int(floor(Float(limit - leader.count) / 2.0))

            return "\(self.prefix(headCharactersCount))\(leader)\(self.suffix(tailCharactersCount))"
        case .tail:
            return self.prefix(limit) + leader
        }
    }
}

extension Array where Element == String {
    func caseInsensitiveContains(value: String) -> Bool {
        return self.contains(where: { $0.caseInsensitiveEquals(value) })
    }
}

extension String {
    func removingUserSubredditPrefix() -> String {
        if self.hasPrefix("u_") {
            return String(self.dropFirst(2))
        }
        
        return self
    }
}
