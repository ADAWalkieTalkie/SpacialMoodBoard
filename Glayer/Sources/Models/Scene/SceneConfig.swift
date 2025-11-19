import Foundation

// MARK: - SceneConfig (SceneRealityView의 설정 옵션)
struct SceneConfig {
    var enableGestures: Bool = true
    var rootEntityscale: SIMD3<Float> = [0.1, 0.1, 0.1]
    var useHeadAnchoredToolbar: Bool = false
    var rootEntityPosition: SIMD3<Float> = [0, 0, 0]
    var movementBounds: MovementBounds = .default
    
    static let immersive = SceneConfig(
        rootEntityscale: [
            SceneConstants.ImmersiveMode.scale,
            SceneConstants.ImmersiveMode.scale,
            SceneConstants.ImmersiveMode.scale
        ],
        useHeadAnchoredToolbar: true,
        rootEntityPosition: [0, SceneConstants.ImmersiveMode.yPosition, 0]
    )
    
    static let volume = SceneConfig()
}
