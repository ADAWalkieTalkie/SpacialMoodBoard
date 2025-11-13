//
//  CircleButtonEnum.swift
//  Glayer
//
//  Created by jeongminji on 10/31/25.
//

import SwiftUI

enum ToolBarToggleButtonEnum {
    case volumeControl
    case fullImmersive
    case viewMode
    case mute(isOn: Bool)
    case minimize(isOn: Bool)
    case immersiveTime(TimeOfDay)
    
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
        case .minimize:
            return "Minimize"
        case .immersiveTime:
            return "Day/Night"
        }
    }
    
    var image: Image {
        switch self {
        case .volumeControl:
            return Image("ic_volumeControl")
        case .fullImmersive:
            return Image(systemName: "person.and.background.dotted")
        case .viewMode:
            return Image(systemName: "eye")
        case .mute(let isOn):
            return isOn ? Image(systemName: "speaker.wave.1.fill") : Image(systemName: "speaker.slash.fill")
        case .minimize(let isOn):
            return isOn ? Image(systemName: "arrow.up.backward.and.arrow.down.forward.rectangle") : Image(systemName: "arrow.down.right.and.arrow.up.left.rectangle")
        case .immersiveTime(let t):
            switch t {
            case .day:   return Image(systemName: "sunset.fill")
            case .night: return Image(systemName: "sunrise")
            }
        }
    }
}
