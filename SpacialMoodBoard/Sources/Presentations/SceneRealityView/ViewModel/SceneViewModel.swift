import Foundation
import RealityKit
import Observation
import SwiftUI

@MainActor
@Observable
final class SceneViewModel {
  
  // MARK: - Dependencies
  
  let appModel: AppModel
  let projectRepository: ProjectRepository?
  let entityBuilder: RoomEntityBuilder
  let opacityAnimator: WallOpacityAnimator
  
  // MARK: - State
  
  // Room Entity 캐시
  var cachedRoomEntities: [UUID: Entity] = [:]
  
  // SceneObject의 RealityKit 내 Entity 맵
  var entityMap: [UUID: ModelEntity] = [:]
  var selectedEntity: ModelEntity?
  
  // SceneObject 데이터
  var sceneObjects: [SceneObject] = []
  
  // 회전 각도 (Volume용)
  var rotationAngle: Float = .pi / 4
  
  // MARK: - Initialization
  
  init(
    appModel: AppModel,
    projectRepository: ProjectRepository? = nil,
    entityBuilder: RoomEntityBuilder = RoomEntityBuilder(),
    opacityAnimator: WallOpacityAnimator = WallOpacityAnimator()
  ) {
    self.appModel = appModel
    self.projectRepository = projectRepository
    self.entityBuilder = entityBuilder
    self.opacityAnimator = opacityAnimator
  }
  
  // MARK: - Project Management
  
  func getActiveProject() -> Project? {
    guard let activeProject = appModel.selectedProject else {
      return nil
    }
    return projectRepository?.fetchProject(activeProject) ?? activeProject
  }
  
  // MARK: - Cleanup
  
  func reset() {
    entityMap.removeAll()
    selectedEntity = nil
    cachedRoomEntities.removeAll()
    opacityAnimator.reset()
    rotationAngle = .pi / 4
  }
}