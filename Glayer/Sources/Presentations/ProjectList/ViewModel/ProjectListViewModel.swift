//
//  ProjectListViewModel.swift
//  Glayer
//
//  Created by PenguinLand on 10/9/25.
//

import Foundation
import Observation

@MainActor
@Observable
final class ProjectListViewModel {
    private var appStateManager: AppStateManager
    private let projectRepository: ProjectServiceInterface
    private let sceneModelStorage = SceneModelFileStorage()
    private let projectFileStorage = ProjectFileStorage()
    
    var searchText: String = ""
    var sort: SortOrder = .sort(.recent)
    
    private(set) var projects: [Project] = []
    
    var filteredProjects: [Project] {
        let filtered = searchText.isEmpty
        ? projects
        : projects.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        return sortProjects(filtered)
    }
    
    init(appStateManager: AppStateManager, projectRepository: ProjectServiceInterface) {
        self.appStateManager = appStateManager
        self.projectRepository = projectRepository
        
        refreshProjects()
    }
    
    private func refreshProjects() {
        projects = projectRepository.fetchProjects()
    }
    
    /// 고유한 프로젝트 제목 생성 ("무제1", "무제2", ...)
    private func generateUniqueProjectTitle() -> String {
        let prefix = String(localized: "project.untitled")

        // 기존 프로젝트 중 "무제" + 숫자 형태의 제목에서 숫자 추출
        let numbers = projects.compactMap { project -> Int? in
            guard project.title.hasPrefix(prefix) else { return nil }
            let numberPart = project.title.dropFirst(prefix.count)
            return Int(numberPart)
        }

        // 가장 큰 숫자 찾기 (없으면 0)
        let maxNumber = numbers.max() ?? 0

        // 다음 숫자로 제목 생성
        return "\(prefix)\(maxNumber + 1)"
    }
    
    func selectProject(project: Project) {
        guard projectRepository.fetchProject(project) != nil else {
#if DEBUG
            print(
                "[ProjectListViewModel] selectProject - ⚠️ Project not found: \(project.id)"
            )
#endif
            return
        }
        
        // 1. SceneModel 로드 (파일이 있으면 로드, 없으면 기본값 생성)
        let sceneModel = loadSceneModel(for: project)
        
        // 2. AppModel의 중앙화된 상태 관리 메서드 호출
        appStateManager.selectProject(project, scene: sceneModel)
    }
    
    // SceneModel 로드 또는 생성
    private func loadSceneModel(for project: Project) -> SceneModel {
        do {
            // 파일이 있으면 로드
            if sceneModelStorage.exists(projectName: project.title) {
                let sceneModel = try sceneModelStorage.load(
                    projectName: project.title,
                    projectId: project.id
                )
                
                // Floor 로드는 SceneViewModel에서 AssetRepository를 통해 처리됨
                // (floorAssetId → Asset 조회 → URL 획득)
                print("📂 Floor Asset ID: \(sceneModel.spacialEnvironment.floorAssetId ?? String(localized: "project.none"))")
                
                print("📂 기존 SceneModel 로드 완료")
                return sceneModel
            } else {
                // 파일이 없으면 기본값 생성
                return SceneModel(
                    projectId: project.id,
                    spacialEnvironment: SpacialEnvironment(),
                    userSpatialState: UserSpatialState(),
                    sceneObjects: []
                )
            }
        } catch {
            print("❌ SceneModel 로드 실패: \(error)")
            // 실패 시 기본값 생성
            return SceneModel(
                projectId: project.id,
                spacialEnvironment: SpacialEnvironment(),
                userSpatialState: UserSpatialState(),
                sceneObjects: []
            )
        }
    }
    
    @discardableResult
    func createProject(
        title: String? = nil
    ) throws -> Project {
        // title이 nil이거나 비어있으면 고유 제목 자동 생성
        let projectTitle = title?.isEmpty == false ? title! : generateUniqueProjectTitle()
        
        let spacialEnvironment = SpacialEnvironment()
        // Project 생성 및 DB에 저장
        let newProject = Project(
            title: projectTitle,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        projectRepository.addProject(newProject)
        refreshProjects()
        
        // 새 SceneModel 생성 및 로컬 파일에 저장
        let newSceneModel = SceneModel(
            projectId: newProject.id,
            spacialEnvironment: spacialEnvironment,
            userSpatialState: UserSpatialState(),
            sceneObjects: []
        )
        appStateManager.updateSelectedScene(newSceneModel)
        
        do {
            try sceneModelStorage.save(newSceneModel, projectName: projectTitle)
            print("✅ SceneModel 저장 성공: \(projectTitle)")
        } catch {
            print("❌ SceneModel 저장 실패: \(error)")
            print("   - 프로젝트명: \(projectTitle)")
            print("   - 에러 상세: \(error.localizedDescription)")
            throw error
        }
        
        appStateManager.selectProject(newProject, scene: newSceneModel)
        
        return newProject
    }
    
    func updateProjectTitle(project: Project, newTitle: String) {
        do {
            // 프로젝트 디렉토리, 메타데이터 파일 이름 변경
            try projectFileStorage.rename(from: project.title, to: newTitle)
            
            // swiftData 업데이트
            try projectRepository.updateProjectTitle(
                project,
                newTitle: newTitle
            )
            refreshProjects()
            
            // 선택된 프로젝트의 제목이 변경되면 AppState 재설정
            if appStateManager.appState.selectedProject?.id == project.id,
               let selectedScene = appStateManager.selectedScene {
                // 업데이트된 project 객체를 가져와서 appState 재설정
                if let updatedProject = projectRepository.fetchProject(project) {
                    appStateManager.selectProject(updatedProject, scene: selectedScene)
                }
                // SceneModel 파일도 새 이름으로 저장
                try sceneModelStorage.save(selectedScene, projectName: newTitle)
            }
        } catch {
#if DEBUG
            print("[ProjectListViewModel] updateProjectTitle - ❌ Error: \(error)")
#endif
        }
    }
    
    func deleteProject(project: Project) {
        guard projectRepository.fetchProject(project) != nil else {
            return
        }
        
        // SceneModel 파일도 함께 삭제
        try? sceneModelStorage.delete(projectName: project.title)
        
        projectRepository.deleteProject(project)
        refreshProjects()
        
        // 삭제된 프로젝트가 현재 선택된 프로젝트라면 상태 초기화
        if appStateManager.appState.selectedProject?.id == project.id {
            appStateManager.closeProject()
        }
    }
    
    /// 주어진 프로젝트 배열을 뷰모델의 정렬 상태에 맞춰 정렬
    private func sortProjects(_ projects: [Project]) -> [Project] {
        switch sort {
        case .sort(.recent):
            return projects.sorted {
                if $0.updatedAt == $1.updatedAt { return $0.title < $1.title }
                return $0.updatedAt > $1.updatedAt // 최신순 (newest first)
            }
        case .sort(.nameAZ):
            return projects.sorted {
                $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
        case .origin(_):
            return projects
        }
    }
}
