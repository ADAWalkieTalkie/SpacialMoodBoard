import RealityKit

struct EntityAttachmentSizeDeterminator {

    /// 거리 계산
    /// - Parameters:
    ///   - headPosition: 머리 위치
    ///   - targetPosition: 대상 위치
    /// - Returns: 거리
    private func distanceCalculation(from headPosition: simd_float3, to targetPosition: simd_float3) -> Float {
        return simd_distance(headPosition, targetPosition)
    }

    /// 거리에 따라 크기 계산
    /// - Parameters:
    ///   - distance: 거리
    /// - Returns: 크기
    private func sizeCalculation(from distance: Float) -> Float {
        return distance * 0.1
    }

    /// 헤드 위치와 엔티티 위치 기반으로 스케일 계산
    /// - Parameters:
    ///   - headPosition: 헤드 위치
    ///   - entityPosition: 엔티티 위치
    /// - Returns: 계산된 스케일
    func calculateScale(headPosition: SIMD3<Float>, entityPosition: SIMD3<Float>) -> Float {
        let distance = distanceCalculation(from: headPosition, to: entityPosition)
        return sizeCalculation(from: distance)
    }
}