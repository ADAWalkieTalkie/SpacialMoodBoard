//
//  SceneViewModel+SceneRuntimeSink.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/29/25.
//

import RealityKit

extension SceneViewModel: SceneRuntimeSink {
    func currentSceneObjects() -> [SceneObject] {
        sceneObjects
    }
    
    func replaceSceneObjects(with newObjects: [SceneObject]) {
        sceneObjects = newObjects
    }
    
    func cleanupRuntime(for removed: [SceneObject], maybeResetFloorIfMatches assetId: String) {
        for obj in removed {
            if let e = entityMap[obj.id] {
                e.removeFromParent()
                entityMap[obj.id] = nil
            }
            SceneAudioCoordinator.shared.stop(obj.id)
            SceneAudioCoordinator.shared.unregister(entityId: obj.id)
        }
        spacialEnvironment.floorMaterialImageURL = nil

        scheduleSceneAutosaveDebounced()
    }
}
