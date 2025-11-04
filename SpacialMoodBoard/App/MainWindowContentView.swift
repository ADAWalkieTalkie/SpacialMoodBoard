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
        .onDisappear {
            Task { @MainActor in
                // 앱 종료 시 모든 창 닫기
                // Case 2: Immersive 상태에서 LibraryView 창 종료 시 Immersive도 함께 닫기
                if appStateManager.appState.isImmersiveOpen {
                    await dismissImmersiveSpace()
                }
                dismissWindow(id: "ImmersiveVolumeWindow")
                // Immersive space가 완전히 닫힐 때까지 잠깐 대기
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                exit(0)
            }
        }
    }
}
