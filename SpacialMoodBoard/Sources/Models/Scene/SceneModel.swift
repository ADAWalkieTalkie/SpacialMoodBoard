import Foundation

struct SceneModel: Codable, Equatable {
  var projectId: UUID
  var spacialEnvironment: SpacialEnvironment
  var userSpatialState: UserSpatialState
  var sceneObjects: [SceneObject]

  init(
    projectId: UUID,
    spacialEnvironment: SpacialEnvironment,
    userSpatialState: UserSpatialState,
    sceneObjects: [SceneObject]
  ) {
    self.projectId = projectId
    self.spacialEnvironment = spacialEnvironment
    self.userSpatialState = userSpatialState
    self.sceneObjects = sceneObjects
  }
}