import SwiftUI

struct ToolBarAttachment: View {
    @Environment(AppStateManager.self) private var appStateManager
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    let viewModel: SceneViewModel
    
    private var isViewEnabled: Bool {
        appStateManager.selectedScene?.userSpatialState.viewMode ?? false
    }

    private var isImmersiveOpen: Bool {
        appStateManager.appState.isImmersiveOpen
    }

    private var isPaused: Bool {
        appStateManager.selectedScene?.userSpatialState.paused ?? false
    }
    
    var body: some View {
        HStack(spacing: 16) {
            
            // Immersive Space 토글 버튼
            ToolBarToggleButton(
                type: .fullImmersive,
                isSelected: isImmersiveOpen,
                action: toggleImmersive
            )
            
            // 뷰 모드 버튼 (viewMode 토글)
            ToolBarToggleButton(
                type: .viewMode,
                isSelected: isViewEnabled,
                action: toggleViewMode
            )
            
            // 일시정지 버튼
            ToolBarToggleButton(
                type: .pause(isOn: isPaused),
                isSelected: isPaused,
                action: togglePause
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .glassBackgroundEffect()
    }
    
    // MARK: - Actions

    /// Immersive 모드 토글 핸들러
    private func toggleImmersive() {
        Task { @MainActor in
            // 현재 상태에 따라 Immersive 모드 열기/닫기
            if isImmersiveOpen {
                // Immersive 닫기
                await appStateManager.closeImmersive()
                await dismissImmersiveSpace()
            } else {
                // Immersive 열기
                switch await openImmersiveSpace(id: "ImmersiveScene") {
                case .opened:
                    await appStateManager.openImmersive()
                case .userCancelled, .error:
                    print("⚠️ Immersive Space 열기 실패")
                @unknown default:
                    print("⚠️ Immersive Space 알 수 없는 에러")
                }
            }
        }
    }
    
    /// 뷰 모드 토글 핸들러
    private func toggleViewMode() {
        guard var scene = appStateManager.selectedScene else { return }
        scene.userSpatialState.viewMode.toggle()
        appStateManager.selectedScene = scene
        
        // ViewModeUseCase를 생성하고 사용
        let viewModeUseCase = ViewModeUseCase(
            entityRepository: viewModel.entityRepository,
            viewMode: scene.userSpatialState.viewMode
        )
        viewModeUseCase.execute()
    }

    /// 일시정지 버튼 핸들러
    private func togglePause() {
        guard var scene = appStateManager.selectedScene else { return }
        let newPausedState = !scene.userSpatialState.paused
        scene.userSpatialState.paused = newPausedState
        appStateManager.selectedScene = scene
        
        // 오디오 음소거 상태 업데이트
        SceneAudioCoordinator.shared.setGlobalMute(newPausedState)
    }
    
}
