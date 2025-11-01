//
//  CreateObjectUseCase.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 11/1/25.
//

import Foundation
import RealityKit

enum CreateObjectError: Error {
    /// 참조하려는 에셋을 찾을 수 없음
    case assetNotFound
    /// RealityKit 엔티티 생성 실패
    case entityCreationFailed
}

struct CreateObjectResult {
    /// 생성된 SceneObject
    let createdObject: SceneObject

    /// 생성된 RealityKit Entity
    let createdEntity: ModelEntity
}

struct CreateObjectUseCase {
    let assetRepository: AssetRepositoryInterface
    let sceneObjectRepository: SceneObjectRepositoryInterface
    let entityRepository: EntityRepositoryInterface

    /// SceneObject를 씬에 추가하고 대응되는 RealityKit 엔티티를 생성합니다.
    /// - Parameters:
    ///   - object: 추가할 `SceneObject`
    ///   - rootEntity: 엔티티를 추가할 부모 Entity
    ///   - scene: 현재 씬 모델(`inout`으로 전달되어 내부 컬렉션이 수정됨)
    /// - Returns: 생성된 `SceneObject`와 `ModelEntity`를 포함한 결과
    /// - Throws:
    ///   - `CreateObjectError.assetNotFound`: 참조된 Asset이 존재하지 않음
    ///   - `CreateObjectError.entityCreationFailed`: Entity 생성 실패
    ///
    /// - Note:
    ///   1) `assetRepository.asset(withId:)`로 에셋을 조회
    ///   2) `sceneObjectRepository.addObject(_:to:)`로 SceneObject를 씬에 추가
    ///   3) `entityRepository.createEntity(from:asset:rootEntity:)`로 RealityKit 엔티티 생성
    ///   4) SceneObject와 Entity는 동일한 UUID로 연결됨
    @MainActor
    func execute(object: SceneObject, rootEntity: Entity, scene: inout SceneModel) throws -> CreateObjectResult {
        // 1. Asset 조회
        guard let asset = assetRepository.asset(withId: object.assetId) else {
            throw CreateObjectError.assetNotFound
        }

        // 2. SceneObject를 씬에 추가
        sceneObjectRepository.addObject(object, to: &scene)

        // 3. Entity 생성
        guard let entity = entityRepository.createEntity(
            from: object,
            asset: asset,
            rootEntity: rootEntity
        ) else {
            throw CreateObjectError.entityCreationFailed
        }

        return CreateObjectResult(
            createdObject: object,
            createdEntity: entity
        )
    }
}
