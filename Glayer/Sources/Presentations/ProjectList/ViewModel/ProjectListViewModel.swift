//
//  ProjectListViewModel.swift
//  Glayer
//
//  Created by PenguinLand on 10/9/25.
//

import Foundation
import Observation

/// 프로젝트 목록 화면의 비즈니스 로직을 관리하는 ViewModel
///
/// - SwiftData를 통한 Project 메타데이터 관리
/// - JSON 파일을 통한 SceneModel 영속성 관리
/// - 프로젝트 CRUD 및 복제 기능
@MainActor
@Observable
final class ProjectListViewModel {
    // MARK: - Dependencies

    private var appStateManager: AppStateManager
    private let projectRepository: ProjectServiceInterface
    private let sceneModelStorage = SceneModelFileStorage()
    private let projectFileStorage = ProjectFileStorage()

    // MARK: - Public State

    var searchText: String = ""
    var sort: SortOrder = .sort(.recent)
    private(set) var projects: [Project] = []

    /// 검색 및 정렬이 적용된 프로젝트 목록
    var filteredProjects: [Project] {
        let filtered = searchText.isEmpty
        ? projects
        : projects.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        return sortProjects(filtered)
    }

    // MARK: - Initialization

    init(appStateManager: AppStateManager, projectRepository: ProjectServiceInterface) {
        self.appStateManager = appStateManager
        self.projectRepository = projectRepository
        refreshProjects()
    }

    // MARK: - Private Helpers

    private func refreshProjects() {
        projects = projectRepository.fetchProjects()
    }

    /// 고유한 프로젝트 제목 자동 생성 ("무제1", "무제2", ...)
    private func generateUniqueProjectTitle() -> String {
        let prefix = String(localized: "project.untitled")

        let existingNumbers = Set(projects.compactMap { project -> Int? in
            guard project.title.hasPrefix(prefix) else { return nil }

            let numberPart = project.title.dropFirst(prefix.count)

            return Int(numberPart)
        })

        var nextNumber = 1
        while existingNumbers.contains(nextNumber) {
            nextNumber += 1
        }

        return "\(prefix)\(nextNumber)"
    }

    /// 복제 프로젝트 제목 생성 ("원본(1)", "원본(2)", ...)
    private func generateDuplicateTitle(from originalTitle: String) -> String {
        let existingTitles = Set(projects.map { $0.title })

        var counter = 1
        while true {
            let candidateTitle = "\(originalTitle)(\(counter))"
            if !existingTitles.contains(candidateTitle) {
                return candidateTitle
            }
            counter += 1
        }
    }

    // MARK: - Public Methods

    /// 프로젝트 선택 및 SceneModel 로드
    func selectProject(project: Project) {
        guard projectRepository.fetchProject(project) != nil else {
#if DEBUG
            print("[ProjectListViewModel] selectProject - ⚠️ Project not found: \(project.id)")
#endif
            return
        }

        let sceneModel = loadSceneModel(for: project)
        appStateManager.selectProject(project, scene: sceneModel)
    }

    /// SceneModel 로드 또는 기본값 생성
    private func loadSceneModel(for project: Project) -> SceneModel {
        do {
            if sceneModelStorage.exists(projectName: project.title) {
                let sceneModel = try sceneModelStorage.load(
                    projectName: project.title,
                    projectId: project.id
                )
                print("📂 Floor Asset ID: \(sceneModel.spacialEnvironment.floorAssetId ?? String(localized: "project.none"))")
                print("📂 기존 SceneModel 로드 완료")
                return sceneModel
            } else {
                return SceneModel(
                    projectId: project.id,
                    spacialEnvironment: SpacialEnvironment(),
                    userSpatialState: UserSpatialState(),
                    sceneObjects: []
                )
            }
        } catch {
            print("❌ SceneModel 로드 실패: \(error)")
            return SceneModel(
                projectId: project.id,
                spacialEnvironment: SpacialEnvironment(),
                userSpatialState: UserSpatialState(),
                sceneObjects: []
            )
        }
    }
    
