import Foundation
import RealityKit
import Observation
import SwiftUI

@MainActor
@Observable
final class SceneViewModel {
    
    // MARK: - Dependencies
    let appModel: AppModel
    let sceneModelFileStorage: SceneModelFileStorage
    let sceneRepository: SceneRepositoryInterface
    let entityBuilder: RoomEntityBuilder
    let opacityAnimator: WallOpacityAnimator
    
    // MARK: - Initialization
    init(appModel: AppModel, sceneRepository: SceneRepositoryInterface) {
        self.appModel = appModel
        self.sceneModelFileStorage = SceneModelFileStorage()
        self.sceneRepository = sceneRepository
        self.entityBuilder = RoomEntityBuilder()
        self.opacityAnimator = WallOpacityAnimator()
    }
    
    
    // MARK: - State
    var selectedSceneModel: SceneModel?
    
    // MARK: - Entity Management
    /// Environment, sceneObjects를 분리해서 관리.
    /// 향후 보기모드에서 Entity에 component를 추가 삭제 하기 편한게 하기 위해서.
    /// Room Entity 캐시
    var roomEntities: [UUID: Entity] = [:]
    /// SceneObject의 RealityKit 내 Entity 맵
    var entityMap: [UUID: ModelEntity] = [:]
    var selectedEntity: ModelEntity?
    
    // 회전 각도 (Volume용)
    var rotationAngle: Float = .pi / 4

    // SceneObjects (computed property)
    var sceneObjects: [SceneObject] {
        get {
            appModel.selectedScene?.sceneObjects ?? []
        }
        set {
            appModel.selectedScene?.sceneObjects = newValue
        }
    }
    
    // UserSpatialState (computed property)
    var userSpatialState: UserSpatialState {
        get {
            appModel.selectedScene?.userSpatialState ?? UserSpatialState()
        }
        set {
            appModel.selectedScene?.userSpatialState = newValue
        }
    }

    // SpacialEnvironment (computed property)
    var spacialEnvironment: SpacialEnvironment {
        get {
            appModel.selectedScene?.spacialEnvironment ?? SpacialEnvironment(
            roomType: .indoor,
            groundSize: .medium
            )
        }
        set {
            appModel.selectedScene?.spacialEnvironment = newValue
        }
    }
    
    
    // MARK: - Cleanup
    
    func reset() {
        entityMap.removeAll()
        selectedEntity = nil
        roomEntities.removeAll()
        opacityAnimator.reset()
        rotationAngle = .pi / 4
    }
}
