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
    @State private var appStateManager = AppStateManager()
    @State private var projectRepository: ProjectServiceInterface
    @State private var assetRepository: AssetRepository
    @State private var renameAssetUseCase: RenameAssetUseCase
    @State private var deleteAssetUseCase: DeleteAssetUseCase
    @State private var sceneModelFileStorage: SceneModelFileStorage
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
            let repository = ProjectService(
                modelContext: container.mainContext
            )
            _projectRepository = State(wrappedValue: repository)

            let sceneModelFileStorage = SceneModelFileStorage(projectRepository: repository)
            _sceneModelFileStorage = State(wrappedValue: sceneModelFileStorage)

            let appStateManager = AppStateManager()
            _appStateManager = State(wrappedValue: appStateManager)

            let assetRepository = AssetRepository(
                project: appStateManager.appState.selectedProject?.title ?? "",
                imageService: ImageAssetService(),
                soundService: SoundAssetService()
            )
            _assetRepository = State(wrappedValue: assetRepository)

            let usageIndex = AssetUsageIndex()
            let sceneObjectRepository = SceneObjectRepository(usageIndex: usageIndex)

            let renameAssetUseCase = RenameAssetUseCase(
                assetRepository: assetRepository,
                sceneObjectRepository: sceneObjectRepository
            )
            _renameAssetUseCase = State(wrappedValue: renameAssetUseCase)

            let deleteAssetUseCase = DeleteAssetUseCase(
                assetRepository: assetRepository,
                sceneObjectRepository: sceneObjectRepository
            )
            _deleteAssetUseCase = State(wrappedValue: deleteAssetUseCase)

            // EntityRepository 생성
            let entityRepository = EntityRepository()

            // Volume Scene용 ViewModel
            let sceneViewModel = SceneViewModel(
                appStateManager: appStateManager,
                sceneModelFileStorage: sceneModelFileStorage,
                sceneObjectRepository: sceneObjectRepository,
                assetRepository: assetRepository,
                entityRepository: entityRepository
            )
            _sceneViewModel = State(wrappedValue: sceneViewModel)
        } catch {
            fatalError("❌ Failed to initialize ModelContainer: \(error)")
        }
    }
    var body: some Scene {
        WindowGroup(id: "MainWindow") {
            MainWindowContent(
                appStateManager: appStateManager,
                assetRepository: assetRepository,
                projectRepository: projectRepository,
                renameAssetUseCase: renameAssetUseCase,
                deleteAssetUseCase: deleteAssetUseCase,
                sceneModelFileStorage: sceneModelFileStorage,
                sceneViewModel: sceneViewModel,
                modelContainer: modelContainer
            )
        }

        // Volume Scene
        WindowGroup(id: "ImmersiveVolumeWindow") {
            VolumeSceneView(
                viewModel: sceneViewModel
            )
            .environment(appStateManager)
            
        }
        .windowStyle(.volumetric)
        .volumeWorldAlignment(.gravityAligned)
        .defaultSize(width: 1.0, height: 1.0, depth: 1.0, in: .meters)

        // Immersive Space (전체 몰입)
        ImmersiveSpace(id: "ImmersiveScene") {
            ImmersiveSceneView(viewModel: sceneViewModel)
                .environment(appStateManager)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
