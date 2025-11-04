import Foundation
import RealityKit
import SwiftUI

// MARK: - Attachment Management

extension SceneViewModel {
    
    // Attachment 자동 제거 시간 설정 (초 단위)
    private static let attachmentAutoRemoveDuration: TimeInterval = 5.0
    
    func updateAttachment(
        onDuplicate: @escaping () -> Void,
        onCrop: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        // 기존 타이머 취소
        attachmentTimerTask?.cancel()
        attachmentTimerTask = nil
        
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
                
                let clamped = max(0.0, min(newValue, 1.0))
                let db: Float = Float(self.linearToDecibels(clamped))
                SceneAudioCoordinator.shared.setGain(Audio.Decibel(db), for: objectId)
                
                if newValue == 0 {
                    SceneAudioCoordinator.shared.pause(objectId)
                } else {
                    SceneAudioCoordinator.shared.play(objectId)
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

        // 5초 후 자동 제거 타이머 시작
        startAttachmentAutoRemoveTimer(for: entity, duration: Self.attachmentAutoRemoveDuration)
    }
    
    // MARK: - Private Helpers

    private func removeAllAttachments() {
        for entity in entityRepository.getCachedEntities().values {
            entity.children
                .filter { $0.name == "objectAttachment" }
                .forEach { $0.removeFromParent() }
        }
    }

    // 특정 Entity의 attachment만 제거
    private func removeAttachment(from entity: ModelEntity) {
        entity.children
            .filter { $0.name == "objectAttachment" }
            .forEach { $0.removeFromParent() }
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

    /// 설정된 시간 후 attachment 자동 제거 타이머 시작
    /// - Parameters:
    ///   - entity: Attachment가 있는 Entity
    ///   - duration: 자동 제거까지의 시간 (초 단위)
    private func startAttachmentAutoRemoveTimer(for entity: ModelEntity, duration: TimeInterval) {
        // 기존 타이머 취소
        attachmentTimerTask?.cancel()
        
        // 나노초로 변환
        let nanoseconds = UInt64(duration * 1_000_000_000)
        
        // 새로운 타이머 시작
        attachmentTimerTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: nanoseconds)
            
            // 타이머가 취소되지 않았고 entity가 여전히 존재하는지 확인
            guard !Task.isCancelled,
                  let self = self,
                  entity.parent != nil else {
                return
            }
            
            await MainActor.run {
                // attachment가 여전히 존재하는지 확인 후 제거
                if entity.children.contains(where: { $0.name == "objectAttachment" }) {
                    self.removeAttachment(from: entity)
                }
            }
        }
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
