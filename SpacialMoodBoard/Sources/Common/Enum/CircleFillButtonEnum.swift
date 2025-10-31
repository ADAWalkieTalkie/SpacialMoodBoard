//
//  CircleButtonEnum.swift
//  SpacialMoodBoard
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
        case .crop:
            return "crop"
        case .duplicate:
            return "doc.on.doc"
        case .delete:
            return "trash"
        case .sound(let isOn):
            return isOn ? "speaker.wave.2.fill" : "speaker.slash.fill"
        }
    }
    
    var size: CGFloat {
        switch self {
        case .crop, .duplicate, .delete, .sound:
            return 36
        default:
            return 44
        }
    }
    
    var buttonStyle: CircleFillButtonStyle {
        switch self {
        case .crop, .duplicate, .delete, .sound:
            return .plain
        default:
            return .automatic
        }
    }
}
