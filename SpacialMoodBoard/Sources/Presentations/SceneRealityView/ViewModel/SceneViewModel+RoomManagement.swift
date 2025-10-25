import Foundation
import RealityKit

extension SceneViewModel {
  
    func getRoomEntity(
        for project: Project?,
        rotationAngle: Float = 0
    ) -> Entity? {
        guard let project = project else {
            print("❌ Project not found")
            return nil
        }
    
        // 캐싱된 Entity 확인
        if let cached = roomEntities[project.id] {
            return cached
        }
    
        // SpacialEnvironment 가져오기
        let environment = self.spacialEnvironment
    
        // Room 생성
        let room = entityBuilder.buildRoomEntity(from: environment, rotationAngle: rotationAngle)
        roomEntities[project.id] = room
    
        return room
    }
  
    func deleteEntityCache(for project: Project) {
        roomEntities.removeValue(forKey: project.id)

        if appModel.selectedProject?.id == project.id {
            appModel.selectedProject = nil
            rotationAngle = .pi / 4
        }
    }
}