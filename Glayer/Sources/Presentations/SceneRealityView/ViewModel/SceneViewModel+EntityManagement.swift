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
    func getFloorEntity() async -> ModelEntity? {
        return await entityRepository.getOrCreateFloorEntity(floorImageURL: self.floorImageURL)
    }

    /// 경계 벽면 설정
    func setupBoundaryWalls(in rootEntity: Entity) {
        boundaryCollisionManager.setupBoundaryWalls(in: rootEntity)
    }

    /// 엔티티 위치 변경 시 경계면 충돌 확인
    func checkBoundaryCollision(for entity: ModelEntity) {
        boundaryCollisionManager.checkCollision(for: entity)
    }
}
