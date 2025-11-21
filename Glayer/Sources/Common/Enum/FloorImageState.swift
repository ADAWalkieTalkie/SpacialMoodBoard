//
//  FloorImageState.swift
//  Glayer
//
//  Created by jeongminji on 11/21/25.
//

import Foundation

/// FloorImageState (바닥 이미지 없음, 이 asset이 현재 바닥 이미지, 다른 asset이 바닥 이미지)
enum FloorImageState {
    case none
    case current
    case other
    
    var changeFloorText: String {
        switch self {
        case .none:
            return String(localized: "floor.add")
        case .current:
            return String(localized: "floor.remove")
        case .other:
            return String(localized: "floor.change")
        }
    }
    
    var changeFloorSymbol: String {
        switch self {
        case .none, .other:
            return "square.on.square.dashed"
        case .current:
            return "square.dashed"
        }
    }
}
