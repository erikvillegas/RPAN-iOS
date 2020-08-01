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

typealias RemovalReason = RemovalReasonsResponse.Item

struct RemovalReasonsResponse: Codable {
    struct Item: Codable {
        let message: String
        let id: String
        let title: String
    }
    
    let data: [String: Item]
    let order: [String]
}

typealias SubredditRule = SubredditRules.Rule

struct SubredditRules: Decodable {
    struct Rule: Decodable {
        let description: String?
        let shortName: String
    }
    
    let rules: [Rule]
    let siteRules: [String]
}


enum ModerationServiceError: Error {
    case userLoggedOut
    case userIsAlreadyBanned
}

typealias ModeratedSubreddit = ModeratedSubredditsResponse.Data.ModeratedSubredditContainer.Subreddit

struct ModeratedSubredditsResponse: Codable {
    struct Data: Codable {
        struct ModeratedSubredditContainer: Codable {
            struct Subreddit: Codable {
                let name: String
                let displayName: String
            }
            
            let data: Subreddit
        }
        
        let children: [ModeratedSubredditContainer]
    }
    
    let data: Data
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
//        return self.userIsBanned(username: username, in: subreddit).then { alreadyBanned -> Promise<Void> in
//            guard !alreadyBanned else {
//                throw ModerationServiceError.userIsAlreadyBanned
//            }
            
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
//        }
    }
    
    func remove(_ broadcast: Broadcast) -> Promise<Void> {
        return self.session().then { session in
            return Promise { seal in
                do {
                    try session.remove(broadcast) { result in
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
    
    func moderatedSubreddits() -> Promise<[ModeratedSubreddit]> {
        return self.session().then { session in
            return Promise { seal in
                do {
                    let path = "subreddits/mine/moderator.json?api_type=json&limit=100&raw_json=1"
                    try session.execute(path: path) { (result: reddift.Result<ModeratedSubredditsResponse>) in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let value):
                                seal.fulfill(value.data.children.map { $0.data })
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

    func userIsBanned(username: String, in subreddit: String) -> Promise<Bool> {
        return self.session().then { session in
            return Promise { seal in
                do {
                    try session.about(subreddit, aboutWhere: .banned, user: username) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success:
                                seal.fulfill(false)
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

    func subredditRemovalReasons(subreddit: String) -> Promise<[RemovalReason]> {
        return self.session().then { session in
            return Promise { seal in
                do {
                    let path = "api/v1/\(subreddit)/removal_reasons?api_type=json&raw_json=1"
                    try session.execute(path: path) { (result: reddift.Result<RemovalReasonsResponse>) in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let value):
                                let reasons = Array(value.data.values)
                                let order = value.order
                                let sorted = reasons.sorted { (item1, item2) -> Bool in
                                    return Int(order.firstIndex { $0 == item1.id }!) < Int(order.firstIndex { $0 == item2.id }!)
                                }
                                
                                seal.fulfill(sorted)
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
        
    func addRemoveReason(broadcast: Broadcast, reason: RemovalReason) -> Promise<Void> {
        return self.session().then { session in
            return Promise { seal in
                do {
                    let parameters = [
                        "title": reason.title,
                        "message": reason.message,
                        "type": "private",
                        "item_id": [broadcast.post.id] // t3_i1bmto
                    ] as [String : Any]
                    
                    let path = "api/v1/modactions/removal_link_message"
                    
//                    let asdf = "title=\(reason.title)&message=\(reason.message)&type=private&item_id[]=t3_i1bmto"
//                    let data = asdf.data(using: .utf8)!
                    let data = try JSONSerialization.data(withJSONObject: parameters)
                    
                    try session.execute(path: path, data: data, method: "POST") { (result: reddift.Result<NullModel>) in
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

public struct NullModel: Decodable {
    public init(from decoder: Decoder) throws {
        return // every json will map successfully to this model
    }

    public init() {}
}
