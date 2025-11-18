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
        minX: -1.0, maxX: 1.0,
        minY: -1.0, maxY: 1.0,
        minZ: -1.0, maxZ: 1.0
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
