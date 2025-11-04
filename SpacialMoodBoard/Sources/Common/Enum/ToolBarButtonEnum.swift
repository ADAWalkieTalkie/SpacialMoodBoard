//
//  CircleButtonEnum.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/31/25.
//

import SwiftUI

enum ToolBarToggleButtonEnum {
    case volumeControl
    case fullImmersive
    case viewMode
    case pause(isOn: Bool)

    var name: String {
        switch self {
        case .volumeControl:
            return "Volume Control"
        case .fullImmersive:
            return "Full Immersive"
        case .viewMode:
            return "View Mode"
        case .pause:
            return "Pause"
        }
    }
    
    var image: Image {
        switch self {
        case .volumeControl:
            return Image(.icVolumeControl)
        case .fullImmersive:
            return Image(systemName: "person.and.background.dotted")
        case .viewMode:
            return Image(systemName: "eye")
        case .pause(let isOn):
            return isOn ? Image(systemName: "play.fill") : Image(systemName: "pause.fill")
        }
    }
}
