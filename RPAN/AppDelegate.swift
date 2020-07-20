//
//  AppDelegate.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import Mixpanel

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {
    
    var window: UIWindow?
    
    var keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first
        }
        else {
            return self.window
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if #available(iOS 13.0, *) {}
        else {
            
            let window = UIWindow()
            window.rootViewController = UINavigationController(rootViewController: HomeViewController())
            window.makeKeyAndVisible()
            window.tintColor = Colors.primaryOrange
            
            self.window = window
            self.window?.makeKeyAndVisible()
        }
        
        Mixpanel.initialize(token: "ed57eac8d8ec3f661d8fe52cd96c196b")
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        SettingsService.shared.createUser().done { userId in
            AnalyticsService.shared.userId = userId
        }.cauterize()
        
        SettingsService.shared.fetchAppConfiguration().done { config in
            UserDefaultsService.shared.setCodableObject(config, forKey: .appConfig)
        }.cauterize()
        
        return true
    }

    // MARK: UISceneSession Lifecycle
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // construct a hex string by converting each individual byte
        // https://www.raywenderlich.com/156966/push-notifications-tutorial-getting-started
        let pushToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        UserDefaults.standard.set(pushToken, forKey: "pushToken")
        UserDefaults.standard.synchronize()
        
        SettingsService.shared.persistPushToken(pushToken).catch { error in
            CrashService.shared.logError(error, message: "APNS token storage failure")
            self.keyWindow?.rootViewController?.showSimpleAlert(title: "Oops", message: "There was a problem registering for push notifications. Please try again later!\n\nError: \(error.localizedDescription)")
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        SettingsService.shared.persistFCMToken(fcmToken).catch { error in
            CrashService.shared.logError(error, message: "FCM token storage failure")
            self.keyWindow?.rootViewController?.showSimpleAlert(title: "Oops", message: "There was a problem registering for push notifications. Please try again later!\n\nError: \(error.localizedDescription)")
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
      
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let data = response.notification.request.content.userInfo
        
        if let url = URL(string: data["url"] as? String) {
            UIApplication.shared.open(url, options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly : true])
        }
        
        completionHandler()
    }
}

