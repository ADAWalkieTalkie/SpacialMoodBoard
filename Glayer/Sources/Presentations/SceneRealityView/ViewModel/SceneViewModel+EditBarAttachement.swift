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
            onLock: { [weak self] in
                guard let self = self else { return }
                self.lockObject(id: objectId)
            },
            onDuplicate: { [weak self] in
                guard let self = self, let rootEntity = self.rootEntity else { return }
                _ = self.duplicateObject(rootEntity: rootEntity)
            },
            onCrop: { [weak self] isOn in
                guard let self else { return }
                if isOn {
                    self.startImageCrop(for: entity, objectId: objectId)
                } else {
                    self.removeCropAttachment(from: entity)
                }
            },
            onDelete: { [weak self] in
                self?.removeSceneObject(id: objectId)
            }
        )
    }
    
    /// Sound Attachment 추가
    private func addSoundEditBarAttachment(to entity: ModelEntity, headPosition: SIMD3<Float>, objectId: UUID, objectType: AssetType, sceneObject: SceneObject) {
        let initVol: Double = sceneObject.audioVolumeOrDefault
        
        let onVolumeChanging: (Double) -> Void = { newValue in
            let clamped = max(0.0, min(newValue, 1.0))
            let db: Float = Float(self.linearToDecibels(clamped))
            SceneAudioCoordinator.shared.setGain(Audio.Decibel(db), for: objectId)
            if clamped == 0 {
                SceneAudioCoordinator.shared.pause(objectId)
            } else {
                SceneAudioCoordinator.shared.play(objectId)
            }
        }

        let onVolumeChange: (Double) -> Void = { [weak self] newValue in
            guard let self else { return }
            self.updateSceneObject(with: objectId) { obj in
                obj.setVolume(Float(newValue))
            }
            self.scheduleSceneAutosaveDebounced()
        }
        
        addEditBarAttachment(
            to: entity,
            headPosition: headPosition,
            objectId: objectId,
            objectType: objectType,
            initialVolume: initVol,
            onVolumeChanging: onVolumeChanging,
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
        onVolumeChanging: ((Double) -> Void)? = nil,
        onVolumeChange: ((Double) -> Void)? = nil,
        onLock: (() -> Void)? = nil,
        onDuplicate: (() -> Void)? = nil,
        onCrop: ((Bool) -> Void)? = nil,
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
                onVolumeChanging: onVolumeChanging,
                onVolumeChange: onVolumeChange,
                onLock: onLock,
                onDuplicate: onDuplicate,
                onCrop: onCrop,
                onDelete: onDelete
            )
        )
        objectAttachment.components.set(attachment)

        EntityBoundBoxApplier.addBoundAuto(to: entity)

        /// attachment 스케일 보정
        let finalScale = EntityAttachmentSizeDeterminator.calculateFinalScale(
            headPosition: headPosition,
            entity: entity,
            isVolumeMode: appStateManager.appState.isVolumeOpen
        )

        objectAttachment.scale = finalScale
        entity.addChild(objectAttachment)
        applyEditBarRotation(to: objectAttachment)

        // Attachment 위치 설정 (상단)
        AttachmentPositioner.positionAtTop(objectAttachment, relativeTo: entity, isVolumeMode: appStateManager.appState.isVolumeOpen)
    }

    /// EditBarAttachment 회전 적용(향후 빌보드 관련 에러 수정시 제거 후 BillboardComponent 적용)
    func applyEditBarRotation(to attachment: Entity) {
        // Floor 회전 상쇄용 회전 rotation
        let counterRotation = createVolumeCounterRotation()
        // Attachment 부모 회전 가져오기
        let parentRotation = attachment.parent?.transform.rotation ?? simd_quatf(real: 1.0, imag: SIMD3<Float>(0, 0, 0))
        
        if appStateManager.appState.isVolumeOpen {
            attachment.transform.rotation = parentRotation.inverse * counterRotation
        }else{
            attachment.transform.rotation = parentRotation.inverse * counterRotation
        }
    }
    /// Volume 회전 상쇄용 회전 생성
    private func createVolumeCounterRotation() -> simd_quatf {
        let counterRotationAngle = -rotationAngle
         return simd_quatf(angle: counterRotationAngle, axis: [0, 1, 0])
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

        /// attachment 스케일 보정
        let finalScale = EntityAttachmentSizeDeterminator.calculateFinalScale(
            headPosition: headPosition,
            entity: entity,
            isVolumeMode: appStateManager.appState.isVolumeOpen
        )
        
        nameAttachment.scale = finalScale
        
        // 6. 위치 설정 (아래에 배치)
        entity.addChild(nameAttachment)
        AttachmentPositioner.positionAtBottom(nameAttachment, relativeTo: entity)
    }

    /// Lock Icon Entity 생성 헬퍼 함수
    private func createLockIconEntity(objectId: UUID, zPosition: Float) -> Entity {
        let lockIcon = Entity()
        
        let attachment = ViewAttachmentComponent(
            rootView: LockIconAttachment(
                onUnlock: { [weak self] in
                    guard let self = self else { return }
                    self.unlockObject(id: objectId)
                }
            )
        )
        
        lockIcon.components.set(attachment)
        lockIcon.position = SIMD3<Float>(0, 0, zPosition)
        
        return lockIcon
    }

    /// Lock 아이콘 Attachment 추가 (앞면과 뒷면 모두)
    func addLockIconAttachment(to entity: ModelEntity) {
        guard let objectId = UUID(uuidString: entity.name) else { return }

        // 중복 생성 방지
        let hasLockIcon = entity.children.contains { $0.name == "lockIconAttachment" }
        if hasLockIcon { return }

        // 부모 Entity (기존 이름 유지)
        let lockAttachment = Entity()
        lockAttachment.name = "lockIconAttachment"
        
        // 앞면과 뒷면 Lock Icon 생성 및 추가
        lockAttachment.addChild(createLockIconEntity(objectId: objectId, zPosition: 0.001))
        lockAttachment.addChild(createLockIconEntity(objectId: objectId, zPosition: -0.001))
        
        // 스케일 보정
        let headPosition = userSpatialState.sceneHeadAnchor.position
        let finalScale = EntityAttachmentSizeDeterminator.calculateFinalScale(
            headPosition: headPosition,
            entity: entity,
            isVolumeMode: appStateManager.appState.isVolumeOpen
        )
        
        lockAttachment.scale = finalScale
        entity.addChild(lockAttachment)
        
        // 위치 설정
        AttachmentPositioner.positionAtMiddle(lockAttachment, relativeTo: entity)
    }

    /// Lock 아이콘 Attachment 제거
    func removeLockIconAttachment(from entity: ModelEntity) {
        entity.children
            .filter { $0.name == "lockIconAttachment" }
            .forEach { $0.removeFromParent() }
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
