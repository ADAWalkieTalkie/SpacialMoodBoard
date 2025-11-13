//
//  WindowCoordinator.swift
//  Glayer
//
//  Created by PenguinLand on 11/2/25.
//

import SwiftUI

/// `AppModel`의 상태 변경을 구독하여, 윈도우와 Immersive Space의 생명주기를 선언적으로 관리하는 코디네이터
/// 윈도우를 열고 닫는 로직을 중앙에서 처리하여, 뷰 로직과 윈도우 관리 로직을 분리하는 역할 수행.
@MainActor
@Observable
class WindowCoordinator {

    private let appStateManager: AppStateManager

    /// - Parameter appStateManager: 앱의 상태를 공유하는 `AppModel` 인스턴스
    init(appStateManager: AppStateManager) {
        self.appStateManager = appStateManager
    }

    /// `AppModel`의 `AppState` 변경 사항을 처리하여 적절한 윈도우 조작을 수행합니다.
    ///
    /// 이 메서드는 `onChange(of: appStateManager.appState)` 수정자 내부에서 호출되어야 합니다.
    /// - Parameters:
    ///   - oldState: 변경 전의 `AppState`
    ///   - newState: 변경 후의 `AppState`
    ///   - openWindow: 특정 ID를 가진 윈도우를 여는 클로저
    ///   - dismissWindow: 특정 ID를 가진 윈도우를 닫는 클로저
    ///   - dismissImmersiveSpace: 현재 열려있는 몰입형 공간을 닫는 비동기 클로저
    func handleStateChange(
        from oldState: AppStateManager.AppState,
        to newState: AppStateManager.AppState,
        openWindow: @escaping (String) -> Void,
        dismissWindow: @escaping (String) -> Void,
        openImmersiveSpace: @escaping (String) async -> Void,
        dismissImmersiveSpace: @escaping () async -> Void
    ) async {
        switch (oldState, newState) {
        // Volume 윈도우 열기
        // projectList → libraryWithVolume
        case (.projectList, .libraryWithVolume):
            openWindow("ImmersiveVolumeWindow")

        // libraryWithVolume → libraryWithImmersive: Volume 윈도우 닫기 (Immersive가 대체)
        case (.libraryWithVolume, .libraryWithImmersive):
            dismissWindow("ImmersiveVolumeWindow")
            await openImmersiveSpace("ImmersiveScene")

        // libraryWithImmersive → libraryWithVolume: Volume 윈도우 다시 열기
        case (.libraryWithImmersive, .libraryWithVolume):
            openWindow("ImmersiveVolumeWindow")
            await dismissImmersiveSpace()

        // libraryWithVolume → projectList: Volume 윈도우 닫기
        case (.libraryWithVolume, .projectList):
            dismissWindow("ImmersiveVolumeWindow")

        // libraryWithImmersive → projectList: Immersive와 Volume 모두 닫기
        case (.libraryWithImmersive, .projectList):
            dismissWindow("MainWindow")
            openWindow("MainWindow")
            await dismissImmersiveSpace()
            
        // libraryWithVolume -> closedApp: 앱 종료
        // case: 볼륨 상태에서 라이브러리 x 버튼 클릭
        case (.libraryWithVolume, .closedApp):
            dismissWindow("ImmersiveVolumeWindow")
            dismissWindow("MainWindow")
            exit(0)
            
        default:
            // 다른 전환은 window 조작이 필요 없음
            break
        }
    }
}
