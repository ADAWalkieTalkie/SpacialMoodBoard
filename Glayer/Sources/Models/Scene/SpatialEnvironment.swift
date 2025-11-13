import Foundation

// MARK: - SpacialEnvironment (SceneRealityView의 배경)
struct SpacialEnvironment: Codable, Equatable {
    var immersiveBackground: URL?

    /// Floor로 사용할 Asset ID (SceneObject와 동일한 참조 방식)
    /// - Note: Floor 이미지 URL은 AssetRepository에서 조회됨 (SceneViewModel.floorImageURL)
    var floorAssetId: String?
    
    var immersiveTime: TimeOfDay?

    init(
        immersiveBackground: URL? = nil,
        floorAssetId: String? = nil,
        immersiveTime: TimeOfDay? = .day
    ) {
        self.immersiveBackground = immersiveBackground
        self.floorAssetId = floorAssetId
        self.immersiveTime = immersiveTime
    }

    // MARK: - Codable
    private enum CodingKeys: String, CodingKey {
        case immersiveBackground
        case floorAssetId
    }
}
