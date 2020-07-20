//
//  RedditAPI.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

class RedditAPI {
    static let shared = RedditAPI()
    
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
    
    private func redditAccessToken() -> Promise<RedditAccessToken> {
        if let existingToken = UserDefaultsService.shared.codableObject(type: RedditAccessToken.self, forKey: .redditAccessToken), !existingToken.isExpired {
            return Promise.value(existingToken)
        }
        
        let url = URL(string: "https://www.reddit.com/")!
        let request = Session.default.request(url, method: .get)
        
        return request.responseString().map { string in
            // (?:"accessToken":")(.*?)(?:")
            let regex = try? NSRegularExpression(pattern: "(?:\"accessToken\":\")(.*?)(?:\")", options: [.caseInsensitive])
            let range = NSRange(location: 0, length: string.count)
            let match = regex?.firstMatch(in: string, options: [], range: range)

            if let match = match, match.numberOfRanges == 2 {
                let value = (string as NSString).substring(with: match.range(at: 1))
                let accessToken = RedditAccessToken(value: value, expiration: Date().addingTimeInterval(10))
                
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
