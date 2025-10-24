import Foundation

// MARK: - SceneConfig (SceneRealityView의 설정 옵션)
struct SceneConfig {
    var showRotationButton: Bool = false
    var enableGestures: Bool = true
    var enableAttachments: Bool = true
    var applyWallOpacity: Bool = false
    var alignToWindowBottom: Bool = false
    var scale: Float = 1.0
    var useHeadAnchoredToolbar: Bool = false 

    static let immersive = SceneConfig(
        enableGestures: true,
        enableAttachments: true,
        useHeadAnchoredToolbar: true 
    )

    static let volume = SceneConfig(
        showRotationButton: true,
        enableGestures: true,
        enableAttachments: true,
        applyWallOpacity: true,
        alignToWindowBottom: true,
        useHeadAnchoredToolbar: false 
    )

    static let minimap = SceneConfig(
        showRotationButton: false,
        enableGestures: false,
        enableAttachments: false,
        scale: 0.3,
        useHeadAnchoredToolbar: false
    )
}