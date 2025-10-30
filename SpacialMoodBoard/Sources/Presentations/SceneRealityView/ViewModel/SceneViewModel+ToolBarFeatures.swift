import SwiftUI

// MARK: - Toolbar Features

extension SceneViewModel {

    // Mark: - View Mode Toggle
    func toggleViewMode() {
        userSpatialState.viewMode.toggle()
    }
    
    // Mark: - Immersive Space Toggle
    /// - Parameters:
    ///   - appModel: AppModel (immersiveSpaceState 관리)
    ///   - dismissImmersiveSpace: Environment action
    ///   - openImmersiveSpace: Environment action
    func toggleImmersiveSpace(
        appModel: AppModel,
        dismissImmersiveSpace: DismissImmersiveSpaceAction,
        openImmersiveSpace: OpenImmersiveSpaceAction
    ) async {
        switch appModel.immersiveSpaceState {
        case .open:
            appModel.immersiveSpaceState = .inTransition
            await dismissImmersiveSpace()
            // Don't set immersiveSpaceState to .closed because there
            // are multiple paths to ImmersiveView.onDisappear().
            // Only set .closed in ImmersiveView.onDisappear().
            
        case .closed:
            appModel.immersiveSpaceState = .inTransition
            switch await openImmersiveSpace(id: "ImmersiveScene") {
            case .opened:
                // Don't set immersiveSpaceState to .open because there
                // may be multiple paths to ImmersiveView.onAppear().
                // Only set .open in ImmersiveView.onAppear().
                break
                
            case .userCancelled, .error:
                // On error, we need to mark the immersive space
                // as closed because it failed to open.
                fallthrough
            @unknown default:
                // On unknown response, assume space did not open.
                appModel.immersiveSpaceState = .closed
            }
            
        case .inTransition:
            // This case should not ever happen because button is disabled for this case.
            break
        }
    }
}