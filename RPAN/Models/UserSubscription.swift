//
//  UserSubscription.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

struct UserSubscription: Codable, Equatable, Hashable {
    let username: String
    let iconUrl: URL?
    let notify: Bool
    let subredditBlacklist: [String]
    let cooldown: Bool
    let sound: String
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.username == rhs.username
    }
    
    func withNotifications(enabled: Bool) -> UserSubscription {
        return UserSubscription(
            username: self.username,
            iconUrl: self.iconUrl,
            notify: enabled,
            subredditBlacklist:
            self.subredditBlacklist,
            cooldown: self.cooldown,
            sound: self.sound)
    }
    
    func withIconUrl(iconUrl: URL?) -> UserSubscription {
        return UserSubscription(
            username: self.username,
            iconUrl: iconUrl,
            notify: self.notify,
            subredditBlacklist: self.subredditBlacklist,
            cooldown: self.cooldown,
            sound: self.sound)
    }
    
    func withSubredditBlacklist(subreddits: [String]) -> UserSubscription {
        return UserSubscription(
            username: self.username,
            iconUrl: self.iconUrl,
            notify: self.notify,
            subredditBlacklist: subreddits,
            cooldown: self.cooldown,
            sound: self.sound)
    }
    
    func withCooldown(enabled: Bool) -> UserSubscription {
        return UserSubscription(
            username: self.username,
            iconUrl: self.iconUrl,
            notify: self.notify,
            subredditBlacklist: self.subredditBlacklist,
            cooldown: enabled,
            sound: self.sound)
    }
    
    func withSound(sound: String) -> UserSubscription {
        return UserSubscription(
            username: self.username,
            iconUrl: self.iconUrl,
            notify: self.notify,
            subredditBlacklist: self.subredditBlacklist,
            cooldown: self.cooldown,
            sound: sound)
    }
    
    var soundDisplayName: String {
        return self.sound.components(separatedBy: "-").joined(separator: " ").capitalized
    }
}
