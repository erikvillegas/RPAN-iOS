//
//  Broadcast.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

struct Broadcast: Decodable {
    struct Meter: Decodable {
        let proportionFull: Double
    }
    
    struct Post: Decodable {
        struct Awarding: Decodable {
            struct Award: Decodable {
                struct Icon: Decodable {
                    let url: URL
                }
                
                let id: String
                let name: String
                let coinPrice: Int
                let icon128: Icon
            }
            
            let award: Award
            let total: Int
        }
        
        struct Author: Decodable {
            let name: String?
        }
        
        struct Subreddit: Decodable {
            struct Styles: Decodable {
                let icon: URL
            }
            
            let name: String
            let styles: Styles
        }
        
        let id: String
        let title: String
        let url: URL
        let authorInfo: Author
        let subreddit: Subreddit
        let awardings: [Awarding]
        let liveCommentsWebsocket: URL
        let commentCount: Double
    }
    
    struct Stream: Decodable {
        enum State: String, Decodable {
            case live = "IS_LIVE"
            case ended = "ENDED"
        }
        
        let streamId: String
        let hlsUrl: String
        let publishAt: Int
        let hlsExistsAt: Int
        let thumbnail: URL
        let width: Int
        let height: Int
        let state: State
        let durationLimit: Int
    }
    
    let uniqueWatchers: Int
    let continuousWatchers: Int
    let totalContinuousWatchers: Int
    let upvotes: Int
    let downvotes: Int
    let chatDisabled: Bool
    let isFirstBroadcast: Bool
    let broadcastTime: Double
    let estimatedRemainingTime: Double
    let meter: Meter
    let post: Post
    let stream: Stream
    
    var broadcaster: String {
        return self.post.authorInfo.name ?? "error"
    }
}
