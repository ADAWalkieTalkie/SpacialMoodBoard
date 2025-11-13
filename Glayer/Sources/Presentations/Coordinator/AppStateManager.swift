//
//  AppStateManager.swift
//  Glayer
//
//  Created by apple on 10/2/25.
//

import SwiftUI

/// 앱의 전반적인 상태를 관리하는 중앙 모델 클래스. (Single Source of Truth)
/// 앱의 현재 상태(`AppState`)를 정의하고, 상태 간의 전환을 처리하는 메서드들을 제공.
@MainActor
@Observable
class AppStateManager {
    // MARK: - App State Definition
    
    /// 앱의 현재 상태를 명시적으로 정의
    /// - projectList: 프로젝트 목록 화면
    /// - libraryWithVolume: 라이브러리 + Volume 윈도우 열림
    /// - libraryWithImmersive: 라이브러리 + Immersive 모드 열림
    enum AppState: Equatable {
        case projectList
        case libraryWithVolume(Project)
        case libraryWithImmersive(Project)
        case closedApp
        
        /// 현재 상태와 연관된 `Project` 객체를 반환.
        /// `projectList` 상태일 경우 `nil`을 반환.
        var selectedProject: Project? {
            switch self {
            case .projectList, .closedApp:
                return nil
            case .libraryWithVolume(let project), .libraryWithImmersive(let project) :
                return project
            }
        }
        
        var isVolumeOpen: Bool {
            if case .libraryWithVolume = self { return true }
            return false
        }
        
        var isImmersiveOpen: Bool {
            if case .libraryWithImmersive = self { return true }
            return false
        }
    }
    
    // MARK: - State Properties
    
    /// 앱의 현재 상태
    /// 이 값의 변경은 `WindowCoordinator`에 의해 감지되어 필요한 윈도우 조작을 트리거.
    private(set) var appState: AppState = .projectList
    
    /// 현재 선택된 씬 데이터
    private(set) var selectedScene: SceneModel?
    
    /// LibraryView 표시 여부
    /// Immersive에서 viewMode 상태일 때 false로 설정되어 LibraryView만 숨김
    private(set) var showLibrary: Bool = true

    /// LibraryView 최소화 상태
    /// true일 경우 라이브러리가 최소화되어 작은 크기로 표시됨
    private(set) var libraryMinimized: Bool = false
    
    // MARK: - Project & Scene Management

    /// 프로젝트를 선택하고 `libraryWithVolume` 상태로 전환.
    ///
    /// 이 메서드는 `WindowCoordinator`가 Volume 윈도우를 열도록 유도.
    /// - Parameters:
    ///   - project: 선택된 프로젝트
    ///   - scene: 해당 프로젝트에서 표시할 씬
    func selectProject(_ project: Project, scene: SceneModel) {
        selectedScene = scene
        appState = .libraryWithVolume(project)
    }

    /// 현재 선택된 씬을 변경 (상태 전환 없이)
    /// - Parameter scene: 선택할 씬 데이터
    func selectScene(_ scene: SceneModel) {
        selectedScene = scene
    }

    /// 현재 선택된 씬을 업데이트
    /// 외부에서 씬 데이터를 수정한 후 이 메서드를 통해 변경사항을 반영
    /// - Parameter scene: 업데이트할 씬 데이터
    func updateSelectedScene(_ scene: SceneModel) {
        selectedScene = scene
    }

    /// 선택된 씬의 사용자 공간 상태를 업데이트
    /// 카메라 위치, 시선 방향 등 사용자 관련 공간 정보를 갱신
    /// - Parameter state: 새로운 userSpatialState 값
    func updateUserSpatialState(_ state: UserSpatialState) {
        selectedScene?.userSpatialState = state
    }

    /// 선택된 씬의 공간 환경 설정을 업데이트
    /// 룸 타입, 바닥 크기 등 환경 관련 설정을 갱신
    /// - Parameter environment: 새로운 spacialEnvironment 값
    func updateSpacialEnvironment(_ environment: SpacialEnvironment) {
        selectedScene?.spacialEnvironment = environment
    }

    /// 프로젝트를 닫고 프로젝트 목록으로 돌아가는 상태로 전환
    /// selectedScene을 nil로 초기화하고 projectList 상태로 변경
    func closeProject() {
        selectedScene = nil
        appState = .projectList
    }

    // MARK: - View Mode Transition

    /// Immersive 모드에서 Volume 모드로 전환
    /// libraryWithImmersive 상태에서만 호출 가능
    func openVolume() {
        guard case .libraryWithImmersive(let project) = appState else {
            print("⚠️ Cannot open volume: not in libraryWithImmersive state")
            return
        }
        appState = .libraryWithVolume(project)
    }
    
    /// Volume 모드에서 Immersive 모드로 전환
    /// libraryWithVolume 상태에서만 호출 가능
    func openImmersive() {
        guard case .libraryWithVolume(let project) = appState else {
            print("⚠️ Cannot open immersive: not in libraryWithVolume state")
            return
        }
        appState = .libraryWithImmersive(project)
    }

    /// Immersive 모드를 닫고 Volume 모드로 돌아가는 상태로 전환
    /// libraryWithImmersive 상태에서만 호출 가능
    func closeImmersive() {
        guard case .libraryWithImmersive(let project) = appState else {
            print("⚠️ Cannot close immersive: not in libraryWithImmersive state")
            return
        }
        appState = .libraryWithVolume(project)
    }

    // MARK: - Library Management
    
    /// LibraryView가 현재 열려있는지 확인
    /// - Returns: showLibrary가 true이고 libraryMinimized가 false일 때 true 반환
    var isLibraryOpen: Bool {
        guard case .libraryWithImmersive = appState else {
            // .projectList, .libraryWithVolume, .closedApp 상태에서는
            // 라이브러리가 "숨겨진" 상태가 아니므로 true 반환 (기존 로직 유지)
            return true
        }
        
        // .libraryWithImmersive 상태일 때만 실제 가시성/최소화 여부 체크
        return showLibrary && !libraryMinimized
    }

    /// LibraryView의 표시/숨김 상태를 토글
    /// Immersive 모드에서 뷰 모드 활성화 시 사용
    func toggleLibraryVisibility() {
        showLibrary.toggle()
    }
    
    /// LibraryView의 최소화 상태를 토글
    /// 최소화 모드와 일반 모드 사이를 전환
    func toggleLibraryMinimized() {
        libraryMinimized.toggle()
    }

    /// LibraryView의 최소화 상태를 직접 설정
    /// - Parameter minimized: true일 경우 최소화, false일 경우 일반 크기
    func setLibraryMinimized(_ minimized: Bool) {
        libraryMinimized = minimized
    }

    // MARK: - App Lifecycle

    /// 앱을 완전히 종료하는 상태로 전환
    /// selectedScene을 nil로 초기화하고 closedApp 상태로 변경
    func closeApp() {
        selectedScene = nil

        appState = .closedApp
    }
}
