//
//  ProjectListViewModel.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/9/25.
//

import Foundation
import Observation

@MainActor
@Observable
final class ProjectListViewModel {
  private var appModel: AppModel
  private let projectRepository: ProjectRepository
  private let sceneModelStorage = SceneModelFileStorage()
  

    var searchText: String = ""

    private(set) var projects: [Project] = []

    var filteredProjects: [Project] {
        guard !searchText.isEmpty else {
            return projects
        }
        return
            projects
            .filter { $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    init(appModel: AppModel, projectRepository: ProjectRepository) {
        self.appModel = appModel
        self.projectRepository = projectRepository

        // 초기 데이터 로드 (향후 Task { await ... } 형태로 변경)
        projectRepository.loadInitialData()
        refreshProjects()
    }

  private func refreshProjects() {
    projects = projectRepository.fetchProjects()
  }
  
  
  func selectProject(project: Project) {
    guard projectRepository.fetchProject(project) != nil else {
#if DEBUG
      print("[ProjectListVM] selectProject - ⚠️ Project not found: \(project.id)")
#endif
      return
    }
    
    // 1. Project 선흑
    appModel.selectedProject = project
    
    // 2. SceneModel 로드 (파일이 있으면 로드, 없으면 기본값 생성)
    loadSceneModel(for: project)
  }
  
  // SceneModel 로드 또는 생성
  private func loadSceneModel(for project: Project) {
    do {
      // 파일이 있으면 로드
      if sceneModelStorage.exists(projectName: project.title) {
        let sceneModel = try sceneModelStorage.load(
          projectName: project.title,
          projectId: project.id
        )
        appModel.selectedScene = sceneModel
        print("📂 기존 SceneModel 로드 완료")
      } else {
        // 파일이 없으면 기본값 생성
        let defaultScene = SceneModel(
          projectId: project.id,
          spacialEnvironment: SpacialEnvironment(roomType: .indoor, groundSize: .medium),
          userSpatialState: UserSpatialState(),
          sceneObjects: []
        )
        appModel.selectedScene = defaultScene
        print("✨ 새 SceneModel 생성")
      }
    } catch {
      print("❌ SceneModel 로드 실패: \(error)")
      // 실패 시 기본값 생성
      appModel.selectedScene = SceneModel(
        projectId: project.id,
        spacialEnvironment: SpacialEnvironment(roomType: .indoor, groundSize: .medium),
        userSpatialState: UserSpatialState(),
        sceneObjects: []
      )
    }
  }
  
  @discardableResult
  func createProject(
    title: String,
    roomType: RoomType,
    groundSize: GroundSize
  ) -> Project {
    let spacialEnvironment = SpacialEnvironment(roomType: roomType, groundSize: groundSize)
    let newProject = Project(title: title, createdAt: Date(), updatedAt: Date())

    projectRepository.addProject(newProject)
    refreshProjects()
    
    appModel.selectedProject = newProject
    
    // 새 SceneModel 생성
    appModel.selectedScene = SceneModel(
      projectId: newProject.id,
      spacialEnvironment: spacialEnvironment,
      userSpatialState: UserSpatialState(),
      sceneObjects: []
    )
    
    return newProject
  }

  func updateProjectTitle(project: Project, newTitle: String) {
    do {
      try projectRepository.updateProjectTitle(project, newTitle: newTitle)
      refreshProjects()
      
      // 선택된 프로젝트의 제목이 변경되면 AppModel도 업데이트
      if appModel.selectedProject?.id == project.id {
        appModel.selectedProject?.title = newTitle
      }
    } catch {
#if DEBUG
      print("[ProjectListVM] updateProjectTitle - ❌ Error: \(error)")
#endif
    }
  }
  
  @discardableResult
  func deleteProject(project: Project) -> Bool {
    guard projectRepository.fetchProject(project) != nil else {
      return false
    }
    
    // SceneModel 파일도 함께 삭제
    try? sceneModelStorage.delete(projectName: project.title)
    
    projectRepository.deleteProject(project)
    refreshProjects()
    
    if appModel.selectedProject?.id == project.id {
      appModel.selectedProject = nil
      appModel.selectedScene = nil
    }
}