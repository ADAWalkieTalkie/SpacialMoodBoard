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

    /// 특정 프로젝트의 엔티티 캐시 삭제
//    func deleteEntityCache(for project: Project) {
//        entityRepository.clearFloorCache()
//
//        if appStateManager.selectedProject?.id == project.id {
//            appStateManager.selectedProject = nil
//        }
//    }

    /// 특정 ID의 엔티티를 가져오기
    func getEntity(for id: UUID) -> ModelEntity? {
        return entityRepository.getEntity(for: id)
    }
    
    /// Floor 엔티티를 가져오거나 생성
    /// EntityRepository에 작업을 위임
    func getFloorEntity() -> ModelEntity? {
        let environment = self.spacialEnvironment
        return entityRepository.getOrCreateFloorEntity(from: environment)
    }

}
