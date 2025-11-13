import SwiftUI

struct ToolBarAttachment: View {
    @Environment(AppStateManager.self) private var appStateManager

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
                type: .mute(isOn: isPaused),
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
                appStateManager.closeImmersive()
            } else {
                // Immersive 열기
                appStateManager.openImmersive()
            }
        }
    }
    
    /// 뷰 모드 토글 핸들러
    private func toggleViewMode() {
        viewModel.toggleViewMode()
    }

    /// 일시정지 버튼 핸들러
    private func togglePause() {
        viewModel.togglePause()
    }
}
