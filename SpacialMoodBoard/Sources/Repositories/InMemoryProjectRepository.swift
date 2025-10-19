//
//  InMemoryProjectRepository.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/18/25.
//

import Foundation

// MARK: - InMemoryProjectRepository Implementation
/// Swift Data 구현 전 임시 메모리 기반 저장소
@MainActor
final class InMemoryProjectRepository: ProjectRepository {
  private var projects: [Project] = Project.mockData
  
  func fetchProjects() -> [Project] {
    return projects.sorted { $0.updatedAt > $1.updatedAt }
  }
  
  func fetchProject(by id: UUID) -> Project? {
    return projects.first { $0.id == id }
  }
  
  func addProject(_ project: Project) {
    guard !projects.contains(where: { $0.id == project.id }) else {
#if DEBUG
      print("[Repo] addProject - ⚠️ Project already exists: \(project.id)")
#endif
      return
    }
    projects.append(project)
  }
  
  func updateProject(_ project: Project) {
    guard let index = projects.firstIndex(where: { $0.id == project.id }) else {
#if DEBUG
      print("[Repo] updateProject - ⚠️ Project not found: \(project.id)")
#endif
      return
    }
    projects[index] = project
  }
  
  func deleteProject(id: UUID) {
    let initialCount = projects.count
    projects.removeAll { $0.id == id }
    
#if DEBUG
    if projects.count < initialCount {
      print("[Repo] deleteProject - ✅ Deleted project: \(id)")
    } else {
      print("[Repo] deleteProject - ⚠️ Project not found: \(id)")
    }
#endif
  }
  
  func updateProjectTitle(projectID: UUID, newTitle: String) throws {
    let trimmedTitle = newTitle.trimmingCharacters(in: .whitespaces)
    guard !trimmedTitle.isEmpty else {
      throw ProjectRepositoryError.emptyTitle
    }
    
    guard let index = projects.firstIndex(where: { $0.id == projectID }) else {
      throw ProjectRepositoryError.projectNotFound
    }
    
    projects[index].title = trimmedTitle
    projects[index].updatedAt = Date()
  }
  
  func filterProjects(by searchText: String) -> [Project] {
    guard !searchText.isEmpty else {
      return fetchProjects()
    }
    
    return projects
      .filter { $0.title.localizedCaseInsensitiveContains(searchText) }
      .sorted { $0.updatedAt > $1.updatedAt }
  }
}
