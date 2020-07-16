//
//  AnalyticsService.swift
//  RPAN
//
//  Created by Erik Villegas on 7/14/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import Foundation
//import FirebaseAnalytics

final class AnalyticsService {
    static let shared = AnalyticsService()
    
    var userId: String {
        return UserDefaultsService.shared.string(forKey: .userId) ?? "N/A"
    }
    
    var username: String {
        return UserDefaultsService.shared.string(forKey: .username) ?? "N/A"
    }
    
    func logEvent(_ name: String, metadata: [String: String] = [:]) {
        var parameters = [
            "username": self.username as NSObject,
            "userId": self.userId as NSObject
        ]
        
        for (key, value) in metadata {
            parameters[key] = value as NSObject
        }
        
        // Commenting out while we figure out why I can't archive the app with this library included
        //Analytics.logEvent(name, parameters: parameters)
    }
    
    func logScreenView(_ controller: UIViewController.Type) {
        self.logEvent("Screen View - " + String(describing: controller))
    }
}
