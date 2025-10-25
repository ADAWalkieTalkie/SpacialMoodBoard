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
                        rootEntity.position = (initialPosition ?? .zero) + movement
                        
                        // 드래그 중 Billboard 효과
                        rootEntity.components.set(BillboardComponent())
                    }
                    .onEnded { value in
                        guard let uuid = UUID(uuidString: value.entity.name) else {
                            print("❌ Entity name을 UUID로 변환 실패")
                            initialPosition = nil
                            return
                        }
                        
                        // Billboard로 적용된 현재 orientation 저장
                        let finalOrientation = value.entity.orientation
                        
                        // Billboard 제거
                        value.entity.components.remove(BillboardComponent.self)
                        
                        // Orientation 유지
                        value.entity.orientation = finalOrientation
                        
                        // Euler angles로 변환해서 저장
                        let eulerRotation = quaternionToEuler(finalOrientation)
                        
                        onPositionUpdate(uuid, value.entity.position)
                        onRotationUpdate(uuid, eulerRotation)
                        
                        initialPosition = nil
                        
                        print("📍 위치 업데이트: \(uuid)")
                        print("🔄 회전 저장: \(eulerRotation)")
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