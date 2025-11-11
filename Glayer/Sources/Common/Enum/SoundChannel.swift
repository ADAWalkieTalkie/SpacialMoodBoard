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
        case .foley:   return "효과음"
        case .ambient: return "앰비언트"
        }
    }
}
