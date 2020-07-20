//
//  SettingsService.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation
import Alamofire
import FirebaseFirestore
import FirebaseAuth
import PromiseKit
import Device
import reddift

class SettingsService {
    static let shared = SettingsService()
    let loginService = LoginService.shared
    
    var savedUserSubscriptions: [UserSubscription] {
        get { return UserDefaultsService.shared.codableObject(type: [UserSubscription].self, forKey: .userSubscriptions) ?? [] }
        set { UserDefaultsService.shared.setCodableObject(newValue, forKey: .userSubscriptions) }
    }
    
    func docId(_ userSubscription: UserSubscription, _ userId: String) -> String {
        return userId + "+" + userSubscription.username
    }
    
    @discardableResult
    func createUser() -> Promise<String> {
        return self.ensureFirebaseAuth().then { userId -> Promise<String> in
            UserDefaultsService.shared.set(userId, forKey: .userId)
            CrashService.shared.setUserId(userId)
            
            let db = Firestore.firestore()
            return db.collection("users").document(userId).setData([
                "userId": userId,
                "simulator": Device.isSimulator()
                ], merge: true)
            .map {
                return userId
            }
        }
    }
    
    @discardableResult
    func associateUsernameToCurrentUser(_ username: String) -> Promise<Void> {
        CrashService.shared.setUserName(username)
        
        return self.ensureFirebaseAuth().then { userId -> Promise<Void> in
            let db = Firestore.firestore()
            return db.collection("users").document(userId).setData([
                "username": username,
            ], merge: true)
        }
    }
    
    func persistPushToken(_ pushToken: String) -> Promise<Void> {
        guard let userId = UserDefaultsService.shared.string(forKey: .userId) else {
            return Promise(error: SettingsServiceError.userIdNotFound)
        }
        
        return self.ensureFirebaseAuth().then { _ -> Promise<Void> in
            let db = Firestore.firestore()
            return db.collection("users").document(userId).setData([
                "pushToken": pushToken
            ], merge: true)
        }
    }
    
    func persistFCMToken(_ fcmToken: String) -> Promise<Void> {
        CrashService.shared.setDeviceToken(fcmToken)
        
        guard let userId = UserDefaultsService.shared.string(forKey: .userId) else {
            return Promise(error: SettingsServiceError.userIdNotFound)
        }
        
        return self.ensureFirebaseAuth().then { _ -> Promise<Void> in
            let db = Firestore.firestore()
            return db.collection("users").document(userId).setData([
                "fcmToken": fcmToken
            ], merge: true)
        }
    }
    
    func importUserSubscriptions() -> Promise<[UserSubscription]> {
        guard let (_, token) = self.loginService.loggedInUser else {
            return Promise(error: SettingsServiceError.loggedOut)
        }
        
        return self.importUserSubscriptionsRecursively(session: Session(token: token), iteration: 1).then { userSubscriptions -> Promise<[UserSubscription]> in
            print("compiled \(userSubscriptions.count) userSubscriptions")
            
            var userSubscriptionsUpdated = userSubscriptions
            
            // ensure we don't accidentally re-import a user they've specifically unsubscribed from
            let unsubscribedUserList = UserDefaultsService.shared.array(forKey: .unsubscribedUserList) ?? []
            userSubscriptionsUpdated.removeAll(where: { unsubscribedUserList.contains($0.username) })
            
            return self.persistFavorites(userSubscriptions: userSubscriptionsUpdated)
        }
    }
    
    /// Recursive function to load all user subscriptions. Needed since Reddit API only returns 25 per page
    /// `iteration` records which iteration we're currently on to prevent infinite loops
    /// https://github.com/mxcl/PromiseKit/issues/623
    func importUserSubscriptionsRecursively(
        session: reddift.Session,
        existingUserSubscriptions: [UserSubscription] = [],
        paginator: Paginator = Paginator(),
        iteration: Int) -> Promise<[UserSubscription]> {
        
        return self.importUserSubscriptionsPaginated(
            session: session,
            existingUserSubscriptions: existingUserSubscriptions,
            paginator: paginator,
            iteration: iteration)
        .then { userSubscriptions, newPaginator, iteration -> Promise<[UserSubscription]> in
            if newPaginator.isVacant || iteration > 10 {
                return Promise.value(userSubscriptions)
            }
            else {
                return self.importUserSubscriptionsRecursively(session: session, existingUserSubscriptions: userSubscriptions, paginator: newPaginator, iteration: iteration).map { $0 }
            }
        }
    }
    
