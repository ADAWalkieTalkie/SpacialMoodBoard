//
//  SwiftDataProjectRepository.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/22/25.
//

import Foundation
import SwiftData

// MARK: - SwiftDataProjectRepository Implementation
/// Swift Data를 사용한 프로젝트 저장소 구현
@MainActor
final class SwiftDataProjectRepository: ProjectRepository {
  private let modelContext: ModelContext
  
  // MARK: - Initialization
  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }
  
  // MARK: - ProjectRepository Protocol Implementation
  
  func loadInitialData() {
    // 기존 데이터가 있는지 확인
    let descriptor = FetchDescriptor<Project>()
    
    do {
      let existingProjects = try modelContext.fetch(descriptor)
      
      // 데이터가 없으면 목 데이터 추가
      if existingProjects.isEmpty {
        for mockProject in Project.mockData {
          modelContext.insert(mockProject)
        }
        
        try modelContext.save()
        
#if DEBUG
        print("[SwiftData] ✅ Initial mock data loaded: \(Project.mockData.count) projects")
#endif
      } else {
#if DEBUG
        print("[SwiftData] ℹ️ Data already exists: \(existingProjects.count) projects")
#endif
      }
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to load initial data: \(error)")
#endif
    }
  }
  
  func fetchProjects() -> [Project] {
    let descriptor = FetchDescriptor<Project>(
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
    )
    
    do {
      return try modelContext.fetch(descriptor)
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to fetch projects: \(error)")
#endif
      return []
    }
  }
  
  func fetchProject(_ project: Project) -> Project? {
    let descriptor = FetchDescriptor<Project>(
      predicate: #Predicate { $0.id == project.id }
    )
    
    do {
      let results = try modelContext.fetch(descriptor)
      return results.first
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to fetch project: \(error)")
#endif
      return nil
    }
  }
  
  func addProject(_ project: Project) {
    // 중복 확인
    if fetchProject(project) != nil {
#if DEBUG
      print("[SwiftData] ⚠️ Project already exists: \(project.id)")
#endif
      return
    }
    
    modelContext.insert(project)
    
    do {
      try modelContext.save()
#if DEBUG
      print("[SwiftData] ✅ Project added: \(project.title)")
#endif
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to add project: \(error)")
#endif
    }
  }
  
  func updateProject(_ project: Project) {
    // Swift Data는 자동으로 변경사항을 추적하므로
    // 이미 컨텍스트에 있는 객체라면 자동으로 업데이트
    project.updatedAt = Date()
    
    do {
      try modelContext.save()
#if DEBUG
      print("[SwiftData] ✅ Project updated: \(project.title)")
#endif
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to update project: \(error)")
#endif
    }
  }
  
  func deleteProject(_ project: Project) {
    modelContext.delete(project)
    
    do {
      try modelContext.save()
#if DEBUG
      print("[SwiftData] ✅ Project deleted: \(project.id)")
#endif
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to delete project: \(error)")
#endif
    }
  }
  
  func updateProjectTitle(_ project: Project, newTitle: String) throws {
    let trimmedTitle = newTitle.trimmingCharacters(in: .whitespaces)
    
    guard !trimmedTitle.isEmpty else {
      throw ProjectRepositoryError.emptyTitle
    }
    
    guard let existingProject = fetchProject(project) else {
      throw ProjectRepositoryError.projectNotFound
    }
    
    existingProject.title = trimmedTitle
    existingProject.updatedAt = Date()
    
    do {
      try modelContext.save()
#if DEBUG
      print("[SwiftData] ✅ Project title updated: \(trimmedTitle)")
#endif
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to update project title: \(error)")
#endif
      throw error
    }
  }
  
  func filterProjects(by searchText: String) -> [Project] {
    guard !searchText.isEmpty else {
      return fetchProjects()
    }
    
    let descriptor = FetchDescriptor<Project>(
      predicate: #Predicate { project in
        project.title.localizedStandardContains(searchText)
      },
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
    )
    
    do {
      return try modelContext.fetch(descriptor)
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to filter projects: \(error)")
#endif
      return []
    }
  }
}

// MARK: - Additional Convenience Methods
extension SwiftDataProjectRepository {
  /// 프로젝트 썸네일 이미지 업데이트
  func updateThumbnailImage(_ project: Project, imageName: String?) throws {
    guard let existingProject = fetchProject(project) else {
      throw ProjectRepositoryError.projectNotFound
    }
    
    existingProject.thumbnailImage = imageName
    existingProject.updatedAt = Date()
    
    do {
      try modelContext.save()
#if DEBUG
      print("[SwiftData] ✅ Thumbnail updated for: \(project.title)")
#endif
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to update thumbnail: \(error)")
#endif
      throw error
    }
  }
  
  /// 프로젝트 디렉토리 업데이트
  func updateProjectDirectory(_ project: Project, directory: URL?) throws {
    guard let existingProject = fetchProject(project) else {
      throw ProjectRepositoryError.projectNotFound
    }
    
    existingProject.projectDirectory = directory
    existingProject.updatedAt = Date()
    
    do {
      try modelContext.save()
#if DEBUG
      print("[SwiftData] ✅ Directory updated for: \(project.title)")
#endif
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to update directory: \(error)")
#endif
      throw error
    }
  }
  
  /// 모든 프로젝트 삭제 (개발/테스트용)
  func deleteAllProjects() {
    let descriptor = FetchDescriptor<Project>()
    
    do {
      let allProjects = try modelContext.fetch(descriptor)
      for project in allProjects {
        modelContext.delete(project)
      }
      try modelContext.save()
      
#if DEBUG
      print("[SwiftData] ✅ All projects deleted")
#endif
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to delete all projects: \(error)")
#endif
    }
  }
  
  /// 프로젝트 개수 반환
  func projectCount() -> Int {
    let descriptor = FetchDescriptor<Project>()
    
    do {
      return try modelContext.fetchCount(descriptor)
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to fetch project count: \(error)")
#endif
      return 0
    }
  }
}