    /// 새 프로젝트 생성 (제목이 없으면 자동 생성)
    @discardableResult
    func createProject(title: String? = nil) throws -> Project {
        let projectTitle = title?.isEmpty == false ? title! : generateUniqueProjectTitle()
        let spacialEnvironment = SpacialEnvironment()

        let newProject = Project(
            title: projectTitle,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        projectRepository.addProject(newProject)
        refreshProjects()

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

    /// 프로젝트 제목 수정 (파일 시스템 및 DB 동기화)
    func updateProjectTitle(project: Project, newTitle: String) {
        do {
            try projectFileStorage.rename(from: project.title, to: newTitle)
            try projectRepository.updateProjectTitle(project, newTitle: newTitle)
            refreshProjects()

            if appStateManager.appState.selectedProject?.id == project.id,
               let selectedScene = appStateManager.selectedScene {
                if let updatedProject = projectRepository.fetchProject(project) {
                    appStateManager.selectProject(updatedProject, scene: selectedScene)
                }
                try sceneModelStorage.save(selectedScene, projectName: newTitle)
            }
        } catch {
#if DEBUG
            print("[ProjectListViewModel] updateProjectTitle - ❌ Error: \(error)")
#endif
        }
    }

    /// 프로젝트 삭제 (메타데이터, 파일, 디렉토리 모두 삭제)
    func deleteProject(project: Project) {
        guard projectRepository.fetchProject(project) != nil else {
            return
        }

        try? sceneModelStorage.delete(projectName: project.title)
        projectRepository.deleteProject(project)
        refreshProjects()

        if appStateManager.appState.selectedProject?.id == project.id {
            appStateManager.closeProject()
        }
    }

    /// 프로젝트 복제 (메타데이터, SceneModel, 이미지/사운드 파일 모두 복사)
    func duplicateProject(project: Project) {
        guard projectRepository.fetchProject(project) != nil else {
            return
        }

        let fileManager = FileManager.default
        let duplicateTitle = generateDuplicateTitle(from: project.title)

        do {
            let sourceSceneModel = try sceneModelStorage.load(
                projectName: project.title,
                projectId: project.id
            )

            let newProject = Project(
                title: duplicateTitle,
                thumbnailImage: project.thumbnailImage,
                createdAt: Date(),
                updatedAt: Date()
            )

            try projectFileStorage.save(newProject, projectName: duplicateTitle)

            let sourceImagesDir = FilePathProvider.imagesDirectory(projectName: project.title)
            let destImagesDir = FilePathProvider.imagesDirectory(projectName: duplicateTitle)

            if fileManager.fileExists(atPath: sourceImagesDir.path) {
                let imageFiles = try fileManager.contentsOfDirectory(atPath: sourceImagesDir.path)
                for filename in imageFiles {
                    let sourceFile = sourceImagesDir.appendingPathComponent(filename)
                    let destFile = destImagesDir.appendingPathComponent(filename)
                    try fileManager.copyItem(at: sourceFile, to: destFile)
                }
            }

            let sourceSoundsDir = FilePathProvider.soundsDirectory(projectName: project.title)
            let destSoundsDir = FilePathProvider.soundsDirectory(projectName: duplicateTitle)

            if fileManager.fileExists(atPath: sourceSoundsDir.path) {
                let soundFiles = try fileManager.contentsOfDirectory(atPath: sourceSoundsDir.path)
                for filename in soundFiles {
                    let sourceFile = sourceSoundsDir.appendingPathComponent(filename)
                    let destFile = destSoundsDir.appendingPathComponent(filename)
                    try fileManager.copyItem(at: sourceFile, to: destFile)
                }
            }

            // TODO: 썸네일 이미지 구현
            if let thumbnailName = project.thumbnailImage {
                let sourceThumbnail = FilePathProvider.imageFile(
                    projectName: project.title,
                    filename: thumbnailName
                )
                let destThumbnail = FilePathProvider.imageFile(
                    projectName: duplicateTitle,
                    filename: thumbnailName
                )

                if fileManager.fileExists(atPath: sourceThumbnail.path) {
                    try? fileManager.copyItem(at: sourceThumbnail, to: destThumbnail)
                }
            }

            let newSceneModel = SceneModel(
                projectId: newProject.id,
                spacialEnvironment: sourceSceneModel.spacialEnvironment,
                userSpatialState: UserSpatialState(),
                sceneObjects: sourceSceneModel.sceneObjects
            )

            try sceneModelStorage.save(newSceneModel, projectName: duplicateTitle)
            projectRepository.addProject(newProject)
            refreshProjects()
        } catch {
            try? projectFileStorage.delete(projectName: duplicateTitle)
        }
    }

    private func sortProjects(_ projects: [Project]) -> [Project] {
        switch sort {
        case .sort(.recent):
            return projects.sorted {
                if $0.updatedAt == $1.updatedAt { return $0.title < $1.title }
                return $0.updatedAt > $1.updatedAt
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
