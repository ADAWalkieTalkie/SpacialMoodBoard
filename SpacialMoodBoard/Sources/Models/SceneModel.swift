import SwiftUI

@MainActor
@Observable
class SceneModel {
    private let sceneObjectStorage = SceneObjectFileStorage()
    
    // MARK: - SceneObject 관리
    var sceneObjects: [SceneObject] = [] {
        didSet {
            saveSceneObjects()  // 변경될 때마다 자동 저장!
        }
    }

    init() {
        loadSceneObjects()
    }   

    var currentProject: Project?

    // MARK: - 프로젝트 로드
    func loadProject(_ project: Project) {
        currentProject = project
        loadSceneObjects()
        print("🎬 프로젝트 로드: \(project.title)")
    }    

    // MARK: - 사용자 공간 상태
    var userSpatialState = UserSpatialState(userPosition: [0, 0, 0], viewMode: false)

    /// viewMode 토글(향후 삭제 혹은 보기 모드를 구현할때 수정하여 사용 가능)
    func toggleViewMode() {
        userSpatialState.viewMode.toggle()
        print("🔄 ViewMode 변경: \(userSpatialState.viewMode)")
    }
    
    // MARK: - SceneObject 관련 로직
    /// 이미지 객체 추가
    func addImageObject(from asset: Asset) {
        let sceneObject = SceneObject.createImage(
            assetId: asset.id,
            position: [0, 1.5, -2],
            scale: 1.0,
            billboardable: true
        )
        sceneObjects.append(sceneObject)
    }

    /// SceneObject 삭제
    func removeSceneObject(id: UUID) {
        sceneObjects.removeAll { $0.id == id }
    }

    /// SceneObject 위치 업데이트
    func updateObjectPosition(id: UUID, position: SIMD3<Float>) {
        if let index = sceneObjects.firstIndex(where: { $0.id == id }) {
            sceneObjects[index].move(to: position)
            print("📍 Object \(id) 위치 업데이트: \(position)")
        }
    }

    // MARK: - 파일 저장/로드
    private func saveSceneObjects() {
        do {
            try sceneObjectStorage.save(sceneObjects, projectName: currentProject?.title ?? "")
        } catch {
            print("❌ 저장 실패: \(error)")
        }
    }

    private func loadSceneObjects() {
        do {
            sceneObjects = try sceneObjectStorage.load(projectName: currentProject?.title ?? "")
        } catch {
            print("❌ 로드 실패: \(error)")
            sceneObjects = []
        }
    }
}