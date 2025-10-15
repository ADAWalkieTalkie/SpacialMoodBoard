import SwiftUI

@MainActor
@Observable
class SceneModel {
    // MARK: - SceneObject 관리
    var sceneObjects: [SceneObject] = []
    
    /// 이미지 객체 생성 및 추가
    func addImageObject(from asset: Asset) {
        let sceneObject = SceneObject.createImage(
            assetId: asset.id,
            position: [0, 1.5, -2],
            scale: 1.0,
            billboardable: true
        )
        sceneObjects.append(sceneObject)
    }
}