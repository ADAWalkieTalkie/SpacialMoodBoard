import SwiftUI

@MainActor
@Observable
class SceneModel {
    // MARK: - SceneObject 관리
    var sceneObjects: [SceneObject] = []
    
    // MARK: - 사용자 공간 상태
    var userSpatialState = UserSpatialState(userPosition: [0, 0, 0], viewMode: false)

    /// viewMode 토글(향후 삭제 혹은 보기 모드를 구현할때 수정하여 사용 가능)
    func toggleViewMode() {
        userSpatialState.viewMode.toggle()
        print("🔄 ViewMode 변경: \(userSpatialState.viewMode)")
    }
    
    // MARK: - SceneObject 추가
    func addImageObject(from asset: Asset) {
        let sceneObject = SceneObject.createImage(
            assetId: asset.id,
            position: [0, 1.5, -2],
            scale: 1.0,
            billboardable: true
        )
        sceneObjects.append(sceneObject)
    }

    // MARK: - SceneObject 삭제
    func removeSceneObject(id: UUID) {
        sceneObjects.removeAll { $0.id == id }
    }

    // MARK: - SceneObject 위치 업데이트
    func updateObjectPosition(id: UUID, position: SIMD3<Float>) {
        if let index = sceneObjects.firstIndex(where: { $0.id == id }) {
            sceneObjects[index].move(to: position)
            print("📍 Object \(id) 위치 업데이트: \(position)")
        }
    }
}