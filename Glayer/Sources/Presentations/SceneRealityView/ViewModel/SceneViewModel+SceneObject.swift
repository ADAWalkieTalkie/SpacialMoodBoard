import Foundation
import RealityKit

// MARK: - SceneObject Operations (Repository 사용)

extension SceneViewModel {
    
    // MARK: - Basic CRUD
    
    /// 씬(Scene) 데이터와 3D 엔티티(Entity)를 씬에 추가합니다.
    ///
    /// 이 메서드는 `SceneObject` (데이터 모델)를 현재 씬에 추가하는 것을 기본으로 합니다.
    /// 추가적으로 `rootEntity` 매개변수의 제공 여부에 따라 3D 씬의 `Entity` (시각적 표현)를
    /// 즉시 생성할지, 아니면 나중에 동기화하도록 연기할지 결정합니다.
    ///
    /// - Parameters:
    ///   - object: 씬에 추가할 `SceneObject` 데이터 모델입니다.
    ///   - rootEntity: (선택 사항) `Entity`를 즉시 생성할 경우, 그 부모가 될 RealityKit 엔티티입니다.
    ///                 이 값이 `nil`이면 `SceneObject` 데이터만 씬에 추가되며, `Entity` 생성은 나중에 동기화됩니다.
    func addSceneObject(_ object: SceneObject, rootEntity: Entity? = nil) {
        guard var scene = appStateManager.selectedScene else { return }
        
        // rootEntity가 제공된 경우 UseCase를 통해 객체 생성
        if let rootEntity = rootEntity {
            do {
                _ = try createObjectUseCase.execute(
                    object: object,
                    rootEntity: rootEntity,
                    scene: &scene
                )
                appStateManager.selectedScene = scene
            } catch CreateObjectError.assetNotFound {
#if DEBUG
                print("❌ SceneObject 생성 실패: 에셋을 찾을 수 없음 (assetId: \(object.assetId))")
#endif
            } catch CreateObjectError.entityCreationFailed {
#if DEBUG
                print("❌ Entity 생성 실패 (objectId: \(object.id))")
#endif
            } catch {
#if DEBUG
                print("❌ SceneObject 생성 실패: \(error)")
#endif
            }
        } else {
            // rootEntity가 없는 경우 SceneObject만 추가 (Entity는 나중에 동기화)
            sceneObjectRepository.addObject(object, to: &scene)
            appStateManager.selectedScene = scene
        }
        
        // 저장
        saveScene()
    }
    
    /// 객체 위치 업데이트 (제스처용)
    func updateObjectPosition(id: UUID, position: SIMD3<Float>) {
        guard var scene = appStateManager.selectedScene else { return }
        
        sceneObjectRepository.updateObject(id: id, in: &scene) { object in
            object.move(to: position)
        }
        appStateManager.selectedScene = scene
        scheduleSceneAutosaveDebounced()
    }
    
    /// 객체 회전 업데이트 (제스처용)
    func updateObjectRotation(id: UUID, rotation: SIMD3<Float>) {
        guard var scene = appStateManager.selectedScene else { return }
        
        sceneObjectRepository.updateObject(id: id, in: &scene) { object in
            object.setRotation(rotation)
        }
        appStateManager.selectedScene = scene
        scheduleSceneAutosaveDebounced()
    }
    
    /// 객체 크기 업데이트 (제스처용)
    func updateObjectScale(id: UUID, scale: Float) {
        guard var scene = appStateManager.selectedScene else { return }
        
        sceneObjectRepository.updateObject(id: id, in: &scene) { object in
            object.setScale(scale)
        }
        appStateManager.selectedScene = scene
        scheduleSceneAutosaveDebounced()
    }
    
    /// 객체 속성 업데이트 (일반용)
    func updateSceneObject(with id: UUID, _ mutate: (inout SceneObject) -> Void) {
        guard var scene = appStateManager.selectedScene else { return }
        
        sceneObjectRepository.updateObject(id: id, in: &scene, mutate: mutate)
        appStateManager.selectedScene = scene
        saveScene()
    }
    
    /// 객체 삭제 + Entity 제거
    func removeSceneObject(id: UUID) {
        guard var scene = appStateManager.selectedScene else { return }

        // 1. EntityRepository를 통해 엔티티 제거
        entityRepository.removeEntity(id: id)

        // 2. Repository를 통해 SceneObject 삭제
        sceneObjectRepository.deleteObject(by: id, from: &scene)
        appStateManager.selectedScene = scene

        // 3. 선택 해제
        selectedEntity = nil
        
        // 4. 저장
        saveScene()
    }
}
