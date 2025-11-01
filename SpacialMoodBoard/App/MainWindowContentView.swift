import SwiftUI
import SwiftData

struct MainWindowContent: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow

    @Bindable var appModel: AppStateManager
    var assetRepository: AssetRepository
    var projectRepository: ProjectServiceInterface
    var renameAssetUseCase: RenameAssetUseCase
    var deleteAssetUseCase: DeleteAssetUseCase
    var sceneViewModel: SceneViewModel
    var modelContainer: ModelContainer

    // WindowCoordinator for centralized window management
    @State private var windowCoordinator: WindowCoordinator?

    var body: some View {
        Group {
            if appModel.appState.selectedProject != nil {
                VStack {
                    LibraryView(
                        viewModel: LibraryViewModel(
                            appModel: appModel,
                            assetRepository: assetRepository,
                            renameAssetUseCase: renameAssetUseCase,
                            deleteAssetUseCase: deleteAssetUseCase,
                        ),
                        sceneViewModel: sceneViewModel
                    )
                }
                .environment(appModel)
                .task {
                    await assetRepository.switchProject(
                        to: appModel.appState.selectedProject?.title ?? ""
                    )
                }
                .onChange(of: appModel.appState.selectedProject?.title) { oldTitle, newTitle in
                    Task {
                        await assetRepository.switchProject(to: newTitle ?? "")
                    }
                }
            } else {
                ProjectListView(
                    viewModel: ProjectListViewModel(
                        appModel: appModel,
                        projectRepository: projectRepository
                    )
                )
                .modelContainer(modelContainer)
            }
        }
        // MARK: - Centralized Window Management (WindowCoordinator)
        .onAppear {
            // WindowCoordinator 초기화
            windowCoordinator = WindowCoordinator(appModel: appModel)
        }
        .onChange(of: appModel.appState) { oldState, newState in
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
                if appModel.appState.isImmersiveOpen {
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
