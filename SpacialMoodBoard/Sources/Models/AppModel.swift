//
//  AppModel.swift
//  SpacialMoodBoard
//
//  Created by apple on 10/2/25.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    static let volumeWindowID = "VolumeWindow"
    
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed

    var selectedProject: Project?
    var selectedScene: SceneModel?
}
