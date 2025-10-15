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
  
  @State private var viewModel = ProjectListViewModel()
  @State private var path = NavigationPath()
  
  var body: some View {
    NavigationStack(path: $path) {
      projectGridView()
        .navigationTitle("Projects")
        .searchable(text: $viewModel.searchText, prompt: "search")
        .navigationDestination(for: CreationStep.self) { step in
          destinationView(for: step, viewModel: viewModel)
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
        
        ForEach(viewModel.filteredProjects) { project in
          ProjectItemView(
            project: project,
            onTap: {
              openWindow(id: VolumeSceneViewModel.volumeWindowID)
            },
            onTitleChanged: { newTitle in
              viewModel.updateProjectTitle(projectId: project.id, newTitle: newTitle)
            },
            onDelete: {
              viewModel.deleteProject(projectId: project.id)
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
  private func destinationView(for step: CreationStep, viewModel: ProjectListViewModel) -> some View {
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
        _ = viewModel.createProject(
          title: projectTitle,
          roomType: roomType,
          groundSize: groundSize
        )
        
        openWindow(id: VolumeSceneViewModel.volumeWindowID)
        
        path.removeLast(path.count)
      }
    }
  }
}

#Preview {
  ProjectListView()
}
