//
//  DeleteAssetUseCase.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/29/25.
//

import Foundation

/// 씬의 런타임/상태로 얇게 접근하는 포트(뷰모델이 채택)
protocol SceneRuntimeSink: AnyObject {
    func currentSceneObjects() -> [SceneObject]
    func replaceSceneObjects(with newObjects: [SceneObject])
    func cleanupRuntime(for removed: [SceneObject], maybeResetFloorIfMatches assetId: String)
}

struct DeleteAssetUseCase {
    let assetRepository: AssetRepositoryInterface
    let sceneRepository: SceneRepositoryInterface
    
    /// 에셋 삭제 + 씬 모델/런타임 연쇄 정리
    /// - Parameters:
    ///   - assetId: 삭제할 에셋 식별자
    ///   - runtimeSink: 현재 씬 상태/런타임에 접근하는 얇은 포트
    func execute(assetId: String, runtimeSink: SceneRuntimeSink) throws {
        let before = runtimeSink.currentSceneObjects()
        
        _ = try? assetRepository.deleteAsset(id: assetId)
        
        var objects = before
        let removedIDs: [UUID] = sceneRepository.removeAllReferencing(from: &objects, assetId: assetId)
        let removedObjects: [SceneObject] = before.filter { removedIDs.contains($0.id) }
        
        runtimeSink.replaceSceneObjects(with: objects)
        runtimeSink.cleanupRuntime(for: removedObjects, maybeResetFloorIfMatches: assetId)
    }
}
