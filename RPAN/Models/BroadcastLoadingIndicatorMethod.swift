//
//  BroadcastLoadingIndicatorMethod.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

enum BroadcastLoadingIndicatorMethod {
    case showIfEmpty(message: String)
    case showImmediately(message: String)
    case hide
}
