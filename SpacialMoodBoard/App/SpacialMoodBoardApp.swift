//
//  SpacialMoodBoardApp.swift
//  SpacialMoodBoard
//
//  Created by apple on 10/2/25.
//

import SwiftData
import SwiftUI

@main
struct SpacialMoodBoardApp: App {
    let modelContainer: ModelContainer
    @State private var appModel = AppModel()
    @State private var projectRepository: ProjectRepository
    @State private var volumeSceneViewModel: SceneViewModel
    @State private var immersiveSceneViewModel: SceneViewModel
    init() {
        do {
            let container = try ModelContainer(
                for: Project.self,
                configurations: ModelConfiguration(
                    isStoredInMemoryOnly: false
                )
            )
            self.modelContainer = container
            let repository = SwiftDataProjectRepository(
                modelContext: container.mainContext
            )
            _projectRepository = State(wrappedValue: repository)
            let appModel = AppModel()
            _appModel = State(wrappedValue: appModel)
            // Volume Scene용 ViewModel
            _volumeSceneViewModel = State(
                wrappedValue: SceneViewModel(
                    appModel: appModel
                )
            )

            // Immersive Scene용 ViewModel
            _immersiveSceneViewModel = State(
                wrappedValue: SceneViewModel(
                    appModel: appModel
                )
            )
        } catch {
            fatalError("❌ Failed to initialize ModelContainer: \(error)")
        }
    }
    var body: some Scene {
        WindowGroup {
            Group {
                if appModel.selectedProject != nil {
                    VStack {
                        LibraryView(
                            viewModel: LibraryViewModel(
                                appModel: appModel
                            )
                        )

                        Divider()

                        DummyView(viewModel: volumeSceneViewModel)
                            .frame(height: 200)
                    }
                    .environment(appModel)
                } else {
                    ProjectListView(
                        viewModel: ProjectListViewModel(
                            appModel: appModel,
                            projectRepository: projectRepository
                        )
                    )
                    .environment(appModel)
                    .modelContainer(modelContainer)
                }
            }
        }

        // Volume Scene (Room 미리보기)
        WindowGroup(id: "ImmersiveVolumeWindow") {
            VolumeSceneView(
                viewModel: volumeSceneViewModel
            )
            .environment(appModel)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.5, height: 1.5, depth: 1.5, in: .meters)

        // Immersive Space (전체 몰입)
        ImmersiveSpace(id: "ImmersiveScene") {
            ImmersiveSceneView(viewModel: immersiveSceneViewModel)
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
