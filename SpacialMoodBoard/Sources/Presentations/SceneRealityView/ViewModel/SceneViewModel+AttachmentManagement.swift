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
              let objectId = UUID(uuidString: entity.name)
        else { return }
        
        guard let sceneObject = sceneObjects.first(where: { $0.id == objectId }) else { return }
        let objectType = sceneObject.type
        
        switch objectType {
        case .image:
            addAttachment(
                to: entity,
                objectId: objectId,
                objectType: objectType,
                onDuplicate: onDuplicate,
                onCrop: onCrop,
                onDelete: onDelete
            )
            
        case .sound:
            let initVol: Double = sceneObject.audioVolumeOrDefault

            let onVolumeChange: (Double) -> Void = { [weak self] newValue in
                guard let self else { return }
                
                self.updateSceneObject(with: objectId) { obj in
                    obj.setVolume(Float(newValue))
                }
                
                if let ctrl = SceneAudioCoordinator.shared.controller(for: objectId) {
                    ctrl.gain = self.linearToDecibels(newValue)
                    newValue == 0 ? ctrl.pause() : ctrl.play()
                }
                
                self.scheduleSceneAutosaveDebounced()
            }
            
            addAttachment(
                to: entity,
                objectId: objectId,
                objectType: objectType,
                initialVolume: initVol,
                onVolumeChange: onVolumeChange,
                onDelete: onDelete
            )
        }
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
        objectType: AssetType,
        initialVolume: Double? = nil,
        onVolumeChange: ((Double) -> Void)? = nil,
        onDuplicate: (() -> Void)? = nil,
        onCrop: (() -> Void)? = nil,
        onDelete: @escaping () -> Void
    ) {
        let objectAttachment = Entity()
        objectAttachment.name = "objectAttachment"
        
        // ViewAttachmentComponent 생성
        let attachment = ViewAttachmentComponent(
            rootView: EditBarAttachment(
                objectId: objectId,
                objectType: objectType,
                initialVolume: initialVolume ?? 1.0,
                onVolumeChange: onVolumeChange,
                onDuplicate: onDuplicate,
                onCrop: onCrop,
                onDelete: onDelete
            )
        )
        objectAttachment.components.set(attachment)
        objectAttachment.components.set(BillboardComponent())
        
        /// attachment 스케일 유지
        let inverseScale = SIMD3<Float>(
            1.0 / entity.scale.x,
            1.0 / entity.scale.y,
            1.0 / entity.scale.z
        )
        objectAttachment.scale = inverseScale
        
        entity.addChild(objectAttachment)
        
        // Attachment 위치 설정
        topPositionAttachment(objectAttachment, relativeTo: entity)
    }
    
    // 상단 위치로 Attachment 설정(EditBarAttachment 위치)
    private func topPositionAttachment(_ attachment: Entity, relativeTo parent: Entity) {
        let objectBounds = parent.visualBounds(relativeTo: parent)
        let attachmentBounds = attachment.visualBounds(relativeTo: parent)
        
        let yOffset = objectBounds.max.y + attachmentBounds.extents.y / 2 + 0.05
        attachment.position = SIMD3<Float>(0, yOffset, 0)
    }
    
    private func centerPositionAttachment(_ attachment: Entity, relativeTo parent: Entity) {
        attachment.position = SIMD3<Float>(0, 0, 0.1)
    }
    
    // MARK: - dB ↔︎ Linear 변환
    
    func linearToDecibels(_ x: Double) -> RealityKit.Audio.Decibel {
        guard x > 0 else { return -80 }
        return max(20.0 * log10(x), -80.0)
    }
    
    func decibelsToLinear(_ db: RealityKit.Audio.Decibel) -> Double {
        pow(10.0, db / 20.0)
    }
}
