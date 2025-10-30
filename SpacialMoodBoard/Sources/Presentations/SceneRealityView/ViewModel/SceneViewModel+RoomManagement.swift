import Foundation
import RealityKit

extension SceneViewModel {

    func getFloorEntity() -> ModelEntity? {
        // 캐싱된 Entity 확인
        if let currentFloorEntity = currentFloorEntity {
            return currentFloorEntity
        }

        // SpacialEnvironment 가져오기
        let environment = self.spacialEnvironment

        // Floor 생성
        let floor = FloorEntity.create(from: environment)
        currentFloorEntity = floor

        return floor
    }

    func deleteEntityCache(for project: Project) {
        currentFloorEntity = nil

        if appModel.selectedProject?.id == project.id {
            appModel.selectedProject = nil
        }
    }
}
