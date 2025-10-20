import Foundation

struct SceneModel: Codable, Equatable {
  var id: UUID
  var SpacialEnvironment: SpacialEnvironment
  var UserSpatialState: UserSpatialState
  var SceneObjects: [SceneObject]

  init(
    id: UUID = UUID(),
    SpacialEnvironment: SpacialEnvironment,
    UserSpatialState: UserSpatialState,
    SceneObjects: [SceneObject]
  ) {
    self.id = id
    self.SpacialEnvironment = SpacialEnvironment
    self.UserSpatialState = UserSpatialState
    self.SceneObjects = SceneObjects
  }
}