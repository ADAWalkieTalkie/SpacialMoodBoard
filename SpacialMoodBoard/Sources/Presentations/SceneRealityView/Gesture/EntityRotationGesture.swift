import SwiftUI
import RealityKit

// MARK: - Entity Rotation Gesture

struct EntityRotationGesture: ViewModifier {
    let onRotationUpdate: (UUID, SIMD3<Float>) -> Void
    let onBillboardableChange: (UUID, Bool) -> Void
    
    @State private var initialOrientation: simd_quatf? = nil
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                // 회전 Gesture (Y축으로 제한)
                RotateGesture3D()
                    .targetedToEntity(where: .has(InputTargetComponent.self))
                    .onChanged { value in
                        let rootEntity = value.entity
                        
                        if initialOrientation == nil {
                            initialOrientation = rootEntity.orientation
                        }
                        
                        // 제스처 회전을 월드 공간의 Y축(수직축)으로만 제한
                        let rotationQuat = simd_quatf(value.rotation)
                        
                        // 월드 Y축을 Entity의 로컬 좌표계로 변환
                        let worldYAxis = SIMD3<Float>(0, 1, 0)
                        let localYAxis = rootEntity.orientation.inverse.act(worldYAxis)
                        
                        // 로컬 Y축 기준 회전 각도 추출
                        let angle = extractRotationAngle(from: rotationQuat, around: localYAxis)
                        
                        // 월드 Y축 기준으로 회전
                        let worldYRotation = simd_quatf(angle: angle, axis: worldYAxis)
                        
                        rootEntity.orientation = worldYRotation * (initialOrientation ?? simd_quatf(angle: 0, axis: [0, 1, 0]))
                    }
                    .onEnded { value in
                        guard let uuid = UUID(uuidString: value.entity.name) else {
                            print("❌ Entity name을 UUID로 변환 실패")
                            initialOrientation = nil
                            return
                        }
                        
                        // 최종 rotation을 Euler angles로 변환해서 저장
                        let finalRotation = quaternionToEuler(value.entity.orientation)
                        onRotationUpdate(uuid, finalRotation)
                        // 회전 제스처 실행시 billboardable을 false로 설정
                        onBillboardableChange(uuid, false)
                        
                        initialOrientation = nil
                        
                        print("🔄 Rotation 업데이트: \(uuid) - rotation: \(finalRotation)")
                    }
            )
    }
}
// MARK: - View Extension
extension View {
    func entityRotationGesture(
        onRotationUpdate: @escaping (UUID, SIMD3<Float>) -> Void,
        onBillboardableChange: @escaping (UUID, Bool) -> Void
    ) -> some View {
        self.modifier(EntityRotationGesture(
            onRotationUpdate: onRotationUpdate,
            onBillboardableChange: onBillboardableChange
        ))
    }
}