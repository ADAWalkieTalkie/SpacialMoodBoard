import SwiftUI
import RealityKit

// MARK: - Entity Drag Gesture

struct EntityDragGesture: ViewModifier {
    @Binding var selectedEntity: ModelEntity?
    let onPositionUpdate: (UUID, SIMD3<Float>) -> Void
    let onRotationUpdate: (UUID, SIMD3<Float>) -> Void
    let onGestureStart: (() -> Void)?
    let onGestureEnd: (() -> Void)?
    
    @State private var initialPosition: SIMD3<Float>? = nil
    @State private var minY: Float = 0  // 제스처 시작 시 한 번만 계산하여 저장
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                // 이동 Gesture
                DragGesture()
                    .targetedToEntity(where: .has(InputTargetComponent.self))
                    .onChanged { value in
                        let currentEntity = value.entity
                        
                        // 제스처 시작 시 Entity 선택
                        if let modelEntity = currentEntity as? ModelEntity {
                            selectedEntity = modelEntity
                            if initialPosition == nil {
                                onGestureStart?()
                                initialPosition = currentEntity.position
                                
                                let bounds = getOriginalEntityBounds(modelEntity)
                                let entityHeight = bounds.extents.y  // 전체 높이
                                let halfHeight = entityHeight / 2.0  // 높이의 절반
                                minY = halfHeight  // 중심점이 최소 halfHeight 이상이어야 하단이 y=0에 닿음
                            }
                        }
                        
                        let movement = value.convert(value.translation3D, from: .global, to: .scene)
                        let newPosition = (initialPosition ?? .zero) + movement

                        // 저장된 minY 값 사용
                        currentEntity.position = SIMD3<Float>(
                            newPosition.x,
                            max(-10, newPosition.y),
                            newPosition.z
                        )
                    }
                    .onEnded { value in
                        guard let uuid = UUID(uuidString: value.entity.name) else {
                            print("❌ Entity name을 UUID로 변환 실패")
                            initialPosition = nil
                            minY = 0
                            return
                        }
                        
                        // 최종 rotation 저장
                        let eulerRotation = quaternionToEuler(value.entity.orientation)
                        onRotationUpdate(uuid, eulerRotation)
                        onPositionUpdate(uuid, value.entity.position)

                        onGestureEnd?()
                        initialPosition = nil
                        minY = 0
                    }
            )
    }
}

// MARK: - View Extension
extension View {
    func entityDragGesture(
        selectedEntity: Binding<ModelEntity?>,
        onPositionUpdate: @escaping (UUID, SIMD3<Float>) -> Void,
        onRotationUpdate: @escaping (UUID, SIMD3<Float>) -> Void,
        onGestureStart: (() -> Void)?,
        onGestureEnd: (() -> Void)?
    ) -> some View {
        self.modifier(EntityDragGesture(
            selectedEntity: selectedEntity,
            onPositionUpdate: onPositionUpdate,
            onRotationUpdate: onRotationUpdate,
            onGestureStart: onGestureStart,
            onGestureEnd: onGestureEnd
        ))
    }
}
