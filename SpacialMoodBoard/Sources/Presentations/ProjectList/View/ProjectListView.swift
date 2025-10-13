//
//  ProjectListView.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/9/25.
//

import SwiftUI

struct ProjectListView: View {
  @State private var viewModel = ProjectListViewModel()
  @State private var path = NavigationPath()
  
  private let columns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 3)
  
  // MARK: - Main View
  var body: some View {
    NavigationStack(path: $path) {
      projectGridView
        .navigationTitle("Projects")
        .searchable(text: $viewModel.searchText, prompt: "search")
        .navigationDestination(for: CreationStep.self) { step in
          destinationView(for: step)
        }
    }
    .glassBackgroundEffect()
  }
  
  // MARK: - Project Grid View
  private var projectGridView: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 40) {
        ProjectCreationButton {
          path.append(CreationStep.roomTypeSelection)
        }
        .padding(.horizontal, 30)
        
        ForEach(viewModel.filteredProjects) { project in
          ProjectItemView(
            project: project,
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
        let newProject = viewModel.createProject(title: projectTitle)
        path.removeLast(path.count)
      }
    }
  }
}

#Preview {
  ProjectListView()
}
