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
        appModel.appState.isImmersiveOpen
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
            // 현재 상태에 따라 Immersive 모드 열기/닫기
            if isImmersiveOpen {
                // Immersive 닫기
                await appModel.closeImmersive()
                await dismissImmersiveSpace()
            } else {
                // Immersive 열기
                switch await openImmersiveSpace(id: "ImmersiveScene") {
                case .opened:
                    await appModel.openImmersive()
                case .userCancelled, .error:
                    print("⚠️ Immersive Space 열기 실패")
                @unknown default:
                    print("⚠️ Immersive Space 알 수 없는 에러")
                }
            }
        }
    }
}
