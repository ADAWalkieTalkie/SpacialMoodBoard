import Foundation

// MARK: - SceneConfig (SceneRealityView의 설정 옵션)
struct SceneConfig {
    var showRotationButton: Bool = false
    var enableGestures: Bool = true
    var enableAttachments: Bool = true
    var alignToWindowBottom: Bool = false
    var scale: Float = 5.0
    var useHeadAnchoredToolbar: Bool = false
    var floorSize: SIMD3<Float> = SIMD3(5, 0.03, 5)


    static let immersive = SceneConfig(
        useHeadAnchoredToolbar: true 
    )

    static let volume = SceneConfig(
        showRotationButton: true,
        alignToWindowBottom: true,
        scale: 1
    )

    static let minimap = SceneConfig(
        enableGestures: false,
        enableAttachments: false,
        scale: 0.3
    )
}
