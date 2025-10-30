import SwiftUI

struct ToolBarAttachment: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    @State private var isMuted = false
    
    private var isViewEnabled: Bool {
        appModel.selectedScene?.userSpatialState.viewMode ?? false
    }
    
    private var isImmersiveOpen: Bool {
        appModel.immersiveSpaceState == .open
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 뷰 모드 버튼 (viewMode 토글)
            ToolBarButton(
                systemName: "eye",
                isEnabled: isViewEnabled,
                action: toggleViewMode
            )
            
            // Immersive Space 토글 버튼
            ToolBarButton(
                systemName: "person.and.background.dotted",
                isEnabled: isImmersiveOpen,
                action: handleToggleImmersive
            )
            
            // 사운드 버튼
            ToolBarButton(
                systemName: isMuted ? "speaker.slash" : "speaker",
                isEnabled: isMuted,
                action: {
                    isMuted.toggle()
                    SceneAudioCoordinator.shared.setGlobalMute(isMuted)
                }
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .glassBackgroundEffect()
    }
    
    // MARK: - Actions
    
    private func toggleViewMode() {
        guard var scene = appModel.selectedScene else { return }
        scene.userSpatialState.viewMode.toggle()
        appModel.selectedScene = scene 
    }
    
    private func handleToggleImmersive() {
        Task { @MainActor in
            await appModel.toggleImmersiveSpace(
                dismissImmersiveSpace: dismissImmersiveSpace,
                openImmersiveSpace: openImmersiveSpace
            )
        }
    }
}