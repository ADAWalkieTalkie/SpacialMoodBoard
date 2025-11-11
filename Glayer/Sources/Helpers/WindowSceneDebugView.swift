//
//  WindowSceneDebugView.swift
//  Glayer
//
//  Created by PenguinLand on 11/12/25.
//

import SwiftUI
import Combine

// MARK: - WindowSceneDetailView

/// visionOS 앱에서 UIWindowScene의 실시간 변화를 관찰하고 디버깅하기 위한 뷰입니다.
///
/// 이 뷰는 디버그 목적으로 사용되며, 다음과 같은 정보를 제공합니다:
/// - 현재 활성화된 모든 UIWindowScene의 목록
/// - 각 Scene의 상태(Foreground Active/Inactive, Background 등)
/// - 윈도우 프레임, Key Window 정보
/// - 크기 제한(Size Restrictions) 정보
/// - 실시간 자동 새로고침 기능 (1초 간격)
///
/// ## 사용 방법
/// ```swift
/// // GlayerApp.swift에 WindowGroup으로 추가
/// WindowGroup(id: "WindowSceneDebug") {
///     WindowSceneDetailView()
/// }
///
/// // 다른 뷰에서 열기
/// @Environment(\.openWindow) private var openWindow
/// openWindow(id: "WindowSceneDebug")
/// ```
///
/// ## 주요 기능
/// - Volume 윈도우, Immersive 모드 전환 시 Scene 변화 추적
/// - 각 윈도우의 크기, 위치, 상태 정보 표시
/// - visionOS의 다중 Scene 환경을 실시간으로 관찰
///
/// - Note: 이 뷰는 디버그 용도로만 사용되어야 합니다. 프로덕션 빌드에서는 제거하는 것을 권장합니다.
/// - Important: `UIApplication.shared.connectedScenes`를 사용하므로 메인 스레드에서 실행됩니다.
struct WindowSceneDetailView: View {
    /// 씬의 상세 정보를 저장할 상태 변수
    @State private var sceneInfo: String = "정보 로딩 중..."

    /// 자동 새로고침 활성화 여부
    @State private var autoRefresh: Bool = false

    /// 자동 새로고침을 위한 타이머 (1초 간격)
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Window Scene 속성")
                .font(.title)
                .padding(.bottom, 10)

            // 자동 새로고침 토글
            Toggle("자동 새로고침 (1초)", isOn: $autoRefresh)
                .padding(.bottom, 10)

