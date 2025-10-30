//
//  CircleButtonEnum.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/31/25.
//

import SwiftUI

enum ToolBarButtonEnum {
    case volumeControl
    case fullImmersive
    case viewMode
    case mute(isOn: Bool)

    var name: String {
        switch self {
        case .volumeControl:
            return "Volume Control"
        case .fullImmersive:
            return "Full Immersive"
        case .viewMode:
            return "View Mode"
        case .mute:
            return "Mute"
        }
    }
    
    var image: Image {
        switch self {
        case .volumeControl:
            return Image(.icVolumeControl)
        case .fullImmersive:
            return Image(.icFullImmersive)
        case .viewMode:
            return Image(.icViewMode)
        case .mute(let isOn):
            return isOn ? Image(.icMuteTrue) : Image(.icMuteFalse)
        }
    }
}
