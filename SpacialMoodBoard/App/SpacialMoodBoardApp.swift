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
    @State private var sceneViewModel: SceneViewModel

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
            _sceneViewModel = State(
                wrappedValue: SceneViewModel(
                    appModel: appModel,
                    sceneRepository: SceneRepository(
                        usageIndex: AssetUsageIndex()
                    )
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
                                assetRepository: AssetRepository(
                                    project: appModel.selectedProject?.title ?? "",
                                    imageService: ImageAssetService(),
                                    soundService: SoundAssetService()
                                )
                            ),
                            // TODO: - 리팩토링 필요
                            sceneViewModel: sceneViewModel
                        )

                        Divider()

                        DummyView(viewModel: sceneViewModel)
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
                viewModel: sceneViewModel
            )
            .environment(appModel)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.5, height: 1.5, depth: 1.5, in: .meters)

        // Immersive Space (전체 몰입)
        ImmersiveSpace(id: "ImmersiveScene") {
            ImmersiveSceneView(viewModel: sceneViewModel)
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
