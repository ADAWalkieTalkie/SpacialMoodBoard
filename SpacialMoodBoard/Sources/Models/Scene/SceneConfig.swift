import Foundation

// MARK: - SceneConfig (SceneRealityView의 설정 옵션)
struct SceneConfig {
    var showRotationButton: Bool = false
    var enableGestures: Bool = true
    var enableAttachments: Bool = true
    var alignToWindowBottom: Bool = false
    var scale: Float = 1.0
    var useHeadAnchoredToolbar: Bool = false
    var showFloorImageApplyButton: Bool = true  // floor 중앙에 이미지 적용 버튼 표시 여부
    var floorSize: SIMD3<Float> = SIMD3(5, 0.03, 5)


    static let immersive = SceneConfig(
        enableGestures: true,
        enableAttachments: true,
        useHeadAnchoredToolbar: true 
    )

    static let volume = SceneConfig(
        showRotationButton: true,
        enableGestures: true,
        enableAttachments: true,
        alignToWindowBottom: true,
        useHeadAnchoredToolbar: false,
    )

    static let minimap = SceneConfig(
        showRotationButton: false,
        enableGestures: false,
        enableAttachments: false,
        scale: 0.3,
        useHeadAnchoredToolbar: false,
        showFloorImageApplyButton: false
        
    )
}
