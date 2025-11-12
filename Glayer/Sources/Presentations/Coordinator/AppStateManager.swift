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
        case viewModeInImmersive(Project)
        case closedApp

        /// 현재 상태와 연관된 `Project` 객체를 반환.
        /// `projectList` 상태일 경우 `nil`을 반환.
        var selectedProject: Project? {
            switch self {
            case .projectList, .closedApp:
                return nil
            case .libraryWithVolume(let project), .libraryWithImmersive(let project), .viewModeInImmersive(let project):
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
        
        var isViewModeInImmersive: Bool {
            if case .viewModeInImmersive(let project) = self { return true }
            return false
        }
    }

    // MARK: - State Properties

    /// 앱의 현재 상태
    /// 이 값의 변경은 `WindowCoordinator`에 의해 감지되어 필요한 윈도우 조작을 트리거.
    private(set) var appState: AppState = .projectList

    /// 현재 선택된 씬 데이터
    var selectedScene: SceneModel?

    // MARK: - State Transition Methods

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

    /// 프로젝트를 닫고 프로젝트 목록으로 돌아가는 상태로 전환
    func closeProject() {
        selectedScene = nil
        appState = .projectList
    }
    
    func openVolume() {
        guard case .libraryWithImmersive(let project) = appState else {
            print("⚠️ Cannot open volume: not in libraryWithImmersive state")
            return
        }
        appState = .libraryWithVolume(project)
    }

    /// Immersive 모드를 여는 상태로 전환
    func openImmersive() {
        guard case .libraryWithVolume(let project) = appState else {
            print("⚠️ Cannot open immersive: not in libraryWithVolume state")
            return
        }
        appState = .libraryWithImmersive(project)
    }

    /// Immersive 모드를 닫고 Volume으로 돌아가는 상태로 전환
    func closeImmersive() {
        guard case .libraryWithImmersive(let project) = appState else {
            print("⚠️ Cannot close immersive: not in libraryWithImmersive state")
            return
        }
        appState = .libraryWithVolume(project)
    }
    
    func viewModeActivateInImmersive() {
        guard case .libraryWithImmersive(let project) = appState else {
            print("⚠️ Cannot activate viewMode: not in libraryWithImmersive state")
            return
        }
        
        appState = .viewModeInImmersive(project)
    }
    
    func viewModeDeActivateInImmersive() {
        guard case .viewModeInImmersive(let project) = appState else {
            print("⚠️ Cannot deactivate viewMode: not in libraryWithImmersive state")
            return
        }
        
        appState = .libraryWithImmersive(project)
    }
    
    func closeApp() {
        selectedScene = nil
        
        appState = .closedApp
    }
}
