//
//  CrashService.swift
//  RPAN
//
//  Created by Erik Villegas on 7/14/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation
import FirebaseCrashlytics

final class CrashService {
    static let shared = CrashService()
    
    func setUserId(_ userId: String?) {
        if let userId = userId {
            Crashlytics.crashlytics().setUserID(userId)
        }
    }
    
    func setUserName(_ username: String?) {
        if let username = username {
            Crashlytics.crashlytics().setCustomValue(username, forKey: "username")
        }
    }
    
    func setDeviceToken(_ fcmToken: String?) {
        if let fcmToken = fcmToken {
            Crashlytics.crashlytics().setCustomValue(fcmToken, forKey: "fcmToken")
        }
    }
    
    func setUserDeviceId(_ id: String) {
        Crashlytics.crashlytics().setCustomValue(id, forKey: "deviceId")
    }
    
    func logError(with message: String, userInfo: [String: String]? = nil) {
        let error = NSError(domain: message, code: -1, userInfo: userInfo)
        Crashlytics.crashlytics().record(error: error)
        AnalyticsService.shared.logEvent("Error: \(message)", metadata: userInfo ?? [:])
    }
    
    func logError(_ error: Error, message: String) {
        Crashlytics.crashlytics().log(message)
        Crashlytics.crashlytics().record(error: error)
        AnalyticsService.shared.logEvent("Error \(message)")
    }
    
    func logMessage(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
}
