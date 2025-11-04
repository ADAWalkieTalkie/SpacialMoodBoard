import Foundation
import RealityKit

// MARK: - SceneObject Entity Management

extension SceneViewModel {

    /// SceneObject 배열과 엔티티를 동기화
    func updateEntities(
        sceneObjects: [SceneObject],
        rootEntity: Entity
    ) {
        // rootEntity 참조 저장 (회전 등의 작업에 사용)
        self.rootEntity = rootEntity

        entityRepository.syncEntities(
            sceneObjects: sceneObjects,
            rootEntity: rootEntity,
            assetRepository: assetRepository
        )
    }

    /// 특정 ID의 엔티티를 가져오기
    func getEntity(for id: UUID) -> ModelEntity? {
        return entityRepository.getEntity(for: id)
    }
    
    /// Floor 엔티티를 가져오거나 생성
    func getFloorEntity() -> ModelEntity? {
        return entityRepository.getOrCreateFloorEntity(floorImageURL: self.floorImageURL)
    }

}
