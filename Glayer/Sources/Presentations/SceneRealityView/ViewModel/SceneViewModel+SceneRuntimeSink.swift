//
//  SceneViewModel+SceneRuntimeSink.swift
//  Glayer
//
//  Created by jeongminji on 10/29/25.
//

import RealityKit

// SceneViewModel.swift 또는 새 extension에 추가
extension SceneViewModel {
    
    /// Asset 삭제 UseCase 실행 + Entity 정리
    /// - Parameters:
    ///   - useCase: DeleteAssetUseCase
    ///   - assetId: 에셋 id
    func executeDeleteAsset(_ useCase: DeleteAssetUseCase, assetId: String) throws {
        guard var scene = appStateManager.selectedScene else { return }

        let result = try useCase.execute(assetId: assetId, scene: &scene)
        appStateManager.selectScene(scene)

        for object in result.removedSceneObjects {
            // EntityRepository를 통해 엔티티 제거
            entityRepository.removeEntity(id: object.id)
            SceneAudioCoordinator.shared.stop(object.id)
            SceneAudioCoordinator.shared.unregister(entityId: object.id)
        }

        // Floor Asset ID가 삭제된 asset를 참조 중이면 제거 (SceneObject와 동일한 방식)
        if spacialEnvironment.floorAssetId == assetId {
            var env = spacialEnvironment
            env.floorAssetId = nil
            spacialEnvironment = env
            print("✅ Floor 참조 제거: Asset \(assetId) 삭제됨")
        }

        saveScene()
    }
}
