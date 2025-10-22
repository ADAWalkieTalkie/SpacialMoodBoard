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

    @discardableResult
    func createProject(
        title: String,
        roomType: RoomType,
        groundSize: GroundSize
    ) -> Project {
        let spacialEnvironment = SpacialEnvironment(
            roomType: roomType,
            groundSize: groundSize
        )
        let newProject = Project(
            title: title,
            createdAt: Date(),
            updatedAt: Date()
        )

        projectRepository.addProject(newProject)
        refreshProjects()
        appModel.selectedProject = newProject

        return newProject
    }

    func selectProject(project: Project) {
        guard projectRepository.fetchProject(project) != nil else {
            #if DEBUG
                print(
                    "[ProjectListVM] selectProject - ⚠️ Project not found: \(project.id)"
                )
            #endif
            return
        }
        appModel.selectedProject = project
    }

    func updateProjectTitle(project: Project, newTitle: String) {
        do {
            try projectRepository.updateProjectTitle(
                project,
                newTitle: newTitle
            )
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
                print(
                    "[ProjectListVM] deleteProject - ⚠️ Project not found: \(project.id)"
                )
            #endif
            return false
        }

        projectRepository.deleteProject(project)
        refreshProjects()

        if appModel.selectedProject?.id == project.id {
            appModel.selectedProject = nil
        }

        return true
    }
}
