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
    }
    
    // MARK: - 복제
    
    func duplicateObject() -> SceneObject? {
        guard let selectedEntity = selectedEntity,
              let objectId = UUID(uuidString: selectedEntity.name),
              let originalObject = sceneObjects.first(where: { $0.id == objectId }),
              case .image(let imageAttrs) = originalObject.attributes else {
            return nil
        }
        
        let newPosition = originalObject.position + SIMD3<Float>(-0.1, 0.1, 0)
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
        addSceneObject(duplicatedObject, rootEntity: nil)
        self.selectedEntity = nil
        
        return duplicatedObject
    }
    
    // MARK: - Billboardable 관련
    
    /// Billboardable 상태 조회
    func getBillboardableState(id: UUID) -> Bool {
        guard let object = sceneObjects.first(where: { $0.id == id }),
              case .image(let attrs) = object.attributes else {
            return false
        }
        return attrs.billboardable
    }
    
    /// Billboardable 상태 변경
    func updateBillboardable(id: UUID, billboardable: Bool) {
        // ✅ SceneViewModel+SceneObject의 updateSceneObject 사용
        updateSceneObject(with: id) { object in
            object.setBillboardable(billboardable)
        }
    }
}