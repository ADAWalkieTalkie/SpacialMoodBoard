//
//  ProjectListViewModel2.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/9/25.
//

import Foundation
import Combine

@Observable
class ProjectListViewModel {
  var projects: [Project] = []
  
  init () {
    self.projects = Project.mockData
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
  
  
}
