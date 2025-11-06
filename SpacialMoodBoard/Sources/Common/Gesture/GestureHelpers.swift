import SwiftUI
import RealityKit

// MARK: - Entity Selection Helper

/// Entity를 선택하고 즉시 해제 (렌더링 사이클을 통한 선택 상태 업데이트용)
/// - Parameters:
///   - entity: 선택할 Entity
///   - selectedEntity: 선택 상태를 저장할 Binding
@MainActor
func selectEntityTemporarily(
    _ entity: Entity,
    selectedEntity: Binding<ModelEntity?>   
) {
    selectedEntity.wrappedValue = entity as? ModelEntity
    // SwiftUI의 렌더링 사이클을 통해 선택 상태가 업데이트된 후
    // 다음 렌더링 사이클에서 nil로 설정
    DispatchQueue.main.async {
        selectedEntity.wrappedValue = nil
    }
}


// MARK: - Entity Boundary Helper

/// Entity의 원본 bounds를 반환
/// - Parameters:
///   - entity: 원본 bounds를 계산할 Entity
/// - Returns: Entity의 원본 bounds
@MainActor
func getOriginalEntityBounds(_ entity: ModelEntity) -> BoundingBox {    
    // boundBox와 objectAttachment 자식들을 일시적으로 제거
    let boundBoxes = entity.children.filter { $0.name == "boundBox" }
    let attachments = entity.children.filter { $0.name == "objectAttachment" }
    
    // 자식들의 원본 위치 저장 (나중에 복원하기 위해)
    var childPositions: [Entity: SIMD3<Float>] = [:]
    (boundBoxes + attachments).forEach { child in
        childPositions[child] = child.position
    }
    
    boundBoxes.forEach { $0.removeFromParent() }
    attachments.forEach { $0.removeFromParent() }
    
    // 원본 엔티티의 bounds 계산
    let bounds = entity.visualBounds(relativeTo: nil)
    
    // boundBox와 attachment를 다시 추가 (원본 위치로)
    boundBoxes.forEach { box in
        entity.addChild(box)
        box.position = childPositions[box] ?? box.position
    }
    attachments.forEach { attachment in
        entity.addChild(attachment)
        attachment.position = childPositions[attachment] ?? attachment.position
    }
    
    return bounds
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


// MARK: - Rotation Angle Helper
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