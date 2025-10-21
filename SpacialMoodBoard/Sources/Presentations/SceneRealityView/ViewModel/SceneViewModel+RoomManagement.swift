import Foundation
import RealityKit

extension SceneViewModel {
  
  func getRoomEntity(
    for project: Project?,
    rotationAngle: Float = 0
  ) -> Entity? {
    guard let project = project else {
      return nil
    }
    
    // 캐싱된 Entity 확인
    if let cached = cachedRoomEntities[project.id] {
      return cached
    }
    
    // SpacialEnvironment 가져오기
    guard let environment = getSpacialEnvironment(from: project) else {
#if DEBUG
      print("[SceneVM] getRoomEntity - ⚠️ SpacialEnvironment not found")
#endif
      return nil
    }
    
    // Room 생성
    let room = entityBuilder.buildRoomEntity(from: environment, rotationAngle: rotationAngle)
    cachedRoomEntities[project.id] = room
    
    return room
  }
  
  func deleteEntityCache(for project: Project) {
    opacityAnimator.reset()
    cachedRoomEntities.removeValue(forKey: project.id)
    
    if appModel.selectedProject?.id == project.id {
      appModel.selectedProject = nil
      rotationAngle = .pi / 4
    }
  }
  
  // MARK: - Private Helpers
  
  private func getSpacialEnvironment(from project: Project) -> SpacialEnvironment? {
    // TODO: 실제 구조에 맞게 구현
    // 예시: project.volumeScene?.spacialEnvironment
    return nil
  }
}