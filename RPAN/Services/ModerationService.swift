//
//  ModerationService.swift
//  RPAN
//
//  Created by Erik Villegas on 7/26/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation
import PromiseKit
import reddift

enum ModerationServiceError: Error {
    case userLoggedOut
}

class ModerationService {
    static let shared = ModerationService()
    
    func session() -> Promise<Session> {
        guard let (_, token) = LoginService.shared.loggedInUser else {
            return Promise(error: ModerationServiceError.userLoggedOut)
        }
        
        return Promise.value(Session(token: token))
    }
    
    func subredditRules(subredditName: String) -> Promise<[SubredditRule]> {
        return self.session().then { session in
            return Promise { seal in
                do {
                    try session.subredditRules(subredditName) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let value):
                                let siteRules = value.siteRules.map { SubredditRule(description: nil, shortName: $0) }
                                let other = SubredditRule(description: nil, shortName: "Other")
                                seal.fulfill(value.rules + siteRules + [other])
                            case .failure(let error):
                                seal.reject(error)
                            }
                        }
                    }
                }
                catch {
                    seal.reject(error)
                }
            }
        }
    }
    
    func ban(_ username: String, from subreddit: String, banMessage: String, modNote: String?, reason: String, duration: Int?, comment: Comment) -> Promise<Void> {
        return self.session().then { session in
            return Promise { seal in
                do {
                    try session.ban(username, from: subreddit, banMessage: banMessage, modNote: modNote, reason: reason, duration: duration, comment: comment) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success:
                                seal.fulfill(())
                            case .failure(let error):
                                seal.reject(error)
                            }
                        }
                    }
                }
                catch {
                    seal.reject(error)
                }
            }
        }
    }
    
    func remove(_ comment: Comment) -> Promise<Void> {
        return self.session().then { session in
            return Promise { seal in
                do {
                    try session.remove(comment) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success:
                                seal.fulfill(())
                            case .failure(let error):
                                seal.reject(error)
                            }
                        }
                    }
                }
                catch {
                    seal.reject(error)
                }
            }
        }
    }
    
    func approve(_ comment: Comment) -> Promise<Void> {
        return self.session().then { session in
            return Promise { seal in
                do {
                    try session.approve(comment) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success:
                                seal.fulfill(())
                            case .failure(let error):
                                seal.reject(error)
                            }
                        }
                    }
                }
                catch {
                    seal.reject(error)
                }
            }
        }
    }

}
