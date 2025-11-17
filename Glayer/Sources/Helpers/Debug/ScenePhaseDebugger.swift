//
//  ScenePhaseDebugger.swift
//  Glayer
//
//  Created by PenguinLand on 11/14/25.
//

import SwiftUI

/// Scene의 현재 `scenePhase`와 `AppStateManager`의 `appState`를 모니터링하고
/// 화면에 오버레이로 표시하는 디버그 뷰입니다.
///
/// 이 뷰는 특정 Scene에 추가되어 해당 Scene의 생명주기와 앱의 전역 상태 변화를
/// 실시간으로 추적하고 콘솔에 로그를 출력합니다.
///
/// ## 사용 예시
/// ```swift
/// WindowGroup(id: "MainWindow") {
///     ContentView()
///         .overlay(alignment: .bottomLeading) {
///             ScenePhaseDebugger(sceneName: "MainWindow", appStateManager: appStateManager)
///         }
/// }
/// ```
struct ScenePhaseDebugger: View {
    /// 디버그 로그 및 오버레이에 표시할 Scene의 고유 이름입니다.
    let sceneName: String
    
    /// 현재 Scene의 `ScenePhase` 환경 값입니다.
    @Environment(\.scenePhase) private var scenePhase
    
    @Bindable var appStateManager: AppStateManager

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            debugInfoRows
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.5), lineWidth: 1)
        )
        .frame(maxWidth: 350)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            logScenePhaseChange(from: oldPhase, to: newPhase)
        }
        .onChange(of: appStateManager.appState) { oldState, newState in
            logAppStateChange(from: oldState, to: newState)
        }
        .onAppear {
            print("🔍 [\(sceneName)] Scene appeared")
            logCurrentState()
        }
        .onDisappear {
            print("🔍 [\(sceneName)] Scene disappeared")
        }
    }

    // MARK: - UI Helper

    /// 디버그 정보를 표시하는 UI 행들의 그룹입니다.
    private var debugInfoRows: some View {
        Group {
            Text("🔍 \(sceneName)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Divider()
                .background(Color.white.opacity(0.3))

            debugInfoRow(label: "ScenePhase", value: phaseString(scenePhase))
            debugInfoRow(label: "AppState", value: stateString(appStateManager.appState))
            debugInfoRow(label: "Project", value: appStateManager.appState.selectedProject?.title ?? "None")
            debugInfoRow(label: "Show Library", value: "\(appStateManager.showLibrary)")
            debugInfoRow(label: "Minimized", value: "\(appStateManager.libraryMinimized)")
            debugInfoRow(label: "Volume Open", value: "\(appStateManager.appState.isVolumeOpen)")
            debugInfoRow(label: "Immersive Open", value: "\(appStateManager.appState.isImmersiveOpen)")
        }
    }

    /// "Label: Value" 형식의 단일 디버그 정보 행을 생성합니다.
    /// - Parameters:
    ///   - label: 정보의 레이블 (예: "ScenePhase").
    ///   - value: 정보의 값 (예: "active").
    /// - Returns: 레이블과 값으로 구성된 뷰
    private func debugInfoRow(label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(label + ":")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    // MARK: - Private Methods

    /// `ScenePhase` 변경 사항을 콘솔에 로깅합니다.
    private func logScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        print("🔄 [\(sceneName)] ScenePhase changed: \(phaseString(oldPhase)) → \(phaseString(newPhase))")
        logCurrentState()
    }

    /// `AppState` 변경 사항을 콘솔에 로깅합니다.
    private func logAppStateChange(from oldState: AppStateManager.AppState, to newState: AppStateManager.AppState) {
        print("🔄 [\(sceneName)] AppState changed: \(stateString(oldState)) → \(stateString(newState))")
        logCurrentState()
    }

    /// 현재 `ScenePhase` 및 `AppState`를 콘솔에 로깅합니다.
    private func logCurrentState() {
        print("""
        📊 [\(sceneName)] Current State:
           - ScenePhase: \(phaseString(scenePhase))
           - AppState: \(stateString(appStateManager.appState))
           - Selected Project: \(appStateManager.appState.selectedProject?.title ?? "None")
           - Show Library: \(appStateManager.showLibrary)
           - Library Minimized: \(appStateManager.libraryMinimized)
        """)
    }

    /// `ScenePhase` 열거형을 로깅하기 쉬운 문자열로 변환합니다.
    private func phaseString(_ phase: ScenePhase) -> String {
        switch phase {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unknown"
        }
    }

    /// `AppStateManager.AppState` 열거형을 로깅하기 쉬운 문자열로 변환합니다.
    private func stateString(_ state: AppStateManager.AppState) -> String {
        switch state {
        case .projectList:
            return "projectList"
        case .libraryWithVolume(let project):
            return "libraryWithVolume(\(project.title))"
        case .libraryWithImmersive(let project):
            return "libraryWithImmersive(\(project.title))"
        case .closedApp:
            return "closedApp"
        }
    }
}

/// 앱 시작 시점의 주요 상태를 콘솔에 로깅하는 유틸리티 구조체입니다.
///
/// `App`의 `init`이나 `onAppear` 등에서 호출하여
/// 앱이 시작될 때의 `AppStateManager` 상태를 확인할 수 있습니다.
struct AppDebugLogger {
    
    /// 앱이 켜질 때 `AppStateManager`의 초기 상태를 콘솔에 출력합니다.
    /// - Parameter appStateManager: 현재 앱의 상태를 담고 있는 `AppStateManager` 인스턴스입니다.
    static func logAppLaunch(appStateManager: AppStateManager) {
        print("""

        ========================================
        🚀 App Launched
        ========================================
        📊 Initial State:
           - AppState: \(stateString(appStateManager.appState))
           - Selected Project: \(appStateManager.appState.selectedProject?.title ?? "None")
           - Show Library: \(appStateManager.showLibrary)
           - Library Minimized: \(appStateManager.libraryMinimized)
           - Volume Open: \(appStateManager.appState.isVolumeOpen)
           - Immersive Open: \(appStateManager.appState.isImmersiveOpen)
        ========================================

        """)
    }

    /// `AppStateManager.AppState` 열거형을 로깅하기 쉬운 문자열로 변환합니다.
    private static func stateString(_ state: AppStateManager.AppState) -> String {
        switch state {
        case .projectList:
            return "projectList"
        case .libraryWithVolume(let project):
            return "libraryWithVolume(\(project.title))"
        case .libraryWithImmersive(let project):
            return "libraryWithImmersive(\(project.title))"
        case .closedApp:
            return "closedApp"
        }
    }
}
