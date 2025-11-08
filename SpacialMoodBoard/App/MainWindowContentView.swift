import SwiftUI
import SwiftData

struct MainWindowContent: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow

    @Bindable var appStateManager: AppStateManager
    var assetRepository: AssetRepository
    var projectRepository: ProjectServiceInterface
    var renameAssetUseCase: RenameAssetUseCase
    var deleteAssetUseCase: DeleteAssetUseCase
    var sceneModelFileStorage: SceneModelFileStorage
    var sceneViewModel: SceneViewModel
    var modelContainer: ModelContainer

    // WindowCoordinator for centralized window management
    @State private var windowCoordinator: WindowCoordinator?

    var body: some View {
        Group {
            if appStateManager.appState.selectedProject != nil {
                VStack {
                    LibraryView(
                        viewModel: LibraryViewModel(
                            appStateManager: appStateManager,
                            assetRepository: assetRepository,
                            renameAssetUseCase: renameAssetUseCase,
                            deleteAssetUseCase: deleteAssetUseCase,
                            sceneModelFileStorage: sceneModelFileStorage
                        ),
                        sceneViewModel: sceneViewModel
                    )
                    .onBackground {
                        if appStateManager.appState.isImmersiveOpen {
                            appStateManager.closeProject()
                        } else {
                            appStateManager.closeApp()
                        }
                        
                    }
                }
                .environment(appStateManager)
                .task {
                    await assetRepository.switchProject(
                        to: appStateManager.appState.selectedProject?.title ?? ""
                    )
                }
                .onChange(of: appStateManager.appState.selectedProject?.title) { oldTitle, newTitle in
                    Task {
                        await assetRepository.switchProject(to: newTitle ?? "")
                    }
                }
            } else {
                ProjectListView(
                    viewModel: ProjectListViewModel(
                        appStateManager: appStateManager,
                        projectRepository: projectRepository
                    )
                )
                .modelContainer(modelContainer)
            }
        }
        // MARK: - Centralized Window Management (WindowCoordinator)
        .onAppear {
            // WindowCoordinator 초기화
            windowCoordinator = WindowCoordinator(appStateManager: appStateManager)
        }
        .onChange(of: appStateManager.appState) { oldState, newState in
            Task { @MainActor in
                await windowCoordinator?.handleStateChange(
                    from: oldState,
                    to: newState,
                    openWindow: { id in openWindow(id: id) },
                    dismissWindow: { id in dismissWindow(id: id) },
                    dismissImmersiveSpace: { await dismissImmersiveSpace() }
                )
            }
        }
    }
}
