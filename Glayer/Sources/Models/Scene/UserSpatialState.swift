import Foundation

// MARK: - UserSpatialState (User의 ImmersiveScene 내에서의 위치 및 뷰 모드)
struct UserSpatialState: Codable, Hashable {
    var userPosition: SIMD3<Float> = [0, 0, 0]
    var viewMode: Bool = false
    var paused: Bool = false

    init(userPosition: SIMD3<Float> = [0, 0, 0], viewMode: Bool = false, paused: Bool = false) {
        self.userPosition = userPosition
        self.viewMode = viewMode
        self.paused = paused
    }
}
