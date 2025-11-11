//
//  View+ScenePhaseChange.swift
//  Glayer
//
//  Created by PenguinLand on 11/9/25.
//
//  이 파일은 SwiftUI View에 ScenePhase 변경 감지 기능을 추가하는 확장을 제공합니다.
//  앱의 생명주기(active, inactive, background) 변화에 따라 특정 액션을 실행할 수 있습니다.
//

import SwiftUI

/// `ScenePhase`가 특정 상태로 변경될 때 주어진 액션을 수행하는 `ViewModifier`입니다.
///
/// 이 modifier는 SwiftUI의 `Environment(\.scenePhase)`를 감지하여,
/// 앱의 생명주기 상태 변화에 반응할 수 있게 합니다.
///
/// - Note: 이 modifier는 phase가 변경될 때마다 체크하며, `targetPhase`와 일치할 때만 액션을 실행합니다.
struct ScenePhaseChangeModifier: ViewModifier {

    /// 액션을 트리거할 목표 `ScenePhase`입니다.
    let targetPhase: ScenePhase

    /// `targetPhase`에 도달했을 때 실행할 클로저입니다.
    let action: () -> Void

    @Environment(\.scenePhase) private var scenePhase

    /// View에 scene phase 변경 감지 기능을 적용합니다.
    ///
    /// - Parameter content: 수정할 원본 View
    /// - Returns: Scene phase 변경을 감지하는 기능이 추가된 View
    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == targetPhase {
                    action()
                }
            }
    }
}

// MARK: - View Extension

extension View {

    /// 씬(Scene)이 활성 상태(.active)가 될 때 특정 작업을 수행합니다.
    ///
    /// `.active` 상태는 앱이 포그라운드에서 실행 중이고 사용자와 상호작용할 수 있는 상태입니다.
    /// 일반적으로 앱이 처음 시작되거나, 백그라운드에서 복귀할 때 이 상태가 됩니다.
    ///
    /// - Parameter action: 씬이 활성화될 때 실행할 클로저입니다.
    ///   이 클로저는 메인 스레드에서 실행되며, UI 업데이트를 안전하게 수행할 수 있습니다.
    /// - Returns: `ScenePhase` 변경을 감지하는 수정자가 적용된 뷰입니다.
    ///
    /// # Example
    /// ```swift
    /// ContentView()
    ///     .onActive {
    ///         print("앱이 활성화되었습니다")
    ///         // 데이터 새로고침, 타이머 재시작 등
    ///     }
    /// ```
    ///
    /// - Note: 여러 개의 phase modifier를 동시에 사용할 수 있습니다.
    ///   각각의 modifier는 독립적으로 동작합니다.
    func onActive(perform action: @escaping () -> Void) -> some View {
        self.modifier(ScenePhaseChangeModifier(targetPhase: .active, action: action))
    }

    /// 씬(Scene)이 비활성 상태(.inactive)가 될 때 특정 작업을 수행합니다.
    ///
    /// `.inactive` 상태는 앱이 포그라운드에 있지만 이벤트를 받지 않는 상태입니다.
    /// 예를 들어, 시스템 알림이 표시되거나 앱 전환 화면이 나타날 때 발생합니다.
    /// 이 상태는 일시적이며, 곧 `.active` 또는 `.background` 상태로 전환됩니다.
    ///
    /// - Parameter action: 씬이 비활성화될 때 실행할 클로저입니다.
    ///   이 클로저는 메인 스레드에서 실행되며, UI 업데이트를 안전하게 수행할 수 있습니다.
    /// - Returns: `ScenePhase` 변경을 감지하는 수정자가 적용된 뷰입니다.
    ///
    /// # Example
    /// ```swift
    /// ContentView()
    ///     .onInactive {
    ///         print("앱이 비활성화되었습니다")
    ///         // 진행 중인 작업 일시 중지
    ///     }
    /// ```
    ///
    /// - Important: 이 상태는 매우 짧게 유지될 수 있으므로,
    ///   무거운 작업은 `.background` 상태에서 수행하는 것이 좋습니다.
    func onInactive(perform action: @escaping () -> Void) -> some View {
        self.modifier(ScenePhaseChangeModifier(targetPhase: .inactive, action: action))
    }

    /// 씬(Scene)이 백그라운드 상태(.background)가 될 때 특정 작업을 수행합니다.
    ///
    /// `.background` 상태는 앱이 더 이상 화면에 표시되지 않는 상태입니다.
    /// 사용자가 홈 버튼을 누르거나 다른 앱으로 전환했을 때 발생합니다.
    /// 이 상태에서는 시스템이 언제든 앱을 종료할 수 있습니다.
    ///
    /// - Parameter action: 씬이 백그라운드로 전환될 때 실행할 클로저입니다.
    ///   이 클로저는 메인 스레드에서 실행되며, UI 업데이트를 안전하게 수행할 수 있습니다.
    /// - Returns: `ScenePhase` 변경을 감지하는 수정자가 적용된 뷰입니다.
    ///
    /// # Example
    /// ```swift
    /// ContentView()
    ///     .onBackground {
    ///         print("앱이 백그라운드로 전환되었습니다")
    ///         // 데이터 저장, 네트워크 연결 해제 등
    ///     }
    /// ```
    ///
    /// - Important: 백그라운드 상태에서는 실행 시간이 제한적이므로,
    ///   중요한 데이터 저장 작업은 가능한 한 빨리 완료해야 합니다.
    func onBackground(perform action: @escaping () -> Void) -> some View {
        self.modifier(ScenePhaseChangeModifier(targetPhase: .background, action: action))
    }
}
