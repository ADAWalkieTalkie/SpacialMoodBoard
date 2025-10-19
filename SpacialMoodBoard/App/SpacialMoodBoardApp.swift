//
//  SpacialMoodBoardApp.swift
//  SpacialMoodBoard
//
//  Created by apple on 10/2/25.
//

import SwiftUI

@main
struct SpacialMoodBoardApp: App {
  @State private var appModel = AppModel()
  @State private var sceneModel = SceneModel()
  @State private var sceneState = AppSceneState()
  @State private var projectRepository: ProjectRepository
  @State private var volumeSceneViewModel: VolumeSceneViewModel
  
  init() {
      let repository = InMemoryProjectRepository()
      let state = AppSceneState()
      
      _projectRepository = State(wrappedValue: repository)
      _sceneState = State(wrappedValue: state)
      _volumeSceneViewModel = State(wrappedValue: VolumeSceneViewModel(
        sceneState: state,
        projectRepository: repository
      ))
    }
  
  var body: some Scene {
    WindowGroup {
      ProjectListView(
        viewModel: ProjectListViewModel(
          sceneState: sceneState,
          projectRepository: projectRepository
        )
      )
    }
    
    WindowGroup(id: AppSceneState.volumeWindowID) {
      VolumeSceneView(
        viewModel: volumeSceneViewModel
      )
    }
    .windowStyle(.volumetric)
    
    ImmersiveSpace(id: appModel.immersiveSpaceID) {
      ImmersiveView()
        .environment(appModel)
        .environment(sceneModel)
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

