import SwiftUI
import SwiftData

struct MainWindowContent: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @Bindable var appModel: AppModel
    var assetRepository: AssetRepository
    var projectRepository: ProjectServiceInterface
    var deleteAssetUseCase: DeleteAssetUseCase
    var sceneViewModel: SceneViewModel
    var modelContainer: ModelContainer
    
    var body: some View {
        Group {
            if appModel.selectedProject != nil {
                VStack {
                    LibraryView(
                        viewModel: LibraryViewModel(
                            assetRepository: assetRepository,
                            deleteAssetUseCase: deleteAssetUseCase,
                            runtimeSink: sceneViewModel
                        ),
                        sceneViewModel: sceneViewModel
                    )
                }
                .environment(appModel)
                .task {
                    await assetRepository.switchProject(
                        to: appModel.selectedProject?.title ?? ""
                    )
                }
                .onChange(of: appModel.selectedProject?.title ?? "") { _, newTitle in
                    Task {
                        await assetRepository.switchProject(to: newTitle)
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
        .onDisappear {
            Task { @MainActor in
                // 자신을 제외한 모든 창 닫기
                if appModel.immersiveSpaceState == .open {
                    await dismissImmersiveSpace()
                }
                dismissWindow(id: "ImmersiveVolumeWindow")
                exit(0)
            }
        }
    }
}
