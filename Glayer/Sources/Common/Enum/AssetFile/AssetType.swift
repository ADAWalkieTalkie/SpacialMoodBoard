//
//  AssetType.swift
//  Glayer
//
//  Created by jeongminji on 10/12/25.
//

import Foundation
import UniformTypeIdentifiers

enum AssetType: String, Codable, Hashable {
    case image, sound
    
    var symbol: String {
        switch self {
        case .image: return "photo.fill"
        case .sound: return "speaker.fill"
        }
    }
    
    var allowedTypes: [UTType] {
        switch self {
        case .image: return [.image, .png, .jpeg, .heic]
        case .sound: return [.audio]
        }
    }
}
