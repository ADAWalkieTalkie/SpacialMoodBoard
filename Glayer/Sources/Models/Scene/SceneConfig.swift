import Foundation

// MARK: - SceneConfig (SceneRealityView의 설정 옵션)
struct SceneConfig {
    var showRotationButton: Bool = false
    var enableGestures: Bool = true
    var enableAttachments: Bool = true
    var alignToWindowBottom: Bool = false
    var rootEntityscale: SIMD3<Float> = [1, 1, 1]
    var useHeadAnchoredToolbar: Bool = false
    var rootEntityPosition: SIMD3<Float> = [0, 0, 0]
    var movementBounds: MovementBounds = .default
    
    static let immersive = SceneConfig(
        alignToWindowBottom: false,
        rootEntityscale: [8, 8, 8],
        useHeadAnchoredToolbar: true,
        rootEntityPosition: [0, 4, 0]
    )
    
    static let volume = SceneConfig(
        showRotationButton: true,
        alignToWindowBottom: true
    )
}
