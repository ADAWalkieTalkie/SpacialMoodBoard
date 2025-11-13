import Foundation
import RealityKit

// MARK: - Immersive 전용 기능 (SceneObject CRUD)

extension SceneViewModel {
    
    // MARK: - Add Image Object
    
    /// ImageEditor나 Library에서 호출 (anchor는 SceneRealityView에서 전달)
    @discardableResult
    func addImageObject(from asset: Asset, rootEntity: Entity? = nil) throws -> SceneObject {
        guard asset.type == .image else {
            throw NSError(domain: "Scene", code: 1)
        }
        
        // Volume 모드와 Immersive 모드에 따라 다른 초기 위치 설정
        // Volume: window 중앙 (y=0.1m, z=-1.0m) - 1m 크기 volume 내에서 보이도록
        // Immersive: 사용자 눈높이 (y=1.5m, z=-2.0m) - 기존 동작 유지
        let position: SIMD3<Float>
        if appStateManager.appState.isVolumeOpen {
            position = SIMD3<Float>(0, 0.1, 0.1)
        } else {
            position = SIMD3<Float>(0, 0.0, 0.0)
        }

        let newObject = SceneObject.createImage(
            assetId: asset.id,
            position: position,
            isEditable: true,
            scale: 0.3,
            rotation: SIMD3<Float>(0, 0, 0),
            crop: SIMD4<Float>(0, 0, 1, 1),
            billboardable: true
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
            position = SIMD3<Float>(0, 0.1, 0.1)
        } else {
            position = SIMD3<Float>(0, 0, 0)
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
    
    // MARK: - 복제
    
    func duplicateObject(rootEntity: Entity) -> SceneObject? {
        guard let selectedEntity = selectedEntity,
              let objectId = UUID(uuidString: selectedEntity.name),
              let originalObject = sceneObjects.first(where: { $0.id == objectId }),
              case .image(let imageAttrs) = originalObject.attributes else {
            return nil
        }
        
        let newPosition = originalObject.position + SIMD3<Float>(0.2, 0.2, 0.1)
        let duplicatedObject = SceneObject.createImage(
            assetId: originalObject.assetId,
            position: newPosition,
            isEditable: originalObject.isEditable,
            scale: imageAttrs.scale,
            rotation: imageAttrs.rotation,
            crop: imageAttrs.crop,
            billboardable: imageAttrs.billboardable
        )
        
        // SceneViewModel+SceneObject의 addSceneObject 사용
        addSceneObject(duplicatedObject, rootEntity: rootEntity)
        self.selectedEntity = nil
        
        return duplicatedObject
    }
    
    func toggleImmersiveTime() {
        var environment = spacialEnvironment
        environment.immersiveTime = environment.immersiveTime == .day ? .night : .day
        spacialEnvironment = environment

        // TODO: 구현 예정
    }
}
