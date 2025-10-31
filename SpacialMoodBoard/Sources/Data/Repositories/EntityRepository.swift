//
//  EntityRepository.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/31/25.
//

import Foundation
import RealityKit

/// RealityKit 엔티티의 전체 라이프사이클을 관리하는 Repository
/// SceneViewModel의 엔티티 관리 로직을 추상화하여 관심사 분리
@MainActor
final class EntityRepository: EntityRepositoryInterface {

    // MARK: - Properties

    /// SceneObject ID → ModelEntity 매핑 캐시
    private var entityMap: [UUID: ModelEntity] = [:]

    /// Floor 엔티티 캐시 (재사용을 위해)
    private var currentFloorEntity: ModelEntity?

    // MARK: - Entity CRUD

    func createEntity(
        from sceneObject: SceneObject,
        asset: Asset,
        rootEntity: Entity
    ) -> ModelEntity? {
        let newEntity: ModelEntity?

        switch sceneObject.attributes {
        case .image:
            newEntity = ImageEntity.create(from: sceneObject, with: asset)
        case .audio:
            newEntity = SoundEntity.create(from: sceneObject, with: asset)
        }

        if let entity = newEntity {
            rootEntity.addChild(entity)
            entityMap[sceneObject.id] = entity
        }

        return newEntity
    }

    func updateEntityPosition(id: UUID, to position: SIMD3<Float>) {
        guard let entity = entityMap[id] else { return }
        entity.position = position
    }

    func removeEntity(id: UUID) {
        guard let entity = entityMap[id] else { return }
        entity.removeFromParent()
        entityMap.removeValue(forKey: id)
    }

    func getEntity(for id: UUID) -> ModelEntity? {
        return entityMap[id]
    }

    // MARK: - Entity Synchronization

    func syncEntities(
        sceneObjects: [SceneObject],
        rootEntity: Entity,
        assetRepository: AssetRepositoryInterface
    ) {
        let currentObjectIds = Set(sceneObjects.map { $0.id })
        let existingEntityIds = Set(entityMap.keys)

        // 1. 삭제된 객체의 엔티티 제거
        removeDeletedEntities(
            currentIds: currentObjectIds,
            existingIds: existingEntityIds
        )

        // 2. 새로운 객체 추가 또는 기존 객체 업데이트
        updateOrCreateEntities(
            sceneObjects: sceneObjects,
            rootEntity: rootEntity,
            assetRepository: assetRepository
        )
    }

    // MARK: - Floor Entity Management
    func getOrCreateFloorEntity(from environment: SpacialEnvironment) -> ModelEntity? {
        // 캐싱된 Floor 엔티티가 있으면 재사용
        if let currentFloorEntity = currentFloorEntity {
            return currentFloorEntity
        }

        // 없으면 새로 생성 후 캐싱
        let floor = FloorEntity.create(from: environment)
        currentFloorEntity = floor

        return floor
    }

    func clearFloorCache() {
        currentFloorEntity = nil
    }

    // MARK: - Cache Management

    func clearAllCaches() {
        entityMap.removeAll()
        currentFloorEntity = nil
    }

    func getCachedEntities() -> [UUID: ModelEntity] {
        return entityMap
    }

    // MARK: - Private Helpers

    /// 삭제된 SceneObject에 해당하는 엔티티를 제거
    private func removeDeletedEntities(
        currentIds: Set<UUID>,
        existingIds: Set<UUID>
    ) {
        for removedId in existingIds.subtracting(currentIds) {
            removeEntity(id: removedId)
        }
    }

    /// SceneObject 배열을 순회하며 엔티티를 생성하거나 업데이트
    private func updateOrCreateEntities(
        sceneObjects: [SceneObject],
        rootEntity: Entity,
        assetRepository: AssetRepositoryInterface
    ) {
        for sceneObject in sceneObjects {
            guard let asset = assetRepository.asset(withId: sceneObject.assetId) else {
                continue
            }

            if let existingEntity = entityMap[sceneObject.id] {
                // 기존 엔티티의 위치 업데이트
                existingEntity.position = sceneObject.position
            } else {
                // 새로운 엔티티 생성
                _ = createEntity(from: sceneObject, asset: asset, rootEntity: rootEntity)
            }
        }
    }
}
