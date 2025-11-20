import SwiftUI

struct ToolBarAttachment: View {
    @Environment(AppStateManager.self) private var appStateManager

    let viewModel: SceneViewModel
    
    private var isViewModeEnabled: Bool {
        appStateManager.selectedScene?.userSpatialState.viewMode ?? false
    }

    private var isImmersiveOpen: Bool {
        appStateManager.appState.isImmersiveOpen
    }
    
    // 최소화 모드
    private var isLibraryMinimized: Bool {
        appStateManager.libraryMinimized
    }
    
    // 낮밤 모드
    private var isNightMode: Bool {
        appStateManager.selectedScene?.spacialEnvironment.immersiveTime == .night
    }
    
    private var isPaused: Bool {
        appStateManager.selectedScene?.userSpatialState.paused ?? false
    }
    
    var body: some View {
        HStack(spacing: 24) {
            if appStateManager.appState.isVolumeOpen {
                toolBarSection {
                    ToolBarToggleButton(
                        type: .volumeControl,
                        isSelected: isImmersiveOpen,
                        action: viewModel.rotateBy90Degrees
                    )
                }
            }
            
            toolBarSection {
                ToolBarToggleButton(
                    type: .fullImmersive,
                    isSelected: isImmersiveOpen,
                    action: toggleImmersive
                )
                
                ToolBarToggleButton(
                    type: .viewMode,
                    isSelected: isViewModeEnabled,
                    action: toggleViewMode
                )
                
                if !appStateManager.appState.isVolumeOpen {
                    ToolBarToggleButton(
                        type: .minimize(isOn: false),
                        isSelected: isLibraryMinimized,
                        action: toggleMinimize
                    )
                    
                    ToolBarToggleButton(
                        type: .immersiveTime(appStateManager.selectedScene?.spacialEnvironment.immersiveTime ?? .day),
                        isSelected: isNightMode,
                        action: toggleImmersiveTime
                    )
                }
            }
            
            toolBarSection {
                ToolBarToggleButton(
                    type: .mute(isOn: isPaused),
                    isSelected: isPaused,
                    action: togglePause
                )
            }

            if !appStateManager.appState.isVolumeOpen {
                JoystickAttachment(
                    onValueChanged: { x, z in
                        viewModel.updateUserPositionFromJoystick(x: x, z: z)
                    },
                    onGestureStart: {
                        viewModel.startGesture()
                    },
                    onGestureEnd: {
                        viewModel.endGesture()
                    }
                )
            }
        }
    }
    
    // MARK: - 공통 섹션 래퍼

    @ViewBuilder
    private func toolBarSection<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 16) {
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .glassBackgroundEffect()
    }
    
    // MARK: - Actions

    private func toggleImmersive() {
        Task { @MainActor in
            if isImmersiveOpen {
                appStateManager.closeImmersive()
                viewModel.resetRootEntityPosition()
            } else {
                appStateManager.openImmersive()
            }
        }
    }
    
    /// 뷰 모드 토글 핸들러
    private func toggleViewMode() {
        viewModel.toggleViewMode()
        if isViewModeEnabled {
            appStateManager.setLibraryMinimized(false)
        }
    }

    private func toggleMinimize() {
        if !isViewModeEnabled {
            appStateManager.toggleLibraryMinimized()
        }
    }
    
    private func toggleImmersiveTime() {
        viewModel.toggleImmersiveTime()
    }

    /// 일시정지 버튼 핸들러
    private func togglePause() {
        viewModel.togglePause()
    }
}
