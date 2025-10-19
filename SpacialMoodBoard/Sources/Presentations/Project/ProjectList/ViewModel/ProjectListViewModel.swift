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
  private var sceneState: AppSceneState
  private var projectRepository: ProjectRepository
  
  var searchText: String = ""
  
  var filteredProjects: [Project] {
    projectRepository.filterProjects(by: searchText)
  }
  
  init(sceneState: AppSceneState, projectRepository: ProjectRepository) {
    self.sceneState = sceneState
    self.projectRepository = projectRepository
    
    // 해당 코드 없으면 볼륨 재생성 안됨.
    let activeProjectID = sceneState.activeProjectID
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
    sceneState.activeProjectID = newProject.id
    
    return newProject
  }
  
  func selectProject(projectID: Project.ID) {
    guard projectRepository.fetchProject(by: projectID) != nil else {
#if DEBUG
      print("[ProjectListVM] selectProject - ⚠️ Project not found: \(projectID)")
#endif
      return
    }
    
    sceneState.activeProjectID = projectID
  }
  
  func updateProjectTitle(projectId: Project.ID, newTitle: String) {
    do {
      try projectRepository.updateProjectTitle(projectID: projectId, newTitle: newTitle)
    } catch {
#if DEBUG
      print("[ProjectListVM] updateProjectTitle - ❌ Error: \(error)")
#endif
    }
  }
  
  @discardableResult
  func deleteProject(projectId: Project.ID) -> Bool {
    guard projectRepository.fetchProject(by: projectId) != nil else {
#if DEBUG
      print("[ProjectListVM] deleteProject - ⚠️ Project not found: \(projectId)")
#endif
      return false
    }
    
    projectRepository.deleteProject(id: projectId)
    
    if sceneState.activeProjectID == projectId {
      sceneState.activeProjectID = nil
    }
    
    return true
  }
}
