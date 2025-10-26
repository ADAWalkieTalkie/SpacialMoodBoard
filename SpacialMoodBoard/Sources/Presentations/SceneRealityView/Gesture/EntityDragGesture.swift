import SwiftUI
import RealityKit

// MARK: - Entity Drag Gesture

struct EntityDragGesture: ViewModifier {
    let onPositionUpdate: (UUID, SIMD3<Float>) -> Void
    let onRotationUpdate: (UUID, SIMD3<Float>) -> Void
    let getBillboardableState: (UUID) -> Bool
    let getHeadPosition: () -> SIMD3<Float>
    
    @State private var initialPosition: SIMD3<Float>? = nil
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                // 이동 Gesture
                DragGesture()
                    .targetedToEntity(where: .has(InputTargetComponent.self))
                    .onChanged { value in
                        let rootEntity = value.entity
                        
                        if initialPosition == nil {
                            initialPosition = rootEntity.position
                        }
                        
                        let movement = value.convert(value.translation3D, from: .global, to: .scene)
                        rootEntity.position = (initialPosition ?? .zero) + movement
                        
                        guard let uuid = UUID(uuidString: value.entity.name) else { return }
                        
                        let isBillboardable = getBillboardableState(uuid)
                        
                        if isBillboardable {
                            // 모든 축의 Billboard
                            applyFullBillboard(to: rootEntity)
                        } else {
                            // Y축만 고정, X/Z축은 Billboard
                            applyYAxisLockedBillboard(to: rootEntity)
                        }
                    }
                    .onEnded { value in
                        guard let uuid = UUID(uuidString: value.entity.name) else {
                            print("❌ Entity name을 UUID로 변환 실패")
                            initialPosition = nil
                            return
                        }
                        
                        // 최종 rotation 저장
                        let eulerRotation = quaternionToEuler(value.entity.orientation)
                        onRotationUpdate(uuid, eulerRotation)
                        onPositionUpdate(uuid, value.entity.position)
                        
                        initialPosition = nil
                        
                        let isBillboardable = getBillboardableState(uuid)
                        print("📍 위치 업데이트: \(uuid)")
                        print("🔄 회전 저장: \(eulerRotation) - billboardable: \(isBillboardable)")
                    }
            )
    }
    
    /// 모든 축의 Billboard (완전히 사용자를 향함)
    private func applyFullBillboard(to entity: Entity) {
        let headPosition = getHeadPosition()
        let entityPosition = entity.position(relativeTo: nil)
        
        // Entity에서 head로 향하는 방향
        let direction = normalize(headPosition - entityPosition)
        
        // 방향 벡터를 quaternion으로 변환
        // Entity가 Z축이 앞을 향한다고 가정
        let targetForward = direction
        let up = SIMD3<Float>(0, 1, 0)
        
        // Look-at rotation 계산
        let right = normalize(cross(up, targetForward))
        let correctedUp = cross(targetForward, right)
        
        let rotationMatrix = simd_float3x3(right, correctedUp, targetForward)
        entity.orientation = simd_quatf(rotationMatrix)
    }
    
    /// Y축 회전만 고정, X/Z축은 사용자를 향함
    private func applyYAxisLockedBillboard(to entity: Entity) {
        // 1. 현재 Y축 회전값 추출 (사용자가 설정한 값)
        let currentEuler = quaternionToEuler(entity.orientation)
        let lockedYRotation = currentEuler.y
        
        // 2. 실제 head 위치 가져오기
        let headPosition = getHeadPosition()
        let entityPosition = entity.position(relativeTo: nil)
        let directionToHead = normalize(headPosition - entityPosition)
        
        // 3. X축 회전 계산 (위아래 기울기)
        let pitchAngle = -asin(directionToHead.y)
        
        // 4. 회전 조합: Y축(고정) + X축(자동) + Z축(0)
        let yRotation = simd_quatf(angle: lockedYRotation, axis: [0, 1, 0])
        let xRotation = simd_quatf(angle: pitchAngle, axis: [1, 0, 0])
        
        entity.orientation = yRotation * xRotation
    }
}

// MARK: - View Extension
extension View {
    func entityDragGesture(
        onPositionUpdate: @escaping (UUID, SIMD3<Float>) -> Void,
        onRotationUpdate: @escaping (UUID, SIMD3<Float>) -> Void,
        getBillboardableState: @escaping (UUID) -> Bool,
        getHeadPosition: @escaping () -> SIMD3<Float>
    ) -> some View {
        self.modifier(EntityDragGesture(
            onPositionUpdate: onPositionUpdate,
            onRotationUpdate: onRotationUpdate,
            getBillboardableState: getBillboardableState,
            getHeadPosition: getHeadPosition
        ))
    }
}
