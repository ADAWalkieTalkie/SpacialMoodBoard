import SwiftUI
import RealityKit

// MARK: - Entity Drag Gesture

struct EntityDragGesture: ViewModifier {
    let onPositionUpdate: (UUID, SIMD3<Float>) -> Void
    let onRotationUpdate: (UUID, SIMD3<Float>) -> Void
    let getBillboardableState: (UUID) -> Bool 
    
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
                            // billboardable = true: 모든 축의 Billboard 적용
                            rootEntity.components.set(BillboardComponent())
                        } else {
                            // billboardable = false: Y축은 고정, X/Z축만 Billboard
                            applyPartialBillboard(to: rootEntity)
                        }
                    }
                    .onEnded { value in
                        guard let uuid = UUID(uuidString: value.entity.name) else {
                            print("❌ Entity name을 UUID로 변환 실패")
                            initialPosition = nil
                            return
                        }
                        
                        // billboardable 상태 확인
                        let isBillboardable = getBillboardableState(uuid)
                        
                        if isBillboardable {
                            // Billboard로 적용된 현재 orientation 저장
                            let finalOrientation = value.entity.orientation
                            
                            // Billboard 제거
                            value.entity.components.remove(BillboardComponent.self)
                            
                            // Orientation 유지
                            value.entity.orientation = finalOrientation
                            
                            // Euler angles로 변환해서 저장
                            let eulerRotation = quaternionToEuler(finalOrientation)
                            onRotationUpdate(uuid, eulerRotation)
                            
                            print("🔄 회전 저장 (모든 축): \(eulerRotation)")

                        } else {
                            // Y축은 유지, X/Z축만 저장
                            let eulerRotation = quaternionToEuler(value.entity.orientation)
                            onRotationUpdate(uuid, eulerRotation)
                            
                            print("🔄 회전 저장 (Y축 고정, X/Z축만): \(eulerRotation)")
                        }
                        
                        onPositionUpdate(uuid, value.entity.position)
                        initialPosition = nil
                    }
            )
    }

    /// Y축 회전은 유지하고 X, Z축만 사용자를 향하도록 적용
    private func applyPartialBillboard(to entity: Entity) {
        // 1. 현재 Y축 회전값 추출 (사용자가 설정한 값)
        let currentEuler = quaternionToEuler(entity.orientation)
        let lockedYRotation = currentEuler.y  // y 값은 고정
        
        // 2. 사용자(카메라) 방향 계산
        // Billboard 효과를 위해 entity가 향해야 할 방향
        let cameraPosition = SIMD3<Float>(0, 1.6, 0)  // 대략적인 사용자 눈 높이
        let entityPosition = entity.position(relativeTo: nil)
        let directionToUser = normalize(cameraPosition - entityPosition)
        
        // 3. X축 회전 계산 (위아래 기울기) - Billboard가 자동 설정
        let pitchAngle = -asin(directionToUser.y)
        
        // 4. Z축 회전은 0으로 유지 (일반적으로 사용하지 않음)
        let rollAngle: Float = 0
        
        // 5. 회전 조합: Y축(고정) + X축(자동) + Z축(자동)
        let yRotation = simd_quatf(angle: lockedYRotation, axis: [0, 1, 0])  // 고정
        let xRotation = simd_quatf(angle: pitchAngle, axis: [1, 0, 0])      // 자동
        let zRotation = simd_quatf(angle: rollAngle, axis: [0, 0, 1])   
        
        entity.orientation = yRotation * xRotation * zRotation
    }
}

// MARK: - View Extension
extension View {
    func entityDragGesture(
        onPositionUpdate: @escaping (UUID, SIMD3<Float>) -> Void,
        onRotationUpdate: @escaping (UUID, SIMD3<Float>) -> Void,
        getBillboardableState: @escaping (UUID) -> Bool
    ) -> some View {
        self.modifier(EntityDragGesture(
            onPositionUpdate: onPositionUpdate,
            onRotationUpdate: onRotationUpdate,
            getBillboardableState: getBillboardableState
        ))
    }
}