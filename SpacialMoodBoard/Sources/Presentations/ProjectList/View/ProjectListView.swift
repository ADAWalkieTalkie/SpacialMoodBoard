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
        VStack(spacing: 0) {
            headerView
            projectGridView
        }
        .glassBackgroundEffect()
        .environment(viewModel)
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Project Grid View
    private var projectGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 3),
                spacing: 35
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

    private var headerView: some View {
        HStack(alignment: .center, spacing: 16) {
            SortSegment(selection: $viewModel.sort)
                .frame(width: 188, height: 44)

            Spacer()

            CenteredVisionSearchBar(text: $viewModel.searchText)
                .frame(width: 305, height: 44)
        }
        .overlay(
            Text("프로젝트")
                .font(.system(size: 29, weight: .bold)),
            alignment: .center
        )
        .padding(24)
    }
}
