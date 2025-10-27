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
        
        addEditBarAttachment(
            to: entity,
            objectId: objectId,
            onDuplicate: onDuplicate,
            onCrop: onCrop,
            onDelete: {
                // EditBar 제거 후 DeleteAttachment 표시
                self.removeAttachment(from: entity, named: "objectAttachment")
                self.addDeleteAttachment(
                    to: entity,
                    objectId: objectId,
                    onDelete: onDelete,
                    onCancel: {
                        // DeleteAttachment 제거 후 EditBar 다시 표시
                        self.removeAttachment(from: entity, named: "deleteAttachment")
                        self.addEditBarAttachment(
                            to: entity,
                            objectId: objectId,
                            onDuplicate: onDuplicate,
                            onCrop: onCrop,
                            onDelete: onDelete // 재귀적 로직
                        )
                    }
                )
            }
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
    
    private func removeAttachment(from entity: ModelEntity, named attachmentName: String) {
        entity.children
            .filter { $0.name == attachmentName }
            .forEach { $0.removeFromParent() }
    }
    
    private func addEditBarAttachment(
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
        topPositionAttachment(objectAttachment, relativeTo: entity)
    }
    
    private func addDeleteAttachment(
        to entity: ModelEntity,
        objectId: UUID,
        onDelete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        let deleteAttachment = Entity()
        deleteAttachment.name = "deleteAttachment"
        
        // Asset 이름 가져오기
        let assetName = sceneObjects.first(where: { $0.id == objectId })?.assetId ?? "Unknown"
        
        // ViewAttachmentComponent 생성
        let attachment = ViewAttachmentComponent(
            rootView: DeleteAttachment(
                assetName: assetName,
                onDelete: onDelete,
                onCancel: onCancel
            )
        )
        deleteAttachment.components.set(attachment)
        entity.addChild(deleteAttachment)
        
        // Attachment 위치 설정 (중앙 앞쪽)
        centerPositionAttachment(deleteAttachment, relativeTo: entity)
    }
    
    // 상단 위치로 Attachment 설정(EditBarAttachment 위치)
    private func topPositionAttachment(_ attachment: Entity, relativeTo parent: Entity) {
        let objectBounds = parent.visualBounds(relativeTo: parent)
        let attachmentBounds = attachment.visualBounds(relativeTo: attachment)
        
        let yOffset = objectBounds.max.y + attachmentBounds.max.y / 2 + 0.05
        attachment.transform = Transform(translation: SIMD3<Float>(0, yOffset, 0))
    }
    
    private func centerPositionAttachment(_ attachment: Entity, relativeTo parent: Entity) {
        // let objectBounds = parent.visualBounds(relativeTo: parent)
        //        let attachmentBounds = attachment.visualBounds(relativeTo: attachment)
        attachment.transform = Transform(translation: SIMD3<Float>(0, 0, 0.1))
    }
}
