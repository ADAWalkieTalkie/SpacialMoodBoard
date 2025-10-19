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
  private var projectRepository: ProjectRepository
  
  var searchText: String = ""
  
  var filteredProjects: [Project] {
    projectRepository.filterProjects(by: searchText)
  }
  
  init(appModel: AppModel, projectRepository: ProjectRepository) {
    self.appModel = appModel
    self.projectRepository = projectRepository
    
    // 해당 코드 없으면 볼륨 재생성 안됨.
    let activeProjectID = appModel.activeProjectID
  }
  
  @discardableResult
  func createProject(
    title: String,
    roomType: RoomType,
    groundSize: GroundSize
  ) -> Project {
    let scene = VolumeScene(roomType: roomType, groundSize: groundSize)
    let newProject = Project(title: title, volumeScene: scene)

    projectRepository.addProject(newProject)
    appModel.selectedProject = newProject
    
    return newProject
  }
  
  func selectProject(project: Project) {
    guard projectRepository.fetchProject(project) != nil else {
#if DEBUG
      print("[ProjectListVM] selectProject - ⚠️ Project not found: \(project.id)")
#endif
      return
    }
    appModel.selectedProject = project
  }
  
  func updateProjectTitle(project: Project, newTitle: String) {
    do {
      try projectRepository.updateProjectTitle(project, newTitle: newTitle)
    } catch {
#if DEBUG
      print("[ProjectListVM] updateProjectTitle - ❌ Error: \(error)")
#endif
    }
  }
  
  @discardableResult
  func deleteProject(project: Project) -> Bool {
    guard projectRepository.fetchProject(project) != nil else {
#if DEBUG
      print("[ProjectListVM] deleteProject - ⚠️ Project not found: \(project.id)")
#endif
      return false
    }
    
    projectRepository.deleteProject(project)
    
    if appModel.selectedProject?.id == project.id {
      appModel.selectedProject = nil
    }
    
    return true
  }
}
