import Foundation
import RealityKit

// MARK: - SceneObject Operations (Repository 사용)

extension SceneViewModel {
    
    // MARK: - Basic CRUD
    
    /// 객체 추가 + Entity 생성
    func addSceneObject(_ object: SceneObject, anchor: Entity? = nil) {
        guard var scene = appModel.selectedScene else { return }
        
        // 1. Repository를 통해 SceneObject 추가
        sceneObjectRepository.addObject(object, to: &scene)
        appModel.selectedScene = scene
        
        // 2. Entity 생성 및 추가
        if let anchor = anchor,
           let asset = assetRepository.asset(withId: object.assetId) {
            createAndAddEntity(sceneObject: object, asset: asset, anchor: anchor)
        }
        
        // 3. 저장
        saveScene()
    }
    
    /// 객체 위치 업데이트 (제스처용)
    func updateObjectPosition(id: UUID, position: SIMD3<Float>) {
        guard var scene = appModel.selectedScene else { return }
        
        sceneObjectRepository.updateObject(id: id, in: &scene) { object in
            object.move(to: position)
        }
        appModel.selectedScene = scene
        scheduleSceneAutosaveDebounced()
    }
    
    /// 객체 회전 업데이트 (제스처용)
    func updateObjectRotation(id: UUID, rotation: SIMD3<Float>) {
        guard var scene = appModel.selectedScene else { return }
        
        sceneObjectRepository.updateObject(id: id, in: &scene) { object in
            object.setRotation(rotation)
        }
        appModel.selectedScene = scene
        scheduleSceneAutosaveDebounced()
    }
    
    /// 객체 크기 업데이트 (제스처용)
    func updateObjectScale(id: UUID, scale: Float) {
        guard var scene = appModel.selectedScene else { return }
        
        sceneObjectRepository.updateObject(id: id, in: &scene) { object in
            object.setScale(scale)
        }
        appModel.selectedScene = scene
        scheduleSceneAutosaveDebounced()
    }
    
    /// 객체 속성 업데이트 (일반용)
    func updateSceneObject(with id: UUID, _ mutate: (inout SceneObject) -> Void) {
        guard var scene = appModel.selectedScene else { return }
        
        sceneObjectRepository.updateObject(id: id, in: &scene, mutate: mutate)
        appModel.selectedScene = scene
        saveScene()
    }
    
    /// 객체 삭제 + Entity 제거
    func removeSceneObject(id: UUID) {
        guard var scene = appModel.selectedScene else { return }
        
        // 1. Entity 먼저 제거
        if let entity = entityMap[id] {
            entity.removeFromParent()
            entityMap.removeValue(forKey: id)
        }
        
        // 2. Repository를 통해 SceneObject 삭제
        sceneObjectRepository.deleteObject(by: id, from: &scene)
        appModel.selectedScene = scene
        
        // 3. 선택 해제
        selectedEntity = nil
        
        // 4. 저장
        saveScene()
    }
}