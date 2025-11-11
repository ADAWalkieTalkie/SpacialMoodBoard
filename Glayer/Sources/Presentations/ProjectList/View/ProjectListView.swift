//
//  ProjectListView.swift
//  Glayer
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            let columns = [GridItem(.adaptive(minimum: 348, maximum: 360), spacing: 30)]
            LazyVGrid(columns: columns, spacing: 0) {
                ProjectCreationButton {
                    do {
                        try viewModel.createProject()
                    } catch {
                        print("프로젝트 생성 실패: \(error)")
                    }
                }
                .frame(width: 360, height: 328)

                ForEach(viewModel.filteredProjects) { project in
                    ProjectItemView(project: project)
                        .frame(width: 360, height: 328)
//                        .hoverEffect(.highlight)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                viewModel.selectProject(project: project)
                            },
                            including: .gesture
                        )
                }
                
            }
            .padding(.horizontal, 0)
        }
    }

    private var headerView: some View {
        HStack(alignment: .center, spacing: 16) {
            SortSegment(selection: $viewModel.sort, group: .sort)
                .frame(width: 188, height: 44)

            Spacer()

            CenteredVisionSearchBar(text: $viewModel.searchText)
                .frame(width: 305, height: 44)
        }
        .overlay(
            Text(String(localized: "project.title"))
                .font(.system(size: 29, weight: .bold)),
            alignment: .center
        )
        .padding(28.5)
        .padding(.bottom, -20)
    }
}
