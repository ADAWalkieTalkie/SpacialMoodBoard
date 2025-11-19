import Foundation
import RealityKit
import RealityKitContent

// MARK: - Immersive 전용 기능 (SceneObject CRUD)

extension SceneViewModel {

    // MARK: - Private Helpers
    
    /// Immersive 모드에서 headAnchor 기준으로 객체 생성 위치 계산
    /// - Returns: headAnchor 기준 1m 앞, 30cm 아래 위치
    private func immersiveRespawnPosition() -> SIMD3<Float> {
        let headPos = userSpatialState.sceneHeadAnchor.position
        let headRot = simd_quatf(vector: userSpatialState.sceneHeadAnchor.rotation)
        
        // headAnchor의 forward 방향 (z축 음수 방향이 앞, headRot에 의해 월드 좌표계로 계산됨)
        let forward = headRot.act(SIMD3<Float>(0, 0, -2))  // 1m 앞
        let down = SIMD3<Float>(0, -3.3, 0)  // 30cm 아래(좌표계가 0.5아래 이므로 4를 추가로 빼줌 + 사진크기가 약 25cm이므로 1더함)
        
        // 월드 좌표계 위치 계산
        let worldPosition = headPos + forward + down
        
        // rootEntity의 스케일이 8배이므로, 로컬 좌표계로 변환하기 위해 1/8
        let immersiveScale: Float = 8.0
        return worldPosition / immersiveScale
    }
    
    // MARK: - Add Image Object
    
    /// ImageEditor나 Library에서 호출 (anchor는 SceneRealityView에서 전달)
    @discardableResult
    func addImageObject(from asset: Asset, rootEntity: Entity? = nil) throws -> SceneObject {
        guard asset.type == .image else {
            throw NSError(domain: "Scene", code: 1)
        }
        
        // Volume 모드와 Immersive 모드에 따라 다른 초기 위치 설정
        let position: SIMD3<Float>
        if appStateManager.appState.isVolumeOpen {
            position = defaultRespawnPositionVolume
        } else {
            position = immersiveRespawnPosition()
        }

        let newObject = SceneObject.createImage(
            assetId: asset.id,
            position: position,
            isEditable: true,
            scale: 0.3,
            rotation: SIMD3<Float>(0, 0, 0),
            crop: SIMD4<Float>(0, 0, 1, 1),
            lock: false
        )

        // SceneViewModel+SceneObject의 addSceneObject 사용
        addSceneObject(newObject, rootEntity: rootEntity)
        SoundFX.shared.play(.assetOnVolume)
        return newObject
    }
    
    // MARK: - Add Sound Object

    func addSoundObject(from asset: Asset, rootEntity: Entity? = nil) throws -> SceneObject {
        guard asset.type == .sound else {
            throw NSError(domain: "Scene", code: 1)
        }
        
        // Volume 모드와 Immersive 모드에 따라 다른 초기 위치 설정
        let position: SIMD3<Float>
        if appStateManager.appState.isVolumeOpen {
            position = defaultRespawnPositionVolume
        } else {
            position = immersiveRespawnPosition()
        }

        let soundObj = SceneObject.createAudio(
            assetId: asset.id,
            position: position,
            isEditable: true,
            volume: 1.0
        )

        // SceneViewModel+SceneObject의 addSceneObject 사용
        addSceneObject(soundObj, rootEntity: rootEntity)
        SoundFX.shared.play(.assetOnVolume)
        return soundObj
    }

    func lockObject(id: UUID) {
        updateSceneObject(with: id) { obj in
            obj.setLock(true)
        }
        
        // Entity 찾기 및 InputTargetComponent 제거
        guard let entity = getEntity(for: id) else { return }
        entity.components.remove(InputTargetComponent.self)
        
        // lock 아이콘 attachment 추가
        addLockIconAttachment(to: entity)

        selectedEntity = nil
    }

    func unlockObject(id: UUID) {
        updateSceneObject(with: id) { obj in
            obj.setLock(false)
        }
        
        // Entity 찾기 및 InputTargetComponent 복원
        guard let entity = getEntity(for: id) else { return }
        entity.components.set(InputTargetComponent())
        
        // lock 아이콘 attachment 제거
        removeLockIconAttachment(from: entity)

        selectedEntity = entity
    }
    
    // MARK: - 복제
    
    func duplicateObject(rootEntity: Entity) -> SceneObject? {
        guard let selectedEntity = selectedEntity,
              let objectId = UUID(uuidString: selectedEntity.name),
              let originalObject = sceneObjects.first(where: { $0.id == objectId }),
              case .image(let imageAttrs) = originalObject.attributes else {
            return nil
        }
        
        let baseSize: Float = 0.5
        let width = baseSize * imageAttrs.scale

        let offset = width / 3
        let newPosition = originalObject.position + SIMD3<Float>(offset, offset, 0)
        let duplicatedObject = SceneObject.createImage(
            assetId: originalObject.assetId,
            position: newPosition,
            isEditable: originalObject.isEditable,
            scale: imageAttrs.scale,
            rotation: imageAttrs.rotation,
            crop: imageAttrs.crop,
            lock: imageAttrs.lock
        )
        
        // SceneViewModel+SceneObject의 addSceneObject 사용
        addSceneObject(duplicatedObject, rootEntity: rootEntity)
        self.selectedEntity = nil
        
        return duplicatedObject
    }

    // MARK: - Immersive 배경 관리

    /// Immersive 배경을 현재 시간대에 맞게 로드
    /// - Parameter floor: 배경을 추가할 floor Entity
    func loadImmersiveBackground(on floor: Entity) async {
        let immersiveTime = spacialEnvironment.immersiveTime
        let backgroundName = immersiveTime == .day ? "Immersive" : "ImmersiveNight"

        if let immersiveBackground = try? await Entity(named: backgroundName, in: RealityKitContent.realityKitContentBundle) {
            floor.addChild(immersiveBackground)
            currentImmersiveBackground = immersiveBackground
        }
    }

    func toggleImmersiveTime() {
        var environment = spacialEnvironment
        environment.immersiveTime = environment.immersiveTime == .day ? .night : .day
        spacialEnvironment = environment

        // 배경 Entity 교체
        Task { @MainActor in
            // 기존 배경 제거
            guard let oldBackground = currentImmersiveBackground,
                  let floor = oldBackground.parent else {
                return
            }

            oldBackground.removeFromParent()

            // 새로운 배경 로드
            await loadImmersiveBackground(on: floor)
        }
    }
}
