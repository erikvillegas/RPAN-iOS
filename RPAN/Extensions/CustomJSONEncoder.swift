//
//  CustomJSONEncoder.swift
//  CarvanaCore
//
//  Created by Erik Villegas on 11/7/17.
//  Copyright © 2017 Carvana. All rights reserved.
//

import Foundation

public class CustomJSONEncoder: JSONEncoder {

    public override init() {
        super.init()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

        self.dateEncodingStrategy = .formatted(dateFormatter)
    }
}
