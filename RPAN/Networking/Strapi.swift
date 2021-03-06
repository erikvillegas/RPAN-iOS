//
//  Strapi.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

class Strapi {
    static let shared = Strapi()
    
    let baseUrl = URL(string: "https://strapi.reddit.com")!
    
    func broadcasts() -> Promise<[Broadcast]> {
//        return after(.seconds(5)).then {
        
        return self.attempt(maximumRetryCount: 3) {
            return self.redditAccessToken().then { accessToken -> Promise<[Broadcast]> in
                let url = self.baseUrl.appendingPathComponent("broadcasts")
                let request = Session.default.request(url, method: .get, headers: ["Authorization": "Bearer \(accessToken.value)"])
                
//                request.responseString { result in
//                    print(result.value!)
//                }
                
                return request.responseDecodable(type: RedditResponse<[Broadcast]>.self).map { $0.data }
            }
        }
//        }
    }
    
    func broadcast(id: String) -> Promise<Broadcast> {
        return self.attempt(maximumRetryCount: 3) {
            return self.redditAccessToken().then { accessToken -> Promise<Broadcast> in
                let url = self.baseUrl.appendingPathComponent("broadcasts").appendingPathComponent(id)
                let request = Session.default.request(url, method: .get, headers: ["Authorization": "Bearer \(accessToken.value)"])
                
                return request.responseDecodable(type: RedditResponse<Broadcast>.self).map { $0.data }
            }
        }
    }
    
    private func redditAccessToken() -> Promise<RedditAccessToken> {
        if let existingToken = UserDefaultsService.shared.codableObject(type: RedditAccessToken.self, forKey: .redditAccessToken), !existingToken.isExpired {
            return Promise.value(existingToken)
        }
        
        let url = URL(string: "https://www.reddit.com/")!
        let request = Session.default.request(url, method: .get)
        
        return request.responseString().map { string in
            if let value = string.matchRegexSingle("(?:\"accessToken\":\")(.*?)(?:\")") {
                let accessToken = RedditAccessToken(value: value, expiration: Date().addingTimeInterval(3600))
                
                UserDefaultsService.shared.setCodableObject(accessToken, forKey: .redditAccessToken)
                
                return accessToken
            }
            else {
                throw RedditAPIError.noAccessTokenFound
            }
        }
    }
    
    func attempt<T>(maximumRetryCount: Int = 5, delayBeforeRetry: DispatchTimeInterval = .milliseconds(350), _ body: @escaping () -> Promise<T>) -> Promise<T> {
        var attempts = 0
        func attempt() -> Promise<T> {
            attempts += 1
            return body().recover { error -> Promise<T> in
                guard attempts < maximumRetryCount else { throw error }
                return after(delayBeforeRetry).then(on: nil, attempt)
            }
        }
        return attempt()
    }
}
