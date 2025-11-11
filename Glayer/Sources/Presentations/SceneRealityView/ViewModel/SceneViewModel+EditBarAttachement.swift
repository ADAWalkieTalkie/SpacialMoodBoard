import RealityKit
import SwiftUI

// MARK: - EditBarAttachment

extension SceneViewModel {
    
    // MARK: - Add Attachment
    
    /// Entity에 attachment를 추가하고 타이머 시작
    func addAttachmentAndStartTimer(for entity: ModelEntity, headPosition: SIMD3<Float>) {
        guard let objectId = UUID(uuidString: entity.name),
              let sceneObject = sceneObjects.first(where: { $0.id == objectId })
        else { return }
        
        let objectType = sceneObject.type
        
        // 기존 타이머 취소
        attachmentTimer?.cancel()
        attachmentTimer = nil
        
        // Attachment 추가
        switch objectType {
        case .image:
            addImageEditBarAttachment(to: entity, headPosition: headPosition, objectId: objectId, objectType: objectType)
            
        case .sound:
            addSoundEditBarAttachment(to: entity, headPosition: headPosition, objectId: objectId, objectType: objectType, sceneObject: sceneObject)
            addSoundNameAttachment(to: entity, headPosition: headPosition, sceneObject: sceneObject)
        }
        
        // 타이머 생성 및 시작 (entity를 캡처)
        attachmentTimer = FunctionTimer(duration: 5.0) { [weak self] in
            guard let self else { return }
            
            // 타이머 생성 시점의 entity 사용
            self.removeAttachment(from: entity)
            
            // selectedEntity가 여전히 같은 entity면 nil로 설정
            if self.selectedEntity?.name == entity.name {
                self.selectedEntity = nil
            }
        }
        attachmentTimer?.start()
    }
    
    /// Image Attachment 추가
    private func addImageEditBarAttachment(to entity: ModelEntity, headPosition: SIMD3<Float>, objectId: UUID, objectType: AssetType) {
        addEditBarAttachment(
            to: entity,
            headPosition: headPosition,
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
    private func addSoundEditBarAttachment(to entity: ModelEntity, headPosition: SIMD3<Float>, objectId: UUID, objectType: AssetType, sceneObject: SceneObject) {
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
            headPosition: headPosition,
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
        headPosition: SIMD3<Float>,
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
        
        // 거리 기반 스케일 계산
        let entityWorldPosition = entity.position(relativeTo: nil)
        let distanceBasedScale = EntityAttachmentSizeDeterminator.calculateScale(
            headPosition: headPosition,
            entityPosition: entityWorldPosition
        )
        
        /// attachment 스케일 보정
        let parentScale = entity.scale
        let finalScale = SIMD3<Float>(
            distanceBasedScale / parentScale.x,
            distanceBasedScale / parentScale.y,
            distanceBasedScale / parentScale.z
        )
        objectAttachment.scale = finalScale
        
        entity.addChild(objectAttachment)
        
        // Entity의 크기 계산 (visualBounds 사용)
        let bounds = entity.visualBounds(relativeTo: entity)
        let width  = bounds.extents.x
        let height = bounds.extents.y
        EntityBoundBoxApplier.addBoundAuto(to: entity, width: width, height: height)
        
        // Attachment 위치 설정 (상단)
        AttachmentPositioner.positionAtTop(objectAttachment, relativeTo: entity)
    }
    
    private func addSoundNameAttachment(to entity: ModelEntity, headPosition: SIMD3<Float>, sceneObject: SceneObject) {
        // 1. assetId로 Asset 찾기
        guard let asset = assetRepository.asset(withId: sceneObject.assetId) else {
            print("⚠️ Asset not found for assetId: \(sceneObject.assetId)")
            return
        }
        
        // 2. filename 추출
        let filename = asset.filename
        
        // 3. Attachment Entity 생성
        let nameAttachment = Entity()
        nameAttachment.name = "soundNameAttachment"
        
        // 4. ViewAttachmentComponent 생성
        let attachment = ViewAttachmentComponent(
            rootView: SoundNameAttachment(filename: filename)
        )
        nameAttachment.components.set(attachment)
        nameAttachment.components.set(BillboardComponent())
        
        // 거리 기반 스케일 계산
        let entityWorldPosition = entity.position(relativeTo: nil)
        let distanceBasedScale = EntityAttachmentSizeDeterminator.calculateScale(
            headPosition: headPosition,
            entityPosition: entityWorldPosition
        )
        
        // 부모 엔티티 스케일 보정
        let parentScale = entity.scale
        let finalScale = SIMD3<Float>(
            distanceBasedScale / parentScale.x,
            distanceBasedScale / parentScale.y,
            distanceBasedScale / parentScale.z
        )
        
        nameAttachment.scale = finalScale
        
        // 6. 위치 설정 (아래에 배치)
        entity.addChild(nameAttachment)
        AttachmentPositioner.positionAtBottom(nameAttachment, relativeTo: entity)
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
