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
    private var isDayMode: Bool {
        appStateManager.selectedScene?.spacialEnvironment.immersiveTime == .day ? true : false
    }
    

    private var isPaused: Bool {
        appStateManager.selectedScene?.userSpatialState.paused ?? false
    }
    
    
    var body: some View {
        if appStateManager.appState.isVolumeOpen {
            HStack(spacing: 24) {
                HStack(spacing: 16) {
                    
                    // volume 회전 버튼
                    ToolBarToggleButton(
                        type: .volumeControl,
                        isSelected: isImmersiveOpen,
                        action: viewModel.rotateBy90Degrees
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .glassBackgroundEffect()
                
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
                        isSelected: isViewModeEnabled,
                        action: toggleViewMode
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .glassBackgroundEffect()
                
                HStack(spacing: 16) {
                    
                    // 뮤트 토글 버튼
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
            
        } else {
            HStack(spacing: 24) {
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
                        isSelected: isViewModeEnabled,
                        action: toggleViewMode
                    )
                    
                    // 라이브러리 최소화 토글 버튼
                    ToolBarToggleButton(
                        type: .minimize(isOn: false),
                        isSelected: isLibraryMinimized,
                        action: toggleMinimize
                    )
                    
                    // 낮/밤 전환 토글 버튼
                    ToolBarToggleButton(
                        type: .immersiveTime(.day),
                        isSelected: isDayMode,
                        action: toggleImmersiveTime
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .glassBackgroundEffect()
                
                HStack(spacing: 16) {
                    // 뮤트 토글 버튼
                    ToolBarToggleButton(
                        type: .mute(isOn: isPaused),
                        isSelected: isPaused,
                        action: togglePause
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .glassBackgroundEffect()

                HStack(spacing: 16) {
                    // 뮤트 토글 버튼
                    JoystickAttachment(
                        onValueChanged: { x, z in
                            viewModel.updateUserPositionFromJoystick(x: x, z: z)
                        }
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
        }
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
        if isLibraryMinimized {
            appStateManager.toggleLibraryVisibility()
        }
    }

    /// 일시정지 버튼 핸들러
    private func togglePause() {
        viewModel.togglePause()
//        print("isLibraryOpen \(appStateManager.isLibraryOpen())")
//        print("showLibrary \(appStateManager.showLibrary)")
    }
    
    
}
