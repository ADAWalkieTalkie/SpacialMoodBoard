import Foundation

// MARK: - MovementBounds

struct MovementBounds {
    let minX: Float
    let maxX: Float
    let minY: Float
    let maxY: Float
    let minZ: Float
    let maxZ: Float
    
    static let `default` = MovementBounds(
        minX: -0.5, maxX: 0.5,
        minY: -0.5, maxY: 0.5,
        minZ: -0.5, maxZ: 0.5
    )
    
    /// 위치를 영역 내로 제한
    func clamp(_ position: SIMD3<Float>) -> SIMD3<Float> {
        return SIMD3<Float>(
            max(minX, min(maxX, position.x)),
            max(minY, min(maxY, position.y)),
            max(minZ, min(maxZ, position.z))
        )
    }
}
