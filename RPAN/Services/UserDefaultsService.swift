//
//  UserDefaultsService.swift
//  RPAN
//
//  Created by Erik Villegas on 7/11/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

enum UserDefaultsKey: String {
    case userSubscriptions
    case currentUser
    case username
    case userId
    case seenNotificationPrePrompt
    case promptedForNotifications
    case globalNotificationsOn
    case unsubscribedUserList
    case appConfig
    case redditAccessToken
    case moderatedSubreddits
    case rpanSubreddits
}

final class UserDefaultsService {
    static let shared = UserDefaultsService()
    public let userDefaults = UserDefaults.standard
    
    func settingExists(forKey key: UserDefaultsKey) -> Bool {
        return userDefaults.object(forKey: key.rawValue) != nil
    }
    
    func set(_ value: String, forKey key: UserDefaultsKey) {
        self.setObject(value, forKey: key)
    }
    
    func set(_ value: Int, forKey key: UserDefaultsKey) {
        self.setObject(value, forKey: key)
    }
    
    func set(_ value: Float, forKey key: UserDefaultsKey) {
        self.setObject(value, forKey: key)
    }
    
    func set(_ value: Bool, forKey key: UserDefaultsKey) {
        self.setObject(value, forKey: key)
    }
    
    func add(_ element: String, forKey key: UserDefaultsKey) {
        if var existingArray = self.object(forKey: key) as? [String] {
            existingArray += element
            self.setObject(existingArray, forKey: key)
        }
        else {
            self.setObject([element], forKey: key)
        }   
    }
    
    func add(_ elements: [String], forKey key: UserDefaultsKey) {
        if var existingArray = self.object(forKey: key) as? [String] {
            existingArray += elements
            self.setObject(existingArray, forKey: key)
        }
        else {
            self.setObject(elements, forKey: key)
        }
    }
    
    func setObject(_ value: Any, forKey key: UserDefaultsKey) {
        userDefaults.set(value, forKey: key.rawValue)
        userDefaults.synchronize()
    }
    
    func bool(forKey key: UserDefaultsKey) -> Bool {
        return userDefaults.bool(forKey: key.rawValue)
    }
    
    func string(forKey key: UserDefaultsKey) -> String? {
        return userDefaults.string(forKey: key.rawValue)
    }
    
    func integer(forKey key: UserDefaultsKey) -> Int? {
        return userDefaults.integer(forKey: key.rawValue)
    }
    
    func float(forKey key: UserDefaultsKey) -> Float? {
        return userDefaults.float(forKey: key.rawValue)
    }
    
    func array(forKey key: UserDefaultsKey) -> [String]? {
        return self.object(forKey: key) as? [String]
    }
    
    func object(forKey key: UserDefaultsKey) -> Any? {
        return userDefaults.object(forKey: key.rawValue)
    }
    
    func removeObject(forKey key: UserDefaultsKey) {
        userDefaults.removeObject(forKey: key.rawValue)
        userDefaults.synchronize()
    }
    
    func removeAllKeys(exceptFor exclusions: [UserDefaultsKey] = []) {
        for key in userDefaults.dictionaryRepresentation().keys {
            guard let userDefaultsKey = UserDefaultsKey(rawValue: key) else {
                continue // only clear out our custom user defaults
            }
            
            if !exclusions.contains(userDefaultsKey) {
                self.removeObject(forKey: userDefaultsKey)
            }
        }
    }
    
    /// Encodes an object to user defaults using a specified key
    @discardableResult
    func setCodableObject<T: Codable>(_ object: T, forKey key: UserDefaultsKey) -> Bool {
        guard let objectData = try? CustomJSONEncoder().encode(object) else {
            return false
        }

        self.userDefaults.set(objectData, forKey: key.rawValue)
        self.userDefaults.synchronize()

        return true
    }

    /// Decodes an object from user defaults using a specified key
    @discardableResult
    func codableObject<T: Codable>(type: T.Type, forKey key: UserDefaultsKey) -> T? {
        guard let objectData = self.userDefaults.data(forKey: key.rawValue) else {
            return nil
        }

        guard let object = try? CustomJSONDecoder().decode(T.self, from: objectData) else {
            return nil
        }

        return object
    }
}
