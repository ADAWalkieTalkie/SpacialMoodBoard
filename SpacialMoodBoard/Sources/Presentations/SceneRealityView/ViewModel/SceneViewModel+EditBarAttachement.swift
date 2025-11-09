import RealityKit
import SwiftUI

// MARK: - EditBarAttachment

extension SceneViewModel {

    // MARK: - Add Attachment

    /// Image Attachment 추가
    func addImageEditBarAttachment(to entity: ModelEntity, objectId: UUID, objectType: AssetType) {
        addEditBarAttachment(
            to: entity,
            objectId: objectId,
            objectType: objectType,
            onDuplicate: { [weak self] in
                guard let self = self, let rootEntity = self.rootEntity else { return }
                _ = self.duplicateObject(rootEntity: rootEntity)
            },
            // onCrop: { [weak self] in
            //     self?.cropObject(id: objectId)
            // },
            onDelete: { [weak self] in
                self?.removeSceneObject(id: objectId)
            }
        )
    }
    
    /// Sound Attachment 추가
    func addSoundEditBarAttachment(to entity: ModelEntity, objectId: UUID, objectType: AssetType, sceneObject: SceneObject) {
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
        
        addEditBarAttachment(
            to: entity,
            objectId: objectId,
            objectType: objectType,
            initialVolume: initVol,
            onVolumeChange: onVolumeChange,
            onDelete: { [weak self] in
                self?.removeSceneObject(id: objectId)
            }
        )
    }

    /// Attachment 추가
    private func addEditBarAttachment(
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
        
        // Entity의 크기 계산 (visualBounds 사용)
        let bounds = entity.visualBounds(relativeTo: entity)
        let width  = bounds.extents.x
        let height = bounds.extents.y
        entityBoundBoxApplier.addBoundAuto(to: entity, width: width, height: height)

        // Attachment 위치 설정 (상단)
        AttachmentPositioner.positionAtTop(objectAttachment, relativeTo: entity)
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