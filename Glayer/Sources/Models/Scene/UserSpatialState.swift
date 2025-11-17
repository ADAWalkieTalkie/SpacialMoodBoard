import Foundation

// MARK: - UserSpatialState (User의 ImmersiveScene 내에서의 위치 및 뷰 모드)
struct UserSpatialState: Codable, Hashable {
    var userPosition: SIMD3<Float> = [0, 0, 0]
    var headAnchorState: HeadAnchorState = HeadAnchorState()
    var viewMode: Bool = false
    var paused: Bool = false

    init(userPosition: SIMD3<Float> = [0, 0, 0],
         headAnchorState: HeadAnchorState = HeadAnchorState(),
         viewMode: Bool = false,
         paused: Bool = false) {
        self.userPosition = userPosition
        self.headAnchorState = headAnchorState
        self.viewMode = viewMode
        self.paused = paused
    }
}

// MARK: - HeadAnchorState (HeadAnchor의 위치와 회전 정보)
struct HeadAnchorState: Codable, Hashable {
    var position: SIMD3<Float> = [0, 0, 0]
    var rotation: SIMD4<Float> = [0, 0, 0, 1]  // quaternion as SIMD4
}