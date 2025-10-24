import SwiftUI

struct ToolBarAttachment: View {
    @Environment(AppModel.self) private var appModel
    
    @Binding var isSoundEnabled: Bool
    
    // Environment Actions 대신 클로저로 전달받음
    var onToggleImmersive: (() -> Void)?
    
    // Computed properties for state
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
                action: { onToggleImmersive?() }
            )
            
            // 사운드 버튼
            ToolBarButton(
                systemName: isSoundEnabled ? "speaker.slash" : "speaker",
                isEnabled: isSoundEnabled,
                action: { isSoundEnabled.toggle() }
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
}

// MARK: - Preview

#Preview {
    @Previewable @State var isSoundEnabled = false
    
    ToolBarAttachment(
        isSoundEnabled: $isSoundEnabled,
        onToggleImmersive: { print("Toggle Immersive") } 
    )
    .environment(AppModel())
}