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

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environment(appModel)
        }

        WindowGroup(id: "dummy") {
            DummyView()
                .environment(appModel)
                .environment(sceneModel)
        }

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