    /// Fetches a page of user subscriptions
    func importUserSubscriptionsPaginated(
        session: reddift.Session,
        existingUserSubscriptions: [UserSubscription] = [],
        paginator: Paginator = Paginator(),
        iteration: Int) -> Promise<([UserSubscription], Paginator, Int)> {
        
        return Promise { seal in
            do {
                try session.getUserRelatedSubreddit(.subscriber, paginator: paginator, completion: { result in
                    switch result {
                    case .success(let listing):
                        let newUserSubscriptions = listing.asUserSubscriptions(notify: true)
                        seal.fulfill((newUserSubscriptions + existingUserSubscriptions, listing.paginator, iteration + 1))
                    case .failure(let error):
                        seal.reject(error)
                    }
                })
            }
            catch {
                seal.reject(error)
            }
        }
    }
    
    func persistFavorites(userSubscriptions: [UserSubscription]) -> Promise<[UserSubscription]> {
        guard let userId = UserDefaultsService.shared.string(forKey: .userId) else {
            return Promise(error: SettingsServiceError.userIdNotFound)
        }
        
        return self.ensureFirebaseAuth().then { _ -> Promise<[UserSubscription]> in
            let db = Firestore.firestore()
            let batch = db.batch()
            
            // only import subscriptions we don't already have stored locally
            let existingUserSubscriptions = self.savedUserSubscriptions
            let newUserSubscriptions = userSubscriptions.filter { !existingUserSubscriptions.contains($0) }
            
            newUserSubscriptions.forEach { userSubscription in
                let document = db.collection("subscriptions").document(self.docId(userSubscription, userId))
                batch.setData([
                    "userId": userId,
                    "broadcaster": userSubscription.username,
                    "follower": UserDefaultsService.shared.string(forKey: .username) as Any,
                    "notify": true,
                    "iconUrl": userSubscription.iconUrl?.absoluteString as Any
                ], forDocument: document)
            }
            
            return batch.commit().map {
                return userSubscriptions
            }
        }
        .tap { result in
            if case .fulfilled(let savedUserSubscriptions) = result {
                let existingSavedUserSubscriptions = self.savedUserSubscriptions
                var newUserSubscriptions = existingSavedUserSubscriptions
                
                for savedUserSubscription in savedUserSubscriptions {
                    if !existingSavedUserSubscriptions.contains(savedUserSubscription) {
                        newUserSubscriptions += savedUserSubscription
                    }
                }
                
                self.savedUserSubscriptions = newUserSubscriptions
            }
        }
    }
    
    func persistFavorite(userSubscription: UserSubscription) -> Promise<Void> {
        guard let userId = UserDefaultsService.shared.string(forKey: .userId) else {
            return Promise(error: SettingsServiceError.userIdNotFound)
        }
        
        let db = Firestore.firestore()
        
        return db.collection("subscriptions").document(self.docId(userSubscription, userId)).setData([
            "userId": userId,
            "broadcaster": userSubscription.username,
            "follower": UserDefaultsService.shared.string(forKey: .username) as Any,
            "notify": true,
            "iconUrl": userSubscription.iconUrl?.absoluteString as Any
        ], merge: true).tap { result in
            if case .fulfilled = result {
                var userSubscriptions = self.savedUserSubscriptions
                
                if !userSubscriptions.contains(userSubscription) {
                    userSubscriptions += userSubscription
                }
                
                SettingsService.shared.savedUserSubscriptions = userSubscriptions
            }
        }
    }
    
