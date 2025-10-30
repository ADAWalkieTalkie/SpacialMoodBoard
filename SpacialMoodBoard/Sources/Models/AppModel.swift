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

    func toggleImmersiveSpace(
        dismissImmersiveSpace: DismissImmersiveSpaceAction,
        openImmersiveSpace: OpenImmersiveSpaceAction
    ) async {
        switch immersiveSpaceState {
        case .open:
            immersiveSpaceState = .inTransition
            await dismissImmersiveSpace()
            
        case .closed:
            immersiveSpaceState = .inTransition
            switch await openImmersiveSpace(id: "ImmersiveScene") {
            case .opened:
                break
                
            case .userCancelled, .error:
                fallthrough
            @unknown default:
                immersiveSpaceState = .closed
            }
            
        case .inTransition:
            break
        }
    }
    
    var selectedProject: Project?
    var selectedScene: SceneModel?
}
