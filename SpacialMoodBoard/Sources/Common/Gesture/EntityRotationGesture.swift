import SwiftUI
import RealityKit

// MARK: - Entity Rotation Gesture

struct EntityRotationGesture: ViewModifier {
    @Binding var selectedEntity: ModelEntity?
    let onRotationUpdate: (UUID, SIMD3<Float>) -> Void
    let snapAngleDegrees: Float
    
    @State private var initialOrientation: simd_quatf? = nil
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                // 회전 Gesture (Y축으로 제한)
                RotateGesture3D()
                    .targetedToEntity(where: .has(InputTargetComponent.self))
                    .onChanged { value in
                        let currentEntity = value.entity
                        
                        // 제스처 시작 시 Entity 선택
                        if let modelEntity = currentEntity as? ModelEntity {
                            selectedEntity = modelEntity
                        }
                        
                        if initialOrientation == nil {
                            selectEntityTemporarily(currentEntity, selectedEntity: $selectedEntity)
                            initialOrientation = currentEntity.orientation
                        }
                        
                        // 제스처 회전을 월드 공간의 Y축(수직축)으로만 제한
                        let rotationQuat = simd_quatf(value.rotation)
                        
                        // 월드 Y축을 Entity의 로컬 좌표계로 변환
                        let worldYAxis = SIMD3<Float>(0, 1, 0) // 0, 1, 0 대신 1, 1, 1로 변경(모든 축을 고려)
                        let localYAxis = currentEntity.orientation.inverse.act(worldYAxis)
                        
                        // 로컬 Y축 기준 회전 각도 추출
                        let angle = extractRotationAngle(from: rotationQuat, around: localYAxis)

                        // 지정된 각도 단위로 스냅
                        let snappedAngle = snapAngle(angle, toDegrees: snapAngleDegrees)
                        
                        // 월드 Y축 기준으로 회전
                        let worldYRotation = simd_quatf(angle: snappedAngle, axis: worldYAxis)
                        
                        currentEntity.orientation = worldYRotation * (initialOrientation ?? simd_quatf(angle: 0, axis: [0, 1, 0]))
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
                        
                        selectEntityTemporarily(value.entity, selectedEntity: $selectedEntity)
                        
                        initialOrientation = nil
                    }
            )
    }
}

// MARK: - View Extension
extension View {
    func entityRotationGesture(
        selectedEntity: Binding<ModelEntity?>,
        onRotationUpdate: @escaping (UUID, SIMD3<Float>) -> Void,
        snapAngleDegrees: Float = 15.0 // 기본값 15도
    ) -> some View {
        self.modifier(EntityRotationGesture(
            selectedEntity: selectedEntity,
            onRotationUpdate: onRotationUpdate,
            snapAngleDegrees: snapAngleDegrees
        ))
    }
}
