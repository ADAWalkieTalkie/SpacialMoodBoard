import Foundation

// MARK: - UserSpatialState (User의 ImmersiveScene 내에서의 위치 및 뷰 모드)
struct UserSpatialState: Codable, Hashable {
    var userScenePosition: SIMD3<Float> = [0, 0, 0]
    var headAnchorState: HeadAnchorState = HeadAnchorState()
    var viewMode: Bool = false
    var paused: Bool = false

    init(userScenePosition: SIMD3<Float> = [0, 0, 0],
         headAnchorState: HeadAnchorState = HeadAnchorState(),
         viewMode: Bool = false,
         paused: Bool = false) {
        self.userScenePosition = userScenePosition
        self.headAnchorState = headAnchorState
        self.viewMode = viewMode
        self.paused = paused
    }
    
    /// headAnchor 위치와 조이스틱 이동을 합친 실제 유저 위치 및 회전
    var sceneHeadAnchor: HeadAnchorState {
        return HeadAnchorState(
            position: headAnchorState.position - userScenePosition,
            rotation: headAnchorState.rotation
        )
    }
}

// MARK: - HeadAnchorState (HeadAnchor의 위치와 회전 정보)
struct HeadAnchorState: Codable, Hashable {
    var position: SIMD3<Float> = [0, 0, 0]
    var rotation: SIMD4<Float> = [0, 0, 0, 1]  // quaternion as SIMD4
    
    init(position: SIMD3<Float> = [0, 0, 0], rotation: SIMD4<Float> = [0, 0, 0, 1]) {
        self.position = position
        self.rotation = rotation
    }
}