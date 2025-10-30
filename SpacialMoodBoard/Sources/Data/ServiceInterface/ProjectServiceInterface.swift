//
//  ProjectRepositoryInterface.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/19/25.
//

import Foundation

// MARK: - Repository Errors
/// ProjectRepositoryInterface 프로토콜 구현체들이 공통으로 사용하는 에러 타입
enum ProjectRepositoryError: Error {
    case emptyTitle
    case projectNotFound
    case duplicateProject
}

// MARK: - ProjectRepositoryInterface Protocol
/// 프로젝트 데이터에 대한 CRUD 작업을 정의하는 프로토콜
/// - Note: 프로토콜은 데이터 계층의 책임만 가지며, UI 상태(AppSceneState)에 의존하지 않습니다.
protocol ProjectServiceInterface {
    /// 초기 데이터 불러오는 작업
    func loadInitialData()

    /// 모든 프로젝트를 최신순으로 정렬하여 반환
    func fetchProjects() -> [Project]

    /// 특정 프로젝트 조회
    /// - Parameter project: 조회할 프로젝트
    /// - Returns: 프로젝트가 존재하면 반환, 없으면 nil
    func fetchProject(_ project: Project) -> Project?

    /// 새 프로젝트 추가
    /// - Parameter project: 추가할 프로젝트
    /// - Note: 중복된 ID의 프로젝트는 무시됩니다
    func addProject(_ project: Project)

    /// 기존 프로젝트 업데이트
    /// - Parameter project: 업데이트할 프로젝트
    func updateProject(_ project: Project)

    /// 프로젝트 삭제
    /// - Parameter project: 삭제할 프로젝트
    func deleteProject(_ project: Project)

    /// 프로젝트 제목 업데이트
    /// - Parameters:
    ///   - project: 업데이트할 프로젝트
    ///   - newTitle: 새 제목
    /// - Throws: `ProjectRepositoryError.emptyTitle` - 제목이 비어있을 때
    ///          `ProjectRepositoryError.projectNotFound` - 프로젝트를 찾을 수 없을 때
    func updateProjectTitle(_ project: Project, newTitle: String) throws

    /// 검색어로 프로젝트 필터링
    /// - Parameter searchText: 검색어 (빈 문자열이면 전체 반환)
    /// - Returns: 필터링된 프로젝트 배열 (최신순 정렬)
    func filterProjects(by searchText: String) -> [Project]
}
