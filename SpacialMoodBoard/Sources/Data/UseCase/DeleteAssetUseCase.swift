//
//  DeleteAssetUseCase.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/29/25.
//

import Foundation

struct DeleteAssetResult {
    /// 씬에서 실제로 제거된 SceneObject 스냅샷(엔티티 정리/로깅용)
    let removedSceneObjects: [SceneObject]
    /// 삭제된 에셋 ID
    let deletedAssetId: String
}

struct DeleteAssetUseCase {
    let assetRepository: AssetRepositoryInterface
    let sceneObjectRepository: SceneObjectRepositoryInterface

    /// 에셋 삭제 + 씬 참조 일괄 제거
    /// - Parameters:
    ///   - assetId: 삭제할 에셋 식별자
    ///   - scene: 현재 씬 모델(`inout`으로 전달되어 내부 컬렉션이 수정됨)
    /// - Returns: 삭제된 `SceneObject` 목록과 삭제된 에셋 ID
    ///
    /// - Note:
    ///   1) `assetRepository.deleteAsset(id:)`가 디스크/캐시에서 에셋을 제거
    ///   2) `sceneObjectRepository.removeAllReferencing(...)`가 동일 `assetId`를 참조하던
    ///      모든 `SceneObject`를 배열과 인덱스에서 **동시에** 제거
    ///   3) 별도의 for-루프/수동 인덱스 조작이 없다(불일치 방지)
    @MainActor
    func execute(assetId: String, scene: inout SceneModel) throws -> DeleteAssetResult {
        let removed = sceneObjectRepository.removeAllReferencing(from: &scene, assetId: assetId)
        try assetRepository.deleteAsset(id: assetId)

        return DeleteAssetResult(
            removedSceneObjects: removed,
            deletedAssetId: assetId
        )
    }
}
