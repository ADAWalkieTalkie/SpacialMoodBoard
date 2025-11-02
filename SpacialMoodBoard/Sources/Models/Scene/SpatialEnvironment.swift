import Foundation

// MARK: - SpacialEnvironment (SceneRealityView의 배경)
struct SpacialEnvironment: Codable, Equatable {
    var immersiveBackground: URL?

    /// Floor로 사용할 Asset ID (SceneObject와 동일한 참조 방식)
    var floorAssetId: String?

    /// 런타임 전용: Floor 이미지 URL (JSON에 저장하지 않음)
    var floorMaterialImageURL: URL?

    init(
        immersiveBackground: URL? = nil,
        floorAssetId: String? = nil,
        floorMaterialImageURL: URL? = nil
    ) {
        self.immersiveBackground = immersiveBackground
        self.floorAssetId = floorAssetId
        self.floorMaterialImageURL = floorMaterialImageURL
    }

    // MARK: - Codable
    // floorMaterialImageURL은 런타임 전용이므로 JSON에 저장하지 않음
    private enum CodingKeys: String, CodingKey {
        case immersiveBackground
        case floorAssetId
    }
}
