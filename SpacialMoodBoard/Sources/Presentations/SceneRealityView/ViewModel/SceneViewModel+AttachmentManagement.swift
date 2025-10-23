import Foundation
import RealityKit
import SwiftUI

// MARK: - Attachment Management

extension SceneViewModel {
  
  func updateAttachment(
    onDuplicate: @escaping () -> Void,
    onCrop: @escaping () -> Void,
    onDelete: @escaping () -> Void
  ) {
    // 기존 attachment 모두 제거
    removeAllAttachments()
    
    // 선택된 Entity에 attachment 추가
    guard let entity = selectedEntity,
          let objectId = UUID(uuidString: entity.name) else {
      return
    }
    
    addAttachment(
      to: entity,
      objectId: objectId,
      onDuplicate: onDuplicate,
      onCrop: onCrop,
      onDelete: onDelete
    )
  }
  
  // MARK: - Private Helpers
  
  private func removeAllAttachments() {
    for entity in entityMap.values {
      entity.children
        .filter { $0.name == "objectAttachment" }
        .forEach { $0.removeFromParent() }
    }
  }
  
  private func addAttachment(
    to entity: ModelEntity,
    objectId: UUID,
    onDuplicate: @escaping () -> Void,
    onCrop: @escaping () -> Void,
    onDelete: @escaping () -> Void
  ) {
    let objectAttachment = Entity()
    objectAttachment.name = "objectAttachment"
    
    // ViewAttachmentComponent 생성
    let attachment = ViewAttachmentComponent(
      rootView: EditBarAttachment(
        objectId: objectId,
        onDuplicate: onDuplicate,
        onCrop: onCrop,
        onDelete: onDelete
      )
    )
    objectAttachment.components.set(attachment)
    entity.addChild(objectAttachment)
    
    // Attachment 위치 설정
    positionAttachment(objectAttachment, relativeTo: entity)
  }
  
  private func positionAttachment(_ attachment: Entity, relativeTo parent: Entity) {
    let objectBounds = parent.visualBounds(relativeTo: parent)
    let attachmentBounds = attachment.visualBounds(relativeTo: attachment)
    
    let yOffset = objectBounds.max.y + attachmentBounds.max.y / 2 + 0.05
    attachment.transform = Transform(translation: SIMD3<Float>(0, yOffset, 0))
  }
}
