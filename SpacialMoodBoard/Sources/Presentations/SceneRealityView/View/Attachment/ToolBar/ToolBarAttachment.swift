import SwiftUI

struct ToolBarAttachment: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    let viewModel: SceneViewModel
    
    @State private var isMuted = false
    
    private var isViewEnabled: Bool {
        appModel.selectedScene?.userSpatialState.viewMode ?? false
    }
    
    private var isImmersiveOpen: Bool {
        appModel.immersiveSpaceState == .open
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 볼륨 컨트롤
//            ToolBarButton(
//                type: .volumeControl,
//                isSelected: ,
//                action: {}
//            )
            
            // Immersive Space 토글 버튼
            ToolBarButton(
                type: .fullImmersive,
                isSelected: isImmersiveOpen,
                action: { handleToggleImmersive() }
            )
            
            // 뷰 모드 버튼 (viewMode 토글)
            ToolBarButton(
                type: .viewMode,
                isSelected: isViewEnabled,
                action: toggleViewMode
            )
            
            ToolBarButton(
                type: .mute(isOn: isMuted),
                isSelected: isMuted,
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
        
        // ViewModeUseCase를 생성하고 사용
        let viewModeUseCase = ViewModeUseCase(
            entityRepository: viewModel.entityRepository,
            viewMode: scene.userSpatialState.viewMode
        )
        viewModeUseCase.execute()
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
