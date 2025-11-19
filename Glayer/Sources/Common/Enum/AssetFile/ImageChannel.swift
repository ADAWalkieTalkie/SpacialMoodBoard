//
//  ImageChannel.swift
//  Glayer
//
//  Created by jeongminji on 11/17/25.
//

import Foundation

enum ImageChannel: String, Codable, CaseIterable {
    case background
    case floor
    case furniture
    case light
    case electronic
    case animal
    case plant
    
    var title: String {
        switch self {
        case .background:
            return String(localized: "image.background")
        case .floor:
            return String(localized: "image.floor")
        case .furniture:
            return String(localized: "image.furniture")
        case .light:
            return String(localized: "image.light")
        case .electronic:
            return String(localized: "image.electronic")
        case .animal:
            return String(localized: "image.animal")
        case .plant:
            return String(localized: "image.plant")
        }
    }
}
