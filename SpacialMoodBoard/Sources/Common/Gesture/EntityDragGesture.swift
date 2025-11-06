import SwiftUI
import RealityKit

// MARK: - Entity Drag Gesture

struct EntityDragGesture: ViewModifier {
    @Binding var selectedEntity: ModelEntity?
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
                        let currentEntity = value.entity
                        
                        // 제스처 시작 시 Entity 선택
                        if let modelEntity = currentEntity as? ModelEntity {
                            selectedEntity = modelEntity
                        }
                        
                        if initialPosition == nil {
                            selectEntityTemporarily(currentEntity, selectedEntity: $selectedEntity)
                            initialPosition = currentEntity.position
                        }
                        
                        let movement = value.convert(value.translation3D, from: .global, to: .scene)
                        let newPosition = (initialPosition ?? .zero) + movement

                        // 엔티티의 높이를 계산하여 하단이 y=0 아래로 내려가지 않도록 제한
                        var minY: Float = 0
                        if let modelEntity = currentEntity as? ModelEntity {
                            let bounds = modelEntity.visualBounds(relativeTo: nil)
                            let halfHeight = bounds.extents.y / 2.0

                            // Floor 엔티티를 찾아서 실제 씬 좌표 기준으로 minY 계산
                            if let parent = rootEntity.parent,
                               let floor = parent.findEntity(named: "floorRoot") {
                                let floorWorldPosition = floor.position(relativeTo: nil)
                                minY = floorWorldPosition.y + halfHeight
                            } else {
                                // Floor를 찾지 못한 경우: 기존 로직 (y=0 기준)
                                minY = halfHeight
                            }
                        }

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
                            return
                        }
                        
                        // 최종 rotation 저장
                        let eulerRotation = quaternionToEuler(value.entity.orientation)
                        onRotationUpdate(uuid, eulerRotation)
                        onPositionUpdate(uuid, value.entity.position)
                        
                        selectEntityTemporarily(value.entity, selectedEntity: $selectedEntity)
                        
                        initialPosition = nil
                    }
            )
    }
}

// MARK: - View Extension
extension View {
    func entityDragGesture(
        selectedEntity: Binding<ModelEntity?>,
        onPositionUpdate: @escaping (UUID, SIMD3<Float>) -> Void,
        onRotationUpdate: @escaping (UUID, SIMD3<Float>) -> Void
    ) -> some View {
        self.modifier(EntityDragGesture(
            selectedEntity: selectedEntity,
            onPositionUpdate: onPositionUpdate,
            onRotationUpdate: onRotationUpdate
        ))
    }
}
