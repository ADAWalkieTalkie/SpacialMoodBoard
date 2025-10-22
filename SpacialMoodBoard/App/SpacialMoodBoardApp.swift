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
    @State private var volumeSceneViewModel: VolumeSceneViewModel
    @State private var immersiveSceneViewModel: ImmersiveSceneViewModel
    
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
            self.projectRepository = repository
            
            let model = AppModel()
            self.appModel = model
            self.volumeSceneViewModel = VolumeSceneViewModel(
                appModel: model,
                projectRepository: repository
            )
            self.immersiveSceneViewModel = ImmersiveSceneViewModel()
            
        } catch {
            fatalError("❌ Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appModel.selectedProject != nil {
                    LibraryView(
                        viewModel: LibraryViewModel(
                            projectName: appModel.selectedProject?.title ?? ""
                        )
                    )
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
        
        WindowGroup(id: "ImmersiveVolumeWindow") {
            VolumeSceneView(
                viewModel: volumeSceneViewModel
            )
        }
        .windowStyle(.volumetric)
        
        ImmersiveSpace(id: "ImmersiveScene") {
            ImmersiveSceneView(immersiveSceneViewModel: immersiveSceneViewModel)
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
