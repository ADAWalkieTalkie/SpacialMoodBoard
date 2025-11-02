//
//  ProjectListView.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/9/25.
//

import Observation
import SwiftUI

struct ProjectListView: View {
    @State private var viewModel: ProjectListViewModel
    
    init(viewModel: ProjectListViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            projectGridView
                .navigationTitle("프로젝트")
                .searchable(text: $viewModel.searchText, prompt: "search")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        SortSegment(selection: $viewModel.sort)
                            .frame(width: 188, height: 44)
                    }
                }
        }
        .glassBackgroundEffect()
        .environment(viewModel)
    }
    
    // MARK: - Project Grid View
    private var projectGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 3),
                spacing: 40
            ) {
                ProjectCreationButton {
                    do {
                        try viewModel.createProject()
                    } catch {
                        print("프로젝트 생성 실패: \(error)")
                        // TODO: 사용자에게 에러 알림 표시
                    }
                }
                .padding(.horizontal, 30)
                
                ForEach(viewModel.filteredProjects) { project in
                    ProjectItemView(project: project)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                viewModel.selectProject(project: project)
                            },
                            including: .gesture
                        )
                        .padding(.horizontal, 30)
                }
            }
            .padding(.horizontal, 60)
        }
    }
}
