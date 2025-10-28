//
//  ProjectListView.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/9/25.
//

import Observation
import SwiftUI

struct ProjectListView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(AppModel.self) private var appModel

    @State private var viewModel: ProjectListViewModel

    init(viewModel: ProjectListViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            projectGridView
                .navigationTitle("Projects")
                .searchable(text: $viewModel.searchText, prompt: "search")
        }
        .glassBackgroundEffect()
    }

    // MARK: - Project Grid View
    private var projectGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 3),
                spacing: 40
            ) {
                ProjectCreationButton {
                    viewModel.createProject()
                    openWindow(id: "ImmersiveVolumeWindow")
                }
                .padding(.horizontal, 30)

                ForEach(viewModel.filteredProjects) { project in
                    ProjectItemView(
                        project: project,
                        onTap: {
                            viewModel.selectProject(project: project)
                            openWindow(id: "ImmersiveVolumeWindow")
                        },
                        onTitleChanged: { newTitle in
                            viewModel.updateProjectTitle(
                                project: project,
                                newTitle: newTitle
                            )
                        },
                        onDelete: {
                            viewModel.deleteProject(project: project)
                        }
                    )
                    .padding(.horizontal, 30)
                }
            }
            .padding(.horizontal, 60)
        }
    }
}