    func removeFavorite(broadcaster: String) -> Promise<Void> {
        guard let userId = UserDefaultsService.shared.string(forKey: .userId) else {
            return Promise(error: SettingsServiceError.userIdNotFound)
        }
        
        guard let userSubscription = self.savedUserSubscriptions.first(where: { $0.username == broadcaster }) else {
            // this subscription never existed.. ?
            return Promise.value(())
        }
        
        let db = Firestore.firestore()
        
        return db.collection("subscriptions").document(self.docId(userSubscription, userId)).delete().tap { result in
            if case .fulfilled = result {
                var userSubscriptions = self.savedUserSubscriptions
                userSubscriptions.removeAll(where: { $0 == userSubscription })
                SettingsService.shared.savedUserSubscriptions = userSubscriptions
                
                UserDefaultsService.shared.add(broadcaster, forKey: .unsubscribedUserList)
            }
        }
    }
    
    func fetchUserProfile(username: String) -> Promise<RedditProfile> {
        guard let (_, token) = self.loginService.loggedInUser else {
            return Promise.value(RedditProfile(username: username, iconUrl: RedditProfile.randomIcon()))
        }
        
        return Promise { seal in
            let session = Session(token: token)
            do {
                try session.getUserProfile(username, completion: { result in
                    switch result {
                    case .success(let account):
                        let iconUrl = URL(string: account.iconImg) ?? RedditProfile.randomIcon()
                        seal.fulfill(RedditProfile(username: account.name, iconUrl: iconUrl))
                    case .failure(let error):
                        seal.reject(error)
                    }
                })
            }
            catch {
                seal.reject(error)
            }
        }
    }
    
    func fetchUserProfiles(usernames: [String]) -> Promise<[RedditProfile]> {
        let promises = usernames.map { self.fetchUserProfile(username: $0) }
        return when(fulfilled: promises)
    }
    
    @discardableResult
    func ensureFirebaseAuth() -> Promise<String> {
        if let currentUser = Auth.auth().currentUser {
            return Promise.value(currentUser.uid)
        }
        
        return Promise { seal in
            Auth.auth().signInAnonymously() { (authResult, error) in
                if let authResult = authResult {
                    seal.fulfill(authResult.user.uid)
                }
                else if let error = error {
                    seal.reject(error)
                }
                else {
                    seal.reject(SettingsServiceError.unableToAuth)
                }
            }
        }
    }
    
    func updateNotificationSetting(userSubscription: UserSubscription, enabled: Bool) -> Promise<Void> {
        //return after(.seconds(1)).map { throw SettingsServiceError.loggedOut }
        
        guard let userId = UserDefaultsService.shared.string(forKey: .userId) else {
            return Promise(error: SettingsServiceError.userIdNotFound)
        }

        let db = Firestore.firestore()

        return self.ensureFirebaseAuth().then { _ -> Promise<Void> in
            return db.collection("subscriptions").document(self.docId(userSubscription, userId)).setData([
                "notify": enabled
            ], merge: true)
        }
    }
    
    func updateCooldownSetting(userSubscription: UserSubscription, enabled: Bool) -> Promise<Void> {
        guard let userId = UserDefaultsService.shared.string(forKey: .userId) else {
            return Promise(error: SettingsServiceError.userIdNotFound)
        }

        let db = Firestore.firestore()

        return self.ensureFirebaseAuth().then { _ -> Promise<Void> in
            return db.collection("subscriptions").document(self.docId(userSubscription, userId)).setData([
                "cooldown": enabled
            ], merge: true)
        }
    }
    
    func updateNotificationSoundSetting(userSubscription: UserSubscription, sound: String) -> Promise<Void> {
        guard let userId = UserDefaultsService.shared.string(forKey: .userId) else {
            return Promise(error: SettingsServiceError.userIdNotFound)
        }

        let db = Firestore.firestore()

        return self.ensureFirebaseAuth().then { _ -> Promise<Void> in
            return db.collection("subscriptions").document(self.docId(userSubscription, userId)).setData([
                "sound": sound
            ], merge: true)
        }
    }
    
    func updateGlobalNotificationSetting(enabled: Bool) -> Promise<Void> {
        guard let userId = UserDefaultsService.shared.string(forKey: .userId) else {
            return Promise(error: SettingsServiceError.userIdNotFound)
        }
        
        return self.ensureFirebaseAuth().then { _ -> Promise<Void> in
            let db = Firestore.firestore()
            return db.collection("users").document(userId).setData([
                "notificationsOn": enabled
            ], merge: true)
        }
    }
    
