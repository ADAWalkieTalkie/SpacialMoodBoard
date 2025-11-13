import RealityKit

enum EntityAttachmentSizeDeterminator {
    static let scaleFactor: Float = 1

    /// Attachment의 최종 스케일 계산 (모든 보정 포함)
    /// - Parameters:
    ///   - headPosition: 헤드 위치
    ///   - entity: Attachment가 붙을 대상 엔티티
    ///   - isVolumeMode: Volume 모드 여부
    /// - Returns: 최종 스케일 (SIMD3<Float>)
    static func calculateFinalScale(
        headPosition: SIMD3<Float>,
        entity: ModelEntity,
        isVolumeMode: Bool
    ) -> SIMD3<Float> {
        // 1. 엔티티의 월드 좌표 위치
        let entityWorldPosition = entity.position(relativeTo: nil)
        
        // 2. 거리 기반 스케일 계산
        let distanceScale = calculateScale(
            headPosition: headPosition,
            entityPosition: entityWorldPosition
        )
        
        // 3. Volume 모드
        if isVolumeMode {
            return SIMD3<Float>(repeating: 1.0)
        } else {
            let immersiveBase: Float = 0.8
            
            let s = immersiveBase * distanceScale * scaleFactor
            return SIMD3<Float>(repeating: s)
        }
    }
        
    /// 헤드 위치와 엔티티 위치 기반으로 스케일 계산 (기본)
    /// - Parameters:
    ///   - headPosition: 헤드 위치
    ///   - entityPosition: 엔티티 위치
    /// - Returns: 계산된 스케일
    static func calculateScale(
        headPosition: SIMD3<Float>,
        entityPosition: SIMD3<Float>
    ) -> Float {
        let distance = distanceCalculation(from: headPosition, to: entityPosition)
        return sizeCalculation(from: distance)
    }

    /// 거리 계산
    /// - Parameters:
    ///   - headPosition: 머리 위치
    ///   - targetPosition: 대상 위치
    /// - Returns: 거리
    private static func distanceCalculation(from headPosition: simd_float3, to targetPosition: simd_float3) -> Float {
        return simd_distance(headPosition, targetPosition)
    }

    /// 거리에 따라 크기 계산
    /// - Parameters:
    ///   - distance: 거리
    /// - Returns: 크기 (가까울 때는 최소 1.0 유지, 멀어질 때는 1.1배씩 증가)
    private static func sizeCalculation(from distance: Float) -> Float {
        let growth = pow(1.1, max(0, distance - 1.0))
        return max(1.0, growth)
    }
}
