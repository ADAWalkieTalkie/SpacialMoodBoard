import Foundation

// MARK: - SpacialEnvironment (SceneRealityView의 배경)
struct SpacialEnvironment: Codable, Equatable {
    var immersiveBackground: URL?
    var floorMaterialImageURL: URL?

    // Documents 디렉토리로부터의 상대 경로 (예: "projects/프로젝트명/images/파일명.png")
    var floorImageRelativePath: String?

    init(
        immersiveBackground: URL? = nil,
        floorMaterialImageURL: URL? = nil,
        floorImageRelativePath: String? = nil
    ) {
        self.immersiveBackground = immersiveBackground
        self.floorMaterialImageURL = floorMaterialImageURL
        self.floorImageRelativePath = floorImageRelativePath
    }

    // MARK: - Codable
    // floorMaterialImageURL은 런타임 전용이므로 JSON에 저장하지 않음
    private enum CodingKeys: String, CodingKey {
        case immersiveBackground
        case floorImageRelativePath
    }
}
