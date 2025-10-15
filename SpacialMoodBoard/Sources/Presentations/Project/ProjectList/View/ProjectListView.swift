//
//  ProjectListView.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/9/25.
//

import SwiftUI
import Observation

struct ProjectListView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(VolumeSceneViewModel.self) private var sceneVM
  @Environment(ProjectListViewModel.self) private var projectVM 
  
  @State private var path = NavigationPath()
  
  var body: some View {
    @Bindable var projectBinding = projectVM
    
    NavigationStack(path: $path) {
      projectGridView()
        .navigationTitle("Projects")
        .searchable(text: $projectBinding.searchText, prompt: "search")
        .navigationDestination(for: CreationStep.self) { step in
          destinationView(for: step)
        }
    }
    .glassBackgroundEffect()
  }
  
  // MARK: - Project Grid View
  private func projectGridView() -> some View {
    ScrollView {
      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 40) {
        ProjectCreationButton {
          path.append(CreationStep.roomTypeSelection)
        }
        .padding(.horizontal, 30)
        
        ForEach(projectVM.filteredProjects) { project in
          ProjectItemView(
            project: project,
            onTap: {
              handleProjectSelection(project)
            },
            onTitleChanged: { newTitle in
              projectVM.updateProjectTitle(projectId: project.id, newTitle: newTitle)
            },
            onDelete: {
              handleProjectDeletion(project)
            }
          )
          .padding(.horizontal, 30)
        }
      }
      .padding(.horizontal, 60)
    }
  }
  
  // MARK: - Navigation Destinations
  @ViewBuilder
  private func destinationView(for step: CreationStep) -> some View {
    switch step {
    case .roomTypeSelection:
      RoomTypeSelectionView { roomType in
        path.append(CreationStep.groundSizeSelection(roomType: roomType))
      }
      
    case .groundSizeSelection(let roomType):
      GroundSizeSelectionView { groundSize in
        path.append(CreationStep.projectTitleInput(roomType: roomType, groundSize: groundSize))
      }
      
    case .projectTitleInput(let roomType, let groundSize):
      ProjectTitleInputView { projectTitle in
        handleProjectCreation(
          title: projectTitle,
          roomType: roomType,
          groundSize: groundSize
        )
      }
    }
  }
  
  // MARK: - View 관련 Business Logic
    private func handleProjectCreation(
      title: String,
      roomType: RoomType,
      groundSize: GroundSize
    ) {
      let project = projectVM.createProject(
        title: title,
        roomType: roomType,
        groundSize: groundSize
      )
      
      sceneVM.activateScene(for: project.id)
      
      openWindow(id: VolumeSceneViewModel.volumeWindowID)
      path.removeLast(path.count)
    }
    
    private func handleProjectSelection(_ project: Project) {
      sceneVM.activateScene(for: project.id)
      
      openWindow(id: VolumeSceneViewModel.volumeWindowID)
    }
    
    private func handleProjectDeletion(_ project: Project) {
      projectVM.deleteProject(projectId: project.id)
      
      sceneVM.deleteEntityCache(for: project.id)
    }
}

#Preview {
  ProjectListView()
    .environment(VolumeSceneViewModel())
    .environment(ProjectListViewModel())
}
