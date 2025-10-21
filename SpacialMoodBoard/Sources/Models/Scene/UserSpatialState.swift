import Foundation

struct UserSpatialState: Codable, Hashable {
    var userPosition: SIMD3<Float> = [0, 0, 0]
    var viewMode: Bool = false

    init(userPosition: SIMD3<Float> = [0, 0, 0], viewMode: Bool = false) {
        self.userPosition = userPosition
        self.viewMode = viewMode
    }
}
