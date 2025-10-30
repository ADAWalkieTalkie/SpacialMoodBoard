import Foundation
import RealityKit

// MARK: - SceneObject Entity Management

extension SceneViewModel {

    /// SceneObject 배열과 엔티티를 동기화
    /// EntityRepository에 작업을 위임
    func updateEntities(
        sceneObjects: [SceneObject],
        rootEntity: Entity
    ) {
        entityRepository.syncEntities(
            sceneObjects: sceneObjects,
            rootEntity: rootEntity,
            assetRepository: assetRepository
        )
    }

    /// 새로운 엔티티를 생성하고 추가
    /// EntityRepository에 작업을 위임
    func createAndAddEntity(
        sceneObject: SceneObject,
        asset: Asset,
        rootEntity: Entity
    ) {
        _ = entityRepository.createEntity(
            from: sceneObject,
            asset: asset,
            rootEntity: rootEntity
        )
    }

    /// 특정 ID의 엔티티를 가져오기
    func getEntity(for id: UUID) -> ModelEntity? {
        return entityRepository.getEntity(for: id)
    }
}
