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
    @State private var volumeSceneViewModel = VolumeSceneViewModel()

    var body: some Scene {
        WindowGroup {
            ProjectListView()
                .environment(volumeSceneViewModel)
        }

        WindowGroup(id: VolumeSceneViewModel.volumeWindowID) {
            VolumeSceneView()
                .environment(volumeSceneViewModel)
        }
        .windowStyle(.volumetric)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
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
