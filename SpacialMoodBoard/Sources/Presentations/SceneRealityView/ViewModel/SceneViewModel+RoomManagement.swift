import Foundation
import RealityKit

extension SceneViewModel {

    /// Floor 엔티티를 가져오거나 생성
    /// EntityRepository에 작업을 위임
    func getFloorEntity() -> ModelEntity? {
        let environment = self.spacialEnvironment
        return entityRepository.getOrCreateFloorEntity(from: environment)
    }

    /// 특정 프로젝트의 엔티티 캐시 삭제
    func deleteEntityCache(for project: Project) {
        entityRepository.clearFloorCache()

        if appModel.selectedProject?.id == project.id {
            appModel.selectedProject = nil
        }
    }
}
