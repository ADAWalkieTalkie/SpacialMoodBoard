import SwiftUI
import SwiftData

struct MainWindowContent: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @Bindable var appModel: AppModel
    var assetRepository: AssetRepository
    var projectRepository: ProjectRepository
    var sceneViewModel: SceneViewModel
    var modelContainer: ModelContainer
    
    var body: some View {
        Group {
            if appModel.selectedProject != nil {
                VStack {
                    LibraryView(
                        viewModel: LibraryViewModel(
                            assetRepository: assetRepository
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
                .environment(appModel)
                .modelContainer(modelContainer)
            }
        }
    }
}