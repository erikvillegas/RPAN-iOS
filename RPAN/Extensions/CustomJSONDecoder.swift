//
//  CustomJSONDecoder.swift
//  CarvanaCore
//
//  Created by Erik Villegas on 10/8/17.
//  Copyright © 2017 Carvana. All rights reserved.
//

import Foundation
import SwiftDate

public class CustomJSONDecoder: JSONDecoder {

    override public init() {
        super.init()
        // Set the default date decoding strategy.
        // This allows us more control on how Date types are decoded within models.
        // In this case, we're using the SwiftDate library to do the heavy-lifting
        self.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            if let stringValue = try? container.decode(String.self) {

                var dateFormats = [
                    "yyyy-MM-dd'T'HH:mm:ssSSSSSSS",
                    "yyyy-MM-dd'T'HH:mm:ss"
                ]

                dateFormats.append(contentsOf: DateFormats.autoFormats)

                if let date = stringValue.toDate(dateFormats, region: Region.UTC)?.date {
                    return date
                }
                // fallback to possible Unix Timestamp string
                else if let intValue = Int(stringValue) {
                    return Date(timeIntervalSince1970: TimeInterval(intValue))
                }

                let debugDescription = "Date is not in ISO8601 format: \(stringValue)"
                throw DecodingError.dataCorruptedError(in: container, debugDescription: debugDescription)
            }
            // check for possible Unix Timestamp integer or Double
            else if let intValue = try? container.decode(Int.self) {
                return Date(timeIntervalSince1970: TimeInterval(intValue))
            }
            else if let doubleValue = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: TimeInterval(doubleValue))
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unexpected date format")
        }
    }
}
