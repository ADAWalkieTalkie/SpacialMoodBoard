import Foundation
import RealityKit

// MARK: - Volume 전용 기능

extension SceneViewModel {
  
  // MARK: - 회전
  
  func rotateBy90Degrees() {
    rotationAngle += .pi / 2

    guard let projectId = appModel.selectedProject?.id,
          let roomEntity = roomEntities[projectId] else {
      return
    }

    applyRotation(to: roomEntity, angle: rotationAngle, animated: true)
  }
  
  func resetRotation() {
    rotationAngle = .pi / 4

    guard let projectId = appModel.selectedProject?.id,
          let roomEntity = roomEntities[projectId] else {
      return
    }

    applyRotation(to: roomEntity, angle: rotationAngle, animated: false)
  }

  // MARK: - 위치 조정
  
  func alignRoomToWindowBottom(
    room: Entity,
    windowHeight: Float = 1.0,
    padding: Float = 0.02
  ) {
    let bounds = room.visualBounds(relativeTo: room)
    let contentMinY = bounds.min.y
    let windowBottomY = -windowHeight / 2.0
    let targetContentMinY = windowBottomY + padding
    let offsetY = targetContentMinY - contentMinY
    
    var transform = room.transform
    transform.translation.y = offsetY
    room.transform = transform
  }
  
  // MARK: - Private Helpers
  
  private func applyRotation(to entity: Entity, angle: Float, animated: Bool) {
    let rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
    
    if animated {
      var transform = entity.transform
      transform.rotation = rotation
      entity.move(to: transform, relativeTo: entity.parent, duration: 0.3)
    } else {
      entity.transform.rotation = rotation
    }
  }
}