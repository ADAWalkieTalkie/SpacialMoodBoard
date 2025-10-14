//
//  ProjectListViewModel.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/9/25.
//

import Foundation
import Combine

@Observable
class ProjectListViewModel {
  var projects: [Project] = []
  var searchText: String = ""
  
  private let volumeSceneViewModel: VolumeSceneViewModel
  
  var filteredProjects: [Project] {
    filterProjects(by: searchText)
  }
  
  init(volumeSceneViewModel: VolumeSceneViewModel) {
    self.volumeSceneViewModel = volumeSceneViewModel
    self.projects = Project.mockData
  }
  
  @discardableResult
  func createProject(title: String, roomType: RoomType, groundSizePreset: GroundSizePreset) -> Project {
    let newProject = Project(title: title)
    addProject(newProject)
    
    volumeSceneViewModel.createScene(
      projectID: newProject.id,
      roomType: roomType,
      preset: groundSizePreset
    )
    volumeSceneViewModel.activateScene(for: newProject.id)
    
    return newProject
  }

  func selectProject(_ project: Project) {
    volumeSceneViewModel.activateScene(for: project.id)
  }
  
  func addProject(_ project: Project) {
    projects.append(project)
    projects.sort { $0.createdAt > $1.createdAt }
  }
  
  func updateProjectTitle(projectId: Project.ID, newTitle: String) {
    guard !newTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
    if let index = projects.firstIndex(where: { $0.id == projectId }) {
      projects[index].title = newTitle
      projects[index].updatedAt = Date()
    }
  }
  
  @discardableResult
  func deleteProject(projectId: Project.ID) -> Bool {
    guard let index = projects.firstIndex(where: { $0.id == projectId}) else {
      return false
    }
    projects.remove(at: index)
    
    volumeSceneViewModel.deleteScene(for: projectId)
    
    return true
  }
  
  private func filterProjects(by searchText: String) -> [Project] {
    guard !searchText.isEmpty else {
      return projects
    }
    
    return projects.filter {
      $0.title.localizedCaseInsensitiveContains(searchText)
    }
  }
  
  private func sortProjectsByCreatedDate() {
    projects.sort { $0.createdAt > $1.createdAt }
  }
}
