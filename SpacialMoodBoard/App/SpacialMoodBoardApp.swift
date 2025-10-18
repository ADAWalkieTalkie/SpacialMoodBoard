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
  @State private var projectListViewModel = ProjectListViewModel()
  @State private var volumeSceneViewModel = VolumeSceneViewModel()
  @State private var sceneModel = SceneModel()
  
  var body: some Scene {
    WindowGroup {
      ProjectListView()
        .environment(volumeSceneViewModel)
        .environment(projectListViewModel)
    }
    
    WindowGroup(id: VolumeSceneViewModel.volumeWindowID) {
      VolumeSceneView()
        .environment(volumeSceneViewModel)
        .environment(projectListViewModel)
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

