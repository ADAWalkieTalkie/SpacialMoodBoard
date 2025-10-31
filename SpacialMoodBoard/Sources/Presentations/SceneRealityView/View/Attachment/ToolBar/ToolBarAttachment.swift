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
        let viewModeUseCase = ViewModeUseCase(entityRepository: viewModel.entityRepository)
        
        // isViewEnabled가 false일 때 (viewMode가 꺼져있을 때) -> viewModeOnAll()
        // isViewEnabled가 true일 때 (viewMode가 켜져있을 때) -> viewModeOffAll()
        if isViewEnabled {
            // 현재 상태가 true인데 toggle했으므로 false가 됨 -> viewModeOffAll()
            viewModeUseCase.viewModeOffAll()
        } else {
            // 현재 상태가 false인데 toggle했으므로 true가 됨 -> viewModeOnAll()
            viewModeUseCase.viewModeOnAll()
        }
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
