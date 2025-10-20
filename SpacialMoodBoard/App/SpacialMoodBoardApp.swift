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
  @State private var projectRepository: ProjectRepository
  @State private var volumeSceneViewModel: VolumeSceneViewModel
  @State private var immersiveSceneViewModel: ImmersiveSceneViewModel
  init() {
      let repository = InMemoryProjectRepository()
      let appModel = AppModel()
      
      _projectRepository = State(wrappedValue: repository)
      _appModel = State(wrappedValue: appModel)
      _volumeSceneViewModel = State(wrappedValue: VolumeSceneViewModel(
        appModel: appModel,
        projectRepository: repository
      ))
      _immersiveSceneViewModel = State(wrappedValue: ImmersiveSceneViewModel())
    }
  
  var body: some Scene {
    WindowGroup {
      ProjectListView(
        viewModel: ProjectListViewModel(
          appModel: appModel,
          projectRepository: projectRepository
        )
      )
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

