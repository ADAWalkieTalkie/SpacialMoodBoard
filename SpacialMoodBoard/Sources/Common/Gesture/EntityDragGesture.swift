import SwiftUI
import RealityKit

// MARK: - Entity Drag Gesture

struct EntityDragGesture: ViewModifier {
    let onPositionUpdate: (UUID, SIMD3<Float>) -> Void
    let onRotationUpdate: (UUID, SIMD3<Float>) -> Void
    
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
                        let newPosition = (initialPosition ?? .zero) + movement

                        // 엔티티의 높이를 계산하여 하단이 y=0 아래로 내려가지 않도록 제한
                        var minY: Float = 0
                        if let modelEntity = rootEntity as? ModelEntity {
                            let bounds = modelEntity.visualBounds(relativeTo: nil)
                            let entityHeight = bounds.extents.y  // 전체 높이
                            let halfHeight = entityHeight / 2.0  // 높이의 절반
                            minY = halfHeight  // 중심점이 최소 halfHeight 이상이어야 하단이 y=0에 닿음
                        }

                        rootEntity.position = SIMD3<Float>(
                            newPosition.x,
                            max(minY, newPosition.y),
                            newPosition.z
                        )
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
                    }
            )
    }
}

// MARK: - View Extension
extension View {
    func entityDragGesture(
        onPositionUpdate: @escaping (UUID, SIMD3<Float>) -> Void,
        onRotationUpdate: @escaping (UUID, SIMD3<Float>) -> Void
    ) -> some View {
        self.modifier(EntityDragGesture(
            onPositionUpdate: onPositionUpdate,
            onRotationUpdate: onRotationUpdate
        ))
    }
}
