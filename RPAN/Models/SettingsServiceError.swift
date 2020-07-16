//
//  SettingsServiceError.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

enum SettingsServiceError: Error {
    case loggedOut
    case userIdNotFound
    case unableToAuth
    case unknown
}
