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
    @State private var projectRepository: ProjectServiceInterface
    @State private var assetRepository: AssetRepository
    @State private var renameAssetUseCase: RenameAssetUseCase
    @State private var deleteAssetUseCase: DeleteAssetUseCase
    @State private var sceneViewModel: SceneViewModel
    @State private var initialVolumeSize: Size3D = Size3D(width: 1000, height: 1000, depth: 1000)

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

            let appModel = AppModel()
            _appModel = State(wrappedValue: appModel)

            let assetRepository = AssetRepository(
                project: appModel.selectedProject?.title ?? "",
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
                appModel: appModel,
                sceneObjectRepository: sceneObjectRepository,
                assetRepository: assetRepository,
                entityRepository: entityRepository,
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
                renameAssetUseCase: renameAssetUseCase,
                deleteAssetUseCase: deleteAssetUseCase,
                sceneViewModel: sceneViewModel,
                modelContainer: modelContainer
            )
        }

        // Volume Scene
        WindowGroup(id: "ImmersiveVolumeWindow") {
            VolumeSceneView(
                viewModel: sceneViewModel
            )
            .environment(appModel)
            
        }
        .windowStyle(.volumetric)
        .volumeWorldAlignment(.gravityAligned)
        .defaultSize(width: 1.0, height: 1.0, depth: 1.0, in: .meters)

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
