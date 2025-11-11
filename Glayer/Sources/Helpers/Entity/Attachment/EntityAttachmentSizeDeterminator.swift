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
        let distanceBasedScale = calculateScale(
            headPosition: headPosition,
            entityPosition: entityWorldPosition
        )
        
        // 3. Volume 모드 배율 적용
        let volumeMultiplier: Float = isVolumeMode ? 24.0 : 1.0
        let adjustedScale = distanceBasedScale * volumeMultiplier
        
        // 4. 부모 엔티티 스케일 보정
        let parentScale = entity.scale
        let finalScale = SIMD3<Float>(
            adjustedScale / parentScale.x * scaleFactor,
            adjustedScale / parentScale.y * scaleFactor,
            adjustedScale / parentScale.z * scaleFactor
        )
        
        return finalScale
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
    /// - Returns: 크기
    private static func sizeCalculation(from distance: Float) -> Float {
        return distance * 0.1
    }
}