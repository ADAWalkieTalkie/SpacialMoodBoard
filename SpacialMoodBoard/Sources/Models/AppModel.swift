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
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    var selectedProject: Project?
    var selectedScene: SceneModel?
//    var storedAssets: [Asset] = []
}
