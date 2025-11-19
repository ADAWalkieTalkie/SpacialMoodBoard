//
//  SoundChannel.swift
//  Glayer
//
//  Created by jeongminji on 10/21/25.
//

import Foundation

enum SoundChannel: String, Codable, CaseIterable {
    case foley
    case ambient
    
    var title: String {
        switch self {
        case .foley:   return String(localized: "sound.effect")
        case .ambient: return String(localized: "sound.ambient")
        }
    }
}