            // Scene 정보를 모노스페이스 폰트로 표시
            ScrollView {
                Text(sceneInfo)
                    .font(.system(.body, design: .monospaced))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button("정보 새로고침") {
                updateSceneInfo()
            }
            .padding(.top, 10)
        }
        .padding()
        .onAppear {
            updateSceneInfo()
        }
        .onReceive(timer) { _ in
            if autoRefresh {
                updateSceneInfo()
            }
        }
    }

    // MARK: - Scene Information Updates

    /// Scene 정보를 업데이트하고 UI에 반영합니다.
    ///
    /// `getSceneDetails()`를 호출하여 현재 모든 활성 Scene의 정보를 가져온 후,
    /// `sceneInfo` 상태 변수에 할당하여 UI를 업데이트합니다.
    private func updateSceneInfo() {
        self.sceneInfo = getSceneDetails()
    }

    // MARK: - Helper Functions

    /// CGFloat 값을 안전하게 정수 문자열로 변환합니다.
    ///
    /// - Parameter value: 변환할 CGFloat 값
    /// - Returns: 정수 문자열 또는 "무제한" (값이 무한대이거나 너무 큰 경우)
    ///
    /// visionOS에서 윈도우 크기 제한이나 프레임 값이 무한대일 수 있어서
    /// 직접 Int로 변환하면 런타임 에러가 발생할 수 있습니다.
    private func safeIntString(_ value: CGFloat) -> String {
        // 무한대 또는 NaN 체크
        if value.isInfinite || value.isNaN {
            return "무제한"
        }

        // Int 범위를 초과하는지 체크
        if value > Double(Int.max) || value < Double(Int.min) {
            return "무제한"
        }

        // 안전하게 변환 가능
        return "\(Int(value))"
    }

    /// UIWindowScene의 식별 정보를 추출합니다.
    ///
    /// - Parameter scene: 정보를 추출할 UIWindowScene
    /// - Returns: Scene의 식별 정보를 포함한 딕셔너리
    ///
    /// 이 함수는 Scene이 어떤 WindowGroup/ImmersiveSpace인지 식별하는 데 도움이 됩니다.
    /// GlayerApp.swift에 정의된 Scene ID들:
    /// - "MainWindow": ProjectListView 또는 LibraryView
    /// - "ImmersiveVolumeWindow": VolumeSceneView
    /// - "ImmersiveScene": ImmersiveSceneView (Immersive Space)
    /// - "WindowSceneDebug": WindowSceneDetailView
    private func getSceneIdentifier(from scene: UIWindowScene) -> (friendlyName: String, debugInfo: [String]) {
        // 다양한 식별자 수집
        let configName = scene.session.configuration.name ?? "nil"
        let persistentId = scene.session.persistentIdentifier
        let sceneTitle = scene.title ?? "nil"

        // persistentIdentifier에서 WindowGroup ID 추출 시도
        // 예: "MainWindow-XXXX-XXXX" 형태일 가능성
        var extractedId: String?
        if persistentId.contains("-") {
            let components = persistentId.split(separator: "-")
            if !components.isEmpty {
                extractedId = String(components[0])
            }
        }

        // 디버깅 정보 수집
        var debugInfo: [String] = []
        debugInfo.append("Config Name: '\(configName)'")
        debugInfo.append("Persistent ID: '\(persistentId)'")
        debugInfo.append("Title: '\(sceneTitle)'")
        if let extracted = extractedId {
            debugInfo.append("Extracted ID: '\(extracted)'")
        }

        // 알려진 Scene ID와 매핑 (여러 속성에서 시도)
        let sceneNameMap: [String: String] = [
            "MainWindow": "메인 윈도우 (ProjectList/Library)",
            "ImmersiveVolumeWindow": "Volume Scene (3D 미리보기)",
            "ImmersiveScene": "Immersive Space (전체 몰입)",
            "WindowSceneDebug": "디버그 윈도우",
            "com.apple.SwiftUI.windowStyle.volumetric": "Volume Window",
            "Default Configuration": "기본 윈도우",
            // visionOS의 일반적인 패턴들
            "UIWindowSceneSessionRoleApplication": "기본 애플리케이션 윈도우"
        ]

        // 1. persistentIdentifier의 prefix로 매칭 시도
        if let extracted = extractedId, let friendlyName = sceneNameMap[extracted] {
            return (friendlyName, debugInfo)
        }

        // 2. configName으로 매칭 시도
        if let friendlyName = sceneNameMap[configName] {
            return (friendlyName, debugInfo)
        }

        // 3. persistentIdentifier에 특정 키워드가 포함되어 있는지 확인
        for (key, friendlyName) in sceneNameMap {
            if persistentId.contains(key) {
                return (friendlyName, debugInfo)
            }
        }

        // 4. 매칭 실패 시 원본 정보 반환
        return ("알 수 없음 (디버깅 정보 참조)", debugInfo)
    }

    /// 윈도우의 Root View Controller 타입을 추출합니다.
    ///
    /// - Parameter window: 정보를 추출할 UIWindow
    /// - Returns: Root View Controller의 타입 이름
    private func getRootViewControllerType(from window: UIWindow) -> String {
        guard let rootVC = window.rootViewController else {
            return "없음"
        }

        let typeName = String(describing: type(of: rootVC))

        // SwiftUI의 경우 _TtGC7SwiftUI19UIHostingControllerV... 같은 mangled name이 나옴
        if typeName.contains("UIHostingController") {
            return "SwiftUI View (UIHostingController)"
        }

        return typeName
    }

    /// `UIApplication.shared.connectedScenes`를 통해 모든 활성 Scene의 상세 정보를 가져옵니다.
    ///
    /// - Returns: 포맷된 Scene 정보 문자열. 각 Scene의 상태, 윈도우, 크기 제한 등의 정보를 포함합니다.
    ///
    /// 이 함수는 다음과 같은 정보를 수집합니다:
    /// - 전체 Scene 개수
    /// - 업데이트 시간
    /// - 각 Scene의 상세 정보 (상태, 타이틀, 윈도우 정보 등)
    func getSceneDetails() -> String {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        if scenes.isEmpty {
            return "UIWindowScene을 찾을 수 없습니다."
        }

        var allDetails: [String] = []
        allDetails.append("총 \(scenes.count)개의 Window Scene 발견\n")
        allDetails.append("업데이트 시간: \(Date().formatted(date: .omitted, time: .standard))\n")
        allDetails.append("=" + String(repeating: "=", count: 50))

        for (index, scene) in scenes.enumerated() {
            allDetails.append("\n\n📱 Scene #\(index + 1)")
            allDetails.append("-" + String(repeating: "-", count: 50))
            allDetails.append(getSceneDetailString(from: scene))
        }

        return allDetails.joined(separator: "\n")
    }

    /// 개별 `UIWindowScene`의 상세 정보를 포맷된 문자열로 반환합니다.
    ///
    /// - Parameter scene: 정보를 추출할 UIWindowScene 인스턴스
    /// - Returns: 포맷된 Scene 상세 정보 문자열
    ///
    /// 이 함수는 다음 정보를 추출합니다:
    /// - **기본 정보**: 상태, 타이틀, Session Role
    /// - **화면 정보**: 크기, 스케일 (iOS/iPadOS에서만 사용 가능)
    /// - **윈도우 정보**: 연결된 모든 윈도우의 프레임, Key Window 여부, Hidden 상태, Alpha 값
    /// - **크기 제한**: 최소/최대 크기 (visionOS에서 중요)
    ///
    /// - Note: visionOS에서는 `UIScreen` 속성에 접근할 수 없으므로 조건부 컴파일을 사용합니다.
    func getSceneDetailString(from scene: UIWindowScene) -> String {
        var details: [String] = []

        // Scene 식별 정보
        let (friendlyName, debugInfo) = getSceneIdentifier(from: scene)
        details.append("🔷 Scene 타입: \(friendlyName)")
        details.append("")

        // 디버깅 정보 (Scene 식별용)
        details.append("📋 디버깅 정보:")
        for info in debugInfo {
            details.append("  • \(info)")
        }
        details.append("")

        // 기본 정보
        details.append("✓ 상태: \(scene.activationState.stringValue)")
        details.append("✓ 타이틀: \(scene.title ?? "N/A")")
        details.append("✓ Session Role: \(scene.session.role.rawValue)")

        // 윈도우 정보
        details.append("✓ 연결된 윈도우 개수: \(scene.windows.count)")

        // 각 윈도우의 상세 정보
        for (windowIndex, window) in scene.windows.enumerated() {
            let frame = window.frame
            let rootVCType = getRootViewControllerType(from: window)
            details.append("  └─ Window #\(windowIndex + 1):")
            details.append("     • View Controller: \(rootVCType)")
            details.append("     • 프레임: (\(safeIntString(frame.origin.x)), \(safeIntString(frame.origin.y))) - \(safeIntString(frame.width))x\(safeIntString(frame.height))")
            details.append("     • Key Window: \(window.isKeyWindow ? "✓" : "✗")")
            details.append("     • Hidden: \(window.isHidden ? "✓" : "✗")")
            details.append("     • Alpha: \(String(format: "%.2f", window.alpha))")
        }

        // Key Window 정보
        if let keyWindow = scene.keyWindow {
            let frame = keyWindow.frame
            details.append("✓ Key Window 프레임: \(safeIntString(frame.width))x\(safeIntString(frame.height))")
        } else {
            details.append("✗ Key Window: 없음")
        }

        // 크기 제한 (visionOS에서 중요)
        if let restrictions = scene.sizeRestrictions {
            let minSize = restrictions.minimumSize
            let maxSize = restrictions.maximumSize
            details.append("✓ 최소 크기: \(safeIntString(minSize.width)) x \(safeIntString(minSize.height))")
            details.append("✓ 최대 크기: \(safeIntString(maxSize.width)) x \(safeIntString(maxSize.height))")
        } else {
            details.append("✗ 크기 제한: 없음")
        }

        return details.joined(separator: "\n")
    }
}

