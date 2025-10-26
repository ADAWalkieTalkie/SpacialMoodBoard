import Foundation

// MARK: - SpacialEnvironment (SceneRealityView의 배경)
struct SpacialEnvironment: Codable, Equatable {
    var roomType: RoomType
    var groundSize: GroundSize
    var immersiveBackground: URL?
    var floorMaterialImageURL: URL?

    init(
        roomType: RoomType,
        groundSize: GroundSize,
        immersiveBackground: URL? = nil,
        floorMaterialImageURL: URL? = nil
    ) {
        self.roomType = roomType
        self.groundSize = groundSize
        self.immersiveBackground = immersiveBackground
        self.floorMaterialImageURL = floorMaterialImageURL
    }
}
