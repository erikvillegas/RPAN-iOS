//
//  Listing+Extensions.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation
import reddift

extension Listing {
    func asUserSubscriptions(notify: Bool) -> [UserSubscription] {
        guard let subreddits = self.children as? [Subreddit] else {
            return []
        }
        
        return subreddits
            .filter { $0.subredditType == "user" }
            .filter { URL(string: $0.iconImg) != nil }
            .map { UserSubscription(
                username: $0.displayName.removingUserSubredditPrefix(),
                iconUrl: URL(string: $0.iconImg),
                notify: notify,
                subredditBlacklist: [],
                cooldown: false,
                sound: Constants.DefaultNotificationSoundName)
        }
    }
}
