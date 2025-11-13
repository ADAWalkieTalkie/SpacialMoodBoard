//
//  CircleButtonEnum.swift
//  Glayer
//
//  Created by jeongminji on 10/31/25.
//

import SwiftUI

enum CircleFillButtonStyle {
    case automatic, plain
}


enum CircleFillButtonEnum {
    case back
    case next
    case plus
    case search
    case sidebar
    
    // Edit Bar
    case lock
    case crop
    case duplicate
    case delete
    case sound(isOn: Bool)

    var systemName: String {
        switch self {
        case .back:
            return "chevron.left"
        case .next:
            return "chevron.right"
        case .plus:
            return "plus"
        case .search:
            return "magnifyingglass"
        case .sidebar:
            return "square.split.2x1"
        case .lock:
            return "lock"
        case .crop:
            return "crop"
        case .duplicate:
            return "doc.on.doc"
        case .delete:
            return "trash"
        case .sound(let isOn):
            return isOn ? "speaker.slash.fill" : "speaker.wave.2.fill"
        }
    }
    
    var size: CGFloat {
        switch self {
        case .lock, .crop, .duplicate, .delete, .sound:
            return 36
        default:
            return 44
        }
    }
    
    var font: Font {
        switch self {
        case .lock, .crop, .duplicate, .delete, .sound:
            return .system(size: 17, weight: .medium)
        default:
            return .system(size: 19, weight: .medium)
        }
    }
    
    var buttonStyle: CircleFillButtonStyle {
        switch self {
        case .lock, .crop, .duplicate, .delete, .sound:
            return .plain
        default:
            return .automatic
        }
    }
}
