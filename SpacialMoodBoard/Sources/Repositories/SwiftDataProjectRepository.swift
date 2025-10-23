//
//  SwiftDataProjectRepository.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/22/25.
//  Optimized: 10/23/25
//

import Foundation
import SwiftData

// MARK: - SwiftDataProjectRepository Implementation

/// Swift Data를 사용한 프로젝트 저장소 구현
@MainActor
final class SwiftDataProjectRepository: ProjectRepository {
  private let modelContext: ModelContext
  
  // MARK: - Initialization
  
  /// - Parameter modelContext: SwiftData의 ModelContext
  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }
  
  // MARK: - Private Helper Methods
  
  /// 프로젝트가 현재 ModelContext에 등록되어 있는지 확인 (이미 메모리에 있으면 fetch 건너뜀)
  /// - Parameter project: 확인할 프로젝트
  /// - Returns: 컨텍스트에 등록된 프로젝트 객체, 없으면 nil
  private func getRegisteredProject(_ project: Project) -> Project? {
    if project.modelContext === modelContext {
      return project
    }
    return fetchProject(project)
  }
  
  /// 프로젝트가 현재 ModelContext에 등록되어 있는지 확인
  /// - Parameter project: 확인할 프로젝트
  /// - Returns: 등록되어 있으면 true, 아니면 false
  private func isProjectRegistered(_ project: Project) -> Bool {
    return project.modelContext === modelContext
  }
  
  // MARK: - ProjectRepository Protocol Implementation
  
  /// 앱 최초 실행 시 초기 mock 데이터 로드
  func loadInitialData() {
    let descriptor = FetchDescriptor<Project>()
    
    do {
      let existingProjects = try modelContext.fetch(descriptor)
      
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
  
  /// 모든 프로젝트 조회 (updatedAt 기준 최신순 정렬)
  /// - Returns: 프로젝트 배열, 에러 시 빈 배열 반환
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
  
  /// 특정 프로젝트를 ID로 조회
  /// - Parameter project: 조회할 프로젝트 (ID 사용)
  /// - Returns: 조회된 프로젝트, 없으면 nil
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
  
  /// 새 프로젝트 추가 (중복 ID 자동 방지)
  /// - Parameter project: 추가할 프로젝트
  func addProject(_ project: Project) {
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
  
  /// 프로젝트 업데이트 (updatedAt 시간 갱신)
  /// - Parameter project: 업데이트할 프로젝트
  func updateProject(_ project: Project) {
    guard let existingProject = getRegisteredProject(project) else {
#if DEBUG
      print("[SwiftData] ⚠️ Project not found: \(project.id)")
#endif
      return
    }
    
    existingProject.updatedAt = Date()
    
    do {
      try modelContext.save()
#if DEBUG
      print("[SwiftData] ✅ Project updated: \(existingProject.title)")
#endif
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to update project: \(error)")
#endif
    }
  }
  
  /// 프로젝트 삭제
  /// - Parameter project: 삭제할 프로젝트
  func deleteProject(_ project: Project) {
    if isProjectRegistered(project) {
      modelContext.delete(project)
    } else {
      guard let existingProject = fetchProject(project) else {
#if DEBUG
        print("[SwiftData] ⚠️ Project not found for deletion: \(project.id)")
#endif
        return
      }
      modelContext.delete(existingProject)
    }
    
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
  
  /// 프로젝트 제목 수정
  /// - Parameters:
  ///   - project: 수정할 프로젝트
  ///   - newTitle: 새로운 제목
  /// - Throws: ProjectRepositoryError (emptyTitle, projectNotFound)
  func updateProjectTitle(_ project: Project, newTitle: String) throws {
    let trimmedTitle = newTitle.trimmingCharacters(in: .whitespaces)
    
    guard !trimmedTitle.isEmpty else {
      throw ProjectRepositoryError.emptyTitle
    }
    
    guard let existingProject = getRegisteredProject(project) else {
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
  
  /// 프로젝트 검색 (제목 기준)
  /// - Parameter searchText: 검색어 (빈 문자열이면 전체 반환)
  /// - Returns: 검색 결과 프로젝트 배열, 에러 시 빈 배열 반환
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
  /// - Parameters:
  ///   - project: 업데이트할 프로젝트
  ///   - imageName: 새로운 썸네일 이미지 이름
  /// - Throws: ProjectRepositoryError.projectNotFound
  func updateThumbnailImage(_ project: Project, imageName: String?) throws {
    guard let existingProject = getRegisteredProject(project) else {
      throw ProjectRepositoryError.projectNotFound
    }
    
    existingProject.thumbnailImage = imageName
    existingProject.updatedAt = Date()
    
    do {
      try modelContext.save()
#if DEBUG
      print("[SwiftData] ✅ Thumbnail updated for: \(existingProject.title)")
#endif
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to update thumbnail: \(error)")
#endif
      throw error
    }
  }
  
  /// 프로젝트 디렉토리 업데이트
  /// - Parameters:
  ///   - project: 업데이트할 프로젝트
  ///   - directory: 새로운 프로젝트 디렉토리 URL
  /// - Throws: ProjectRepositoryError.projectNotFound
  func updateProjectDirectory(_ project: Project, directory: URL?) throws {
    guard let existingProject = getRegisteredProject(project) else {
      throw ProjectRepositoryError.projectNotFound
    }
    
    existingProject.projectDirectory = directory
    existingProject.updatedAt = Date()
    
    do {
      try modelContext.save()
#if DEBUG
      print("[SwiftData] ✅ Directory updated for: \(existingProject.title)")
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
  /// - Returns: 저장된 프로젝트 개수, 에러 시 0 반환
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

// MARK: - Batch Operations

extension SwiftDataProjectRepository {
  
  /// 여러 프로젝트를 한 번에 업데이트 (성능 최적화)
  /// - Parameter projects: 업데이트할 프로젝트 배열
  func batchUpdateProjects(_ projects: [Project]) {
    var updatedCount = 0
    
    for project in projects {
      if let existingProject = getRegisteredProject(project) {
        existingProject.updatedAt = Date()
        updatedCount += 1
      }
    }
    
    guard updatedCount > 0 else {
#if DEBUG
      print("[SwiftData] ⚠️ No projects to update")
#endif
      return
    }
    
    do {
      try modelContext.save()
#if DEBUG
      print("[SwiftData] ✅ Batch updated \(updatedCount) projects")
#endif
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to batch update: \(error)")
#endif
    }
  }
  
  /// 여러 프로젝트를 한 번에 삭제 (성능 최적화)
  /// - Parameter projects: 삭제할 프로젝트 배열
  func batchDeleteProjects(_ projects: [Project]) {
    var deletedCount = 0
    
    for project in projects {
      if isProjectRegistered(project) {
        modelContext.delete(project)
        deletedCount += 1
      } else if let existingProject = fetchProject(project) {
        modelContext.delete(existingProject)
        deletedCount += 1
      }
    }
    
    guard deletedCount > 0 else {
#if DEBUG
      print("[SwiftData] ⚠️ No projects to delete")
#endif
      return
    }
    
    do {
      try modelContext.save()
#if DEBUG
      print("[SwiftData] ✅ Batch deleted \(deletedCount) projects")
#endif
    } catch {
#if DEBUG
      print("[SwiftData] ❌ Failed to batch delete: \(error)")
#endif
    }
  }
}
