import Foundation

struct SpacialEnvironment: Identifiable, Codable, Equatable {
  var roomType: RoomType
  var groundSize: GroundSize
  var immersiveBackground: URL?
  var viewMode: Bool

  init(
    roomType: RoomType,
    groundSize: GroundSize,
    viewMode: Bool = false,
    immersiveBackground: URL? = nil,
  ) {
    self.roomType = roomType
    self.groundSize = groundSize
    self.viewMode = viewMode
    self.immersiveBackground = immersiveBackground
  }
}