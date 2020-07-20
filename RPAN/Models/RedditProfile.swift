//
//  RedditProfile.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import Foundation

struct RedditProfile {
    let username: String
    let iconUrl: URL
    
    static let defaultIcons = [
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_01_008985.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_02_FFD635.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_03_24A0ED.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_04_0DD3BB.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_05_EA0027.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_06_FF66AC.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_07_0DD3BB.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_08_4856A3.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_09_94E044.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_10_7E53C1.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_11_FF66AC.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_12_DB0064.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_13_DDBD37.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_14_DB0064.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_15_D4E815.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_16_008985.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_17_FF4500.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_18_A06A42.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_19_7E53C1.png")!,
        URL(string: "https://www.redditstatic.com/avatars/avatar_default_20_FFD635.png")!
    ]
    
    static func randomIcon() -> URL {
        return self.defaultIcons.randomElement()!
    }
}
