//
//  LoginService.swift
//  RPAN
//
//  Created by Erik Villegas on 7/10/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation
import FirebaseAuth
import reddift
import PromiseKit
import FirebaseFirestore
import Device

class LoginService {
    static let shared = LoginService()
    
    var loggedInUser: (User, OAuth2Token)? {
        guard let user = UserDefaultsService.shared.codableObject(type: User.self, forKey: .currentUser) else {
            return nil
        }
        
        guard let username = user.username, let token = try? OAuth2TokenRepository.token(of: username) else {
            return nil
        }
        
        return (user, token)
    }
    
    @discardableResult
    func authenticateWithReddit() -> Bool {
        do {
            try OAuth2Authorizer.sharedInstance.challengeWithScopes(["identity", "mysubreddits", "read"])
            return true
        }
        catch {
            return false
        }
    }
    
    func completeRedditAuthentication(token: OAuth2Token) -> Promise<User> {
        guard let userId = UserDefaultsService.shared.string(forKey: .userId) else {
            return Promise(error: SettingsServiceError.userIdNotFound)
        }
        
        return Promise { seal in
            let session = Session(token: token)
            
            do {
                try session.getProfile() { result in
                    switch result {
                    case .success(let account):
                        UserDefaultsService.shared.set(account.name, forKey: .username)
                        
                        let user: User
                        
                        if var anonymousUser = UserDefaultsService.shared.codableObject(type: User.self, forKey: .currentUser) {
                            anonymousUser.username = account.name
                            user = anonymousUser
                        }
                        else {
                            user = User(userId: userId, username: account.name)
                        }
                        
                        SettingsService.shared.associateUsernameToCurrentUser(account.name)
                        
                        UserDefaultsService.shared.setCodableObject(user, forKey: .currentUser)
                        seal.fulfill(user)
                        
                    case .failure(let error):
                        seal.reject(error)
                    }
                }
            }
            catch {
                seal.reject(error)
            }
        }
    }
    
    func logout(user: User) {
        if let username = user.username {
            try? OAuth2TokenRepository.removeToken(of: username)
        }
        
        UserDefaults.standard.removeObject(forKey: "user")
        UserDefaults.standard.synchronize()
    }
}
