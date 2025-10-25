import Foundation
import RealityKit

// MARK: - Immersive 전용 기능 (SceneObject CRUD)

extension SceneViewModel {


  func toggleViewMode() {
      userSpatialState.viewMode.toggle()
  }

  // MARK: - Add Image Object

  func addImageObject(from asset: Asset) {
      let newObject = SceneObject.createImage(
          assetId: asset.id,
          position: SIMD3<Float>(0, 1.5, -2),  // 기본 위치
          isEditable: true,
          scale: 1.0,
          rotation: SIMD3<Float>(0, 0, 0), 
          crop: SIMD4<Float>(0, 0, 1, 1),
          billboardable: true
      )
      
      sceneObjects.append(newObject)
  }
    
    // MARK: - Add Sound Object
    
    func addSoundObject(from asset: Asset) {
        let soundObj = SceneObject.createAudio(
            assetId: asset.id,
            position: SIMD3<Float>(0, 1.5, -2),
            isEditable: true,
            volume: 1.0
        )
        
        sceneObjects.append(soundObj)
        sceneRepository.didAppend(soundObj)
    }
  
  // MARK: - Gesture 관련
  /// 위치 업데이트
  func updateObjectPosition(id: UUID, position: SIMD3<Float>) {
    if let index = sceneObjects.firstIndex(where: { $0.id == id }) {
      sceneObjects[index].move(to: position)
    }
  }

  /// 회전 업데이트
  func updateObjectRotation(id: UUID, rotation: SIMD3<Float>) {
    if let index = sceneObjects.firstIndex(where: { $0.id == id }) {
      sceneObjects[index].setRotation(rotation)
    }
  }

  /// 크기 업데이트
  func updateObjectScale(id: UUID, scale: Float) {
    if let index = sceneObjects.firstIndex(where: { $0.id == id }) {
      sceneObjects[index].setScale(scale)
    }
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
    
    sceneObjects.append(duplicatedObject)
    self.selectedEntity = nil
    
    return duplicatedObject
  }
  
  // MARK: - 삭제
  
  func removeSceneObject(id: UUID) {
    sceneObjects.removeAll { $0.id == id }
    
    if let entity = entityMap[id] {
      entity.removeFromParent()
      entityMap.removeValue(forKey: id)
    }
    
    selectedEntity = nil
  }

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
      if let index = sceneObjects.firstIndex(where: { $0.id == id }) {
          sceneObjects[index].setBillboardable(billboardable)
          print("🔄 Billboardable 변경: \(id) - \(billboardable)")
      }
  }
}
