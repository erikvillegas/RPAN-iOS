//
//  RedditAPI.swift
//  RPAN
//
//  Created by Erik Villegas on 7/25/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation
import PromiseKit
import reddift

class RedditAPI {
    static let shared = RedditAPI()

    func getComments(broadcast: Broadcast) -> Promise<[Comment]> {
        guard let (_, token) = LoginService.shared.loggedInUser else {
            return Promise(error: RedditAPIError.noAccessTokenFound)
        }

        return Promise { seal in
            let session = Session(token: token)
            let link = Link(id: String(broadcast.post.id.dropFirst(3))) // chop off t3_
            // Link(id: "g7h0ku")
            
            do {
                try session.getArticles(link, sort: .new, comments: nil, depth: 10, limit: 1000, context: 5) { result in
                    
                    switch result {
                    case .success((_, let commentListing)):
                        
                        if let comments = commentListing.children.filter({ $0 is Comment }) as? [Comment] {
                            seal.fulfill(comments)
                        }
                        else {
                            seal.fulfill([])
                        }
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
}
