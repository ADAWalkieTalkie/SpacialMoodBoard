//
//  AssetType.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/12/25.
//

import Foundation

enum AssetType: String, Codable, Hashable {
    case image, sound

    var symbol: String {
        switch self {
        case .image: return "photo.fill"
        case .sound: return "speaker.fill"
        }
    }
}
