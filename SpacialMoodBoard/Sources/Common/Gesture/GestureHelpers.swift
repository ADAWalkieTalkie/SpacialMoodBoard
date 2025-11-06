import SwiftUI
import RealityKit

// MARK: - Entity Selection Helper

/// Entity를 선택하고 일정 시간 후 자동으로 해제
/// - Parameters:
///   - entity: 선택할 Entity
///   - selectedEntity: 선택 상태를 저장할 Binding
///   - duration: 자동 해제까지의 시간 (나노초, 기본값: 1초)
@MainActor
func selectEntityTemporarily(
    _ entity: Entity,
    selectedEntity: Binding<ModelEntity?>,
    duration: UInt64 = 100_000_000
) {
    selectedEntity.wrappedValue = entity as? ModelEntity
    
    Task {
        try? await Task.sleep(nanoseconds: duration)
        selectedEntity.wrappedValue = nil
    }
}

// MARK: - Gesture Helper Functions

/// Quaternion을 Euler angles (radians)로 변환
func quaternionToEuler(_ quat: simd_quatf) -> SIMD3<Float> {
    let qw = quat.vector.w
    let qx = quat.vector.x
    let qy = quat.vector.y
    let qz = quat.vector.z
    
    // Roll (x-axis rotation)
    let sinr_cosp = 2 * (qw * qx + qy * qz)
    let cosr_cosp = 1 - 2 * (qx * qx + qy * qy)
    let roll = atan2(sinr_cosp, cosr_cosp)
    
    // Pitch (y-axis rotation)
    let sinp = 2 * (qw * qy - qz * qx)
    let pitch: Float
    if abs(sinp) >= 1 {
        pitch = copysign(.pi / 2, sinp)
    } else {
        pitch = asin(sinp)
    }
    
    // Yaw (z-axis rotation)
    let siny_cosp = 2 * (qw * qz + qx * qy)
    let cosy_cosp = 1 - 2 * (qy * qy + qz * qz)
    let yaw = atan2(siny_cosp, cosy_cosp)
    
    return SIMD3<Float>(roll, pitch, yaw)
}

/// 쿼터니언에서 특정 축 기준 회전 각도 추출
func extractRotationAngle(from quat: simd_quatf, around axis: SIMD3<Float>) -> Float {
    // 쿼터니언을 각도-축 형태로 변환
    let angle = 2 * acos(min(1.0, max(-1.0, quat.real)))
    let sinHalfAngle = sqrt(1.0 - quat.real * quat.real)
    
    if sinHalfAngle < 0.001 {
        return 0 // 거의 회전하지 않음
    }
    
    let rotationAxis = quat.imag / sinHalfAngle
    let projection = dot(rotationAxis, normalize(axis))
    
    return angle * projection
}


//MARK: - Snap Angle

/// 각도를 지정된 각도 단위로 스냅
/// - Parameters:
///   - angle: 라디안 단위의 원본 각도
///   - snapDegrees: 스냅할 각도 (도 단위, 예: 15, 30, 45 등)
/// - Returns: 스냅된 각도 (라디안)
func snapAngle(_ angle: Float, toDegrees snapDegrees: Float) -> Float {
    let snapAngleRadians = snapDegrees * Float.pi / 180.0
    return round(angle / snapAngleRadians) * snapAngleRadians
}