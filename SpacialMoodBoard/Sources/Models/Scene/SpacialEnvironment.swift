import Foundation

// MARK: - SpacialEnvironment (SceneRealityView의 배경)
struct SpacialEnvironment: Codable, Equatable {
    var roomType: RoomType
    var groundSize: GroundSize
    var immersiveBackground: URL?
    var floorMaterialImageURL: URL?

    // Documents 디렉토리로부터의 상대 경로 (예: "projects/프로젝트명/images/파일명.png")
    var floorImageRelativePath: String?

    init(
        roomType: RoomType,
        groundSize: GroundSize,
        immersiveBackground: URL? = nil,
        floorMaterialImageURL: URL? = nil,
        floorImageRelativePath: String? = nil
    ) {
        self.roomType = roomType
        self.groundSize = groundSize
        self.immersiveBackground = immersiveBackground
        self.floorMaterialImageURL = floorMaterialImageURL
        self.floorImageRelativePath = floorImageRelativePath
    }

    // MARK: - Codable
    // floorMaterialImageURL은 런타임 전용이므로 JSON에 저장하지 않음
    private enum CodingKeys: String, CodingKey {
        case roomType
        case groundSize
        case immersiveBackground
        case floorImageRelativePath
    }
}
