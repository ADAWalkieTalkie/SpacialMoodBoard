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
  
  var filteredProjects: [Project] {
    filterProjects(by: searchText)
  }
  
  init() {
    self.projects = Project.mockData
  }
  
  @discardableResult
  func createProject(title: String, roomType: RoomType, groundSize: GroundSize) -> Project {
    let Scene = VolumeScene(roomType: roomType, groundSize: groundSize)
    let newProject = Project(title: title, volumeScene: Scene)
    
    addProject(newProject)
    
    return newProject
  }
  
  // SwiftData에 저장하는 로직으로 변경(예정)
  func addProject(_ project: Project) {
    projects.append(project)
    projects.sort { $0.createdAt > $1.createdAt } // 정렬 순서에 맞춰 정렬 로직 수정(예정)
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
  
  private func openProject() {
    
  }
}
