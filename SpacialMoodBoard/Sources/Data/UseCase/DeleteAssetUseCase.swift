//
//  DeleteAssetUseCase.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/29/25.
//

import Foundation

struct DeleteAssetResult {
    let removedSceneObjects: [SceneObject]
    let deletedAssetId: String
}

struct DeleteAssetUseCase {
    let assetRepository: AssetRepositoryInterface
    let sceneRepository: SceneRepositoryInterface
    let sceneObjectRepository: SceneObjectRepositoryInterface
    
    /// 에셋 삭제 + 씬 모델/런타임 연쇄 정리
    /// - Parameters:
    ///   - assetId: 삭제할 에셋 식별자
    ///   - runtimeSink: 현재 씬 상태/런타임에 접근하는 얇은 포트
/// Asset 삭제 + 연관된 SceneObject 삭제
    /// - Parameters:
    ///   - assetId: 삭제할 Asset ID
    ///   - scene: 현재 SceneModel (inout으로 수정됨)
    /// - Returns: 삭제된 SceneObject 목록 (Entity 정리용)
    func execute(assetId: String, scene: inout SceneModel) throws -> DeleteAssetResult {
        // 1. Asset 삭제
        _ = try assetRepository.deleteAsset(id: assetId)
        
        // 2. 해당 Asset을 참조하는 SceneObject 찾기
        let objectsToRemove = sceneObjectRepository.getAllObjects(from: scene)
            .filter { $0.assetId == assetId }
        
        // 3. SceneObject들 삭제 (Repository를 통해)
        for object in objectsToRemove {
            sceneObjectRepository.deleteObject(by: object.id, from: &scene)
        }
        
        print("🗑️ Deleted asset '\(assetId)' and \(objectsToRemove.count) scene objects")
        
        return DeleteAssetResult(
            removedSceneObjects: objectsToRemove,
            deletedAssetId: assetId
        )
    }
    }
