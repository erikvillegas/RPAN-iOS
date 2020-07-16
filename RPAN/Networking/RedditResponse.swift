//
//  RedditResponse.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

class RedditResponse<T: Decodable>: Decodable {
    let status: String
    let data: T
}
