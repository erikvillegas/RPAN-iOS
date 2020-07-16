//
//  PushService.swift
//  RPAN
//
//  Created by Erik Villegas on 7/11/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation
import UserNotifications
import PromiseKit
import Device

class PushService {
    class func notificationsEnabled() -> Guarantee<Bool> {
        return self.getAuthorizationStatus().map { $0 == .authorized }
    }
    
    class func registerForRemoteNotifications() {
        guard !Device.isSimulator() else { return }
        
        self.requestAuthorizationIfNeeded().done { granted -> Void in
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
                AnalyticsService.shared.logEvent("Notifications Granted")
            }
            else {
                AnalyticsService.shared.logEvent("Notifications Not Granted")
            }
        }.cauterize()
        
        AnalyticsService.shared.logEvent("Notification Prompt")
    }

    class func requestAuthorizationIfNeeded() -> Promise<Bool> {
        return self.getAuthorizationStatus().then { status -> Promise<Bool> in
            guard status == .notDetermined else {
                return Promise.value(status == .authorized)
            }

            return self.requestAuthorization(options: [.alert, .sound, .badge])
        }
    }

    internal class func getAuthorizationStatus() -> Guarantee<UNAuthorizationStatus> {
        return Guarantee { resolver in
            UNUserNotificationCenter.current().getNotificationSettings { resolver($0.authorizationStatus) }
        }
    }

    internal class func requestAuthorization(options: UNAuthorizationOptions) -> Promise<Bool> {
        return Promise { seal in
            UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
                if let error = error {
                    seal.reject(error)
                }
                else {
                    seal.fulfill(granted)
                }
            }
        }
    }
}
