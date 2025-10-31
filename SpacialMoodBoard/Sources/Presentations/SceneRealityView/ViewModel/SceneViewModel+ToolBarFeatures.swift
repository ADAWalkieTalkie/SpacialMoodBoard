import SwiftUI

// MARK: - Toolbar Features

extension SceneViewModel {
    
    // Mark: - View Mode Toggle
    func toggleViewMode() {
        userSpatialState.viewMode.toggle()
    }
}