    func isSubscribedTo(username: String, fromUserSubscriptions userSubscriptions: [UserSubscription]) -> Bool {
        return userSubscriptions.first(where: { $0.username == username }) != nil
    }
    
    func fetchSubreddits() -> Promise<[RpanSubreddit]> {
        return self.ensureFirebaseAuth().then { _ -> Promise<[RpanSubreddit]> in
            let db = Firestore.firestore()
            return db.collection("subreddits").getDocumentsFromCollection().map { documents in
                return documents.compactMap { document in
                    let name = document.data()["name"] as! String
                    let iconUrl = document.data()["iconUrl"] as! String
                    return RpanSubreddit(name: name, iconUrl: URL(string: iconUrl)!)
                }
            }
        }
    }
    
    func updateSubredditBlacklistSetting(userSubscription: UserSubscription, subreddits: [String]) -> Promise<Void> {
        guard let userId = UserDefaultsService.shared.string(forKey: .userId) else {
            return Promise(error: SettingsServiceError.userIdNotFound)
        }

        let db = Firestore.firestore()

        return self.ensureFirebaseAuth().then { _ -> Promise<Void> in
            return db.collection("subscriptions").document(self.docId(userSubscription, userId)).setData([
                "subBlacklist": subreddits
            ], merge: true)
        }
    }
    
    func fetchAppConfiguration() -> Promise<AppConfig> {
        return self.ensureFirebaseAuth().then { _ -> Promise<AppConfig> in
            let db = Firestore.firestore()
            
            return db.collection("config").document("main").getDocumentFromReference().compactMap { document in
                return document.data()
            }.map { data in
                return AppConfig(s: data["s"] as? Bool ?? false)
            }
        }
    }
    
    func fetchUserSubscriptions() -> Promise<[UserSubscription]> {
        guard let userId = UserDefaultsService.shared.string(forKey: .userId) else {
            return Promise(error: SettingsServiceError.userIdNotFound)
        }
        
        return self.ensureFirebaseAuth().then { _ -> Promise<[UserSubscription]> in
            let db = Firestore.firestore()
            return db.collection("subscriptions")
                .whereField("userId", isEqualTo: userId)
                .getDocumentsFromQuery().map { documents in
                    
                return documents.compactMap { document in
                    let broadcaster = document.data()["broadcaster"] as! String
                    let notify = document.data()["notify"] as? Bool ?? false
                    let cooldown = document.data()["cooldown"] as? Bool ?? false
                    let subBlacklist = document.data()["subBlacklist"] as? [String] ?? []
                    let iconUrl = document.data()["iconUrl"] as? String
                    let sound = document.data()["sound"] as? String ?? Constants.DefaultNotificationSoundName
                    return UserSubscription(
                        username: broadcaster,
                        iconUrl: URL(string: iconUrl) ?? RedditProfile.randomIcon(),
                        notify: notify,
                        subredditBlacklist: subBlacklist,
                        cooldown: cooldown,
                        sound: sound)
                }
            }
        }
    }
    
    func persistProfileIcons(userSubscriptions: [UserSubscription]) -> Promise<Void> {
        guard let userId = UserDefaultsService.shared.string(forKey: .userId) else {
            return Promise(error: SettingsServiceError.userIdNotFound)
        }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        userSubscriptions.filter { $0.iconUrl != nil }.forEach { userSubscription in
            let document = db.collection("subscriptions").document(self.docId(userSubscription, userId))
            batch.updateData(["iconUrl": userSubscription.iconUrl!.absoluteString], forDocument: document)
        }
        
        return batch.commit()
    }
    
    func removeAllMyFavorites() -> Promise<Void> {
        guard let userId = UserDefaultsService.shared.string(forKey: .userId) else {
            return Promise(error: SettingsServiceError.userIdNotFound)
        }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        return db.collection("subscriptions").whereField("userId", isEqualTo: userId).getDocumentsFromQuery().then { result -> Promise<Void> in
            result.forEach { document in
                batch.deleteDocument(db.collection("subscriptions").document(document.documentID))
            }
            
            return batch.commit()
        }
    }
}
