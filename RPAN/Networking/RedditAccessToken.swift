//
//  RedditAccessToken.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

struct RedditAccessToken: Codable {
    let value: String
    let expiration: Date
    
    var isExpired: Bool {
        return self.expiration.isInPast
    }
}
