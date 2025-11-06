import Foundation
import RealityKit

// MARK: - Immersive 전용 기능 (SceneObject CRUD)

extension SceneViewModel {
    
    // MARK: - Add Image Object
    
    /// ImageEditor나 Library에서 호출 (anchor는 SceneRealityView에서 전달)
    func addImageObject(from asset: Asset, rootEntity: Entity? = nil) {
        let newObject = SceneObject.createImage(
            assetId: asset.id,
            position: SIMD3<Float>(0, 1.5, -2),
            isEditable: true,
            scale: 1.0,
            rotation: SIMD3<Float>(0, 0, 0),
            crop: SIMD4<Float>(0, 0, 1, 1),
            billboardable: true
        )
        
        // SceneViewModel+SceneObject의 addSceneObject 사용
        addSceneObject(newObject, rootEntity: rootEntity)
        SoundFX.shared.play(.assetOnVolume)
    }
    
    // MARK: - Add Sound Object
    
    func addSoundObject(from asset: Asset, rootEntity: Entity? = nil) {
        let soundObj = SceneObject.createAudio(
            assetId: asset.id,
            position: SIMD3<Float>(0, 1.5, -2),
            isEditable: true,
            volume: 1.0
        )
        
        // SceneViewModel+SceneObject의 addSceneObject 사용
        addSceneObject(soundObj, rootEntity: rootEntity)
        SoundFX.shared.play(.assetOnVolume)
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
}
