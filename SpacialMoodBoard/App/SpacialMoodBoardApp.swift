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
    @State private var assetRepository: AssetRepository
    @State private var deleteAssetUseCase: DeleteAssetUseCase
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

            let assetRepository = AssetRepository(
                project: appModel.selectedProject?.title ?? "",
                imageService: ImageAssetService(),
                soundService: SoundAssetService()
            )
            _assetRepository = State(wrappedValue: assetRepository)
            let sceneRepository = SceneRepository(usageIndex: AssetUsageIndex())
            
            let deleteAssetUseCase = DeleteAssetUseCase(
                assetRepository: assetRepository,
                sceneRepository: sceneRepository
            )
            _deleteAssetUseCase = State(wrappedValue: deleteAssetUseCase)
          

            // Volume Scene용 ViewModel
            let sceneViewModel = SceneViewModel(
                appModel: appModel,
                sceneRepository: sceneRepository,
                assetRepository: assetRepository,
                projectRepository: repository
            )
            _sceneViewModel = State(wrappedValue: sceneViewModel)
        } catch {
            fatalError("❌ Failed to initialize ModelContainer: \(error)")
        }
    }
    var body: some Scene {
        WindowGroup(id: "MainWindow") {
            MainWindowContent(
                appModel: appModel,
                assetRepository: assetRepository,
                projectRepository: projectRepository,
                deleteAssetUseCase: deleteAssetUseCase,
                sceneViewModel: sceneViewModel,
                modelContainer: modelContainer
            )
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
