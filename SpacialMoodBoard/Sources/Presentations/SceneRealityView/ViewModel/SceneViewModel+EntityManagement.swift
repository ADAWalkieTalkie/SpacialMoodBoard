import Foundation
import RealityKit

// MARK: - SceneObject Entity Management

extension SceneViewModel {
    
    func updateEntities(
        sceneObjects: [SceneObject],
        anchor: Entity
    ) {
        let currentObjectIds = Set(sceneObjects.map { $0.id })
        let existingEntityIds = Set(entityMap.keys)
        
        // 1. 삭제된 객체 제거
        removeDeletedEntities(
            currentIds: currentObjectIds,
            existingIds: existingEntityIds
        )
        
        // 2. 새로운 객체 추가 또는 업데이트
        updateOrCreateEntities(
            sceneObjects: sceneObjects,
            anchor: anchor
        )
    }
    
    // MARK: - Private Helpers
    
    private func removeDeletedEntities(
        currentIds: Set<UUID>,
        existingIds: Set<UUID>
    ) {
        for removedId in existingIds.subtracting(currentIds) {
            if let entity = entityMap[removedId] {
                entity.removeFromParent()
                entityMap.removeValue(forKey: removedId)
            }
        }
    }
    
    private func updateOrCreateEntities(
        sceneObjects: [SceneObject],
        anchor: Entity
    ) {
        for sceneObject in sceneObjects {
            guard let asset = assetRepository.asset(withId: sceneObject.assetId) else { continue }
            
            if let existingEntity = entityMap[sceneObject.id] {
                // 기존 Entity 위치 업데이트
                existingEntity.position = sceneObject.position
            } else {
                // 새로운 Entity 생성
                createAndAddEntity(sceneObject: sceneObject, asset: asset, anchor: anchor)
            }
        }
    }
    
    func createAndAddEntity(
        sceneObject: SceneObject,
        asset: Asset,
        anchor: Entity
    ) {
        let newEntity: ModelEntity?
        switch sceneObject.attributes {
        case .image:
            newEntity = ImageEntity.create(from: sceneObject, with: asset, viewMode: false)
        case .audio:
            newEntity = SoundEntity.create(from: sceneObject, with: asset, viewMode: false)
        }
        if let entity = newEntity {
            anchor.addChild(entity)
            entityMap[sceneObject.id] = entity
        }
    }
}