// MARK: - UIScene.ActivationState Extension

/// `UIScene.ActivationState`를 사람이 읽기 쉬운 문자열로 변환하는 확장입니다.
///
/// 이 확장은 디버그 뷰에서 Scene의 현재 상태를 명확하게 표시하기 위해 사용됩니다.
extension UIScene.ActivationState {
    /// Scene의 활성화 상태를 사람이 읽기 쉬운 문자열로 반환합니다.
    ///
    /// - Returns: 상태를 나타내는 문자열
    ///   - `"Unattached"`: Scene이 앱에 연결되지 않음
    ///   - `"Foreground Active"`: Scene이 포그라운드에서 활성 상태
    ///   - `"Foreground Inactive"`: Scene이 포그라운드에 있지만 비활성 상태 (예: 알림 센터 표시 중)
    ///   - `"Background"`: Scene이 백그라운드에 있음
    ///   - `"Unknown"`: 알 수 없는 상태 (향후 추가될 상태)
    var stringValue: String {
        switch self {
        case .unattached: return "Unattached"
        case .foregroundActive: return "Foreground Active"
        case .foregroundInactive: return "Foreground Inactive"
        case .background: return "Background"
        @unknown default: return "Unknown"
        }
    }
}

// SwiftUI 미리보기
#Preview {
    WindowSceneDetailView()
}

