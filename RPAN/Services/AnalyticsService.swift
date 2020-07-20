//
//  AnalyticsService.swift
//  RPAN
//
//  Created by Erik Villegas on 7/14/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import Foundation
import Mixpanel

final class AnalyticsService {
    static let shared = AnalyticsService()
    
    var userId: String {
        get {
            return UserDefaultsService.shared.string(forKey: .userId) ?? "N/A"
        }
        set {
            Mixpanel.mainInstance().identify(distinctId: newValue)
            Mixpanel.mainInstance().registerSuperProperties(["UserId": newValue])
        }
    }
    
    var username: String {
        get {
            return UserDefaultsService.shared.string(forKey: .username) ?? "N/A"
        }
        set {
            Mixpanel.mainInstance().registerSuperProperties(["Username": newValue])
        }
    }
    
    func logEvent(_ name: String, metadata: [String: String] = [:]) {
        var parameters = [String: String]()
        
        for (key, value) in metadata {
            parameters[key] = value
        }
        
        Mixpanel.mainInstance().track(event: name, properties: parameters)
    }
    
    func logScreenView(_ controller: UIViewController.Type) {
        self.logEvent("Screen View - " + String(describing: controller))
    }
}
