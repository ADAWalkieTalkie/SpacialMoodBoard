import SwiftUI
import RealityKit

// MARK: - Entity Scale Gesture

struct EntityScaleGesture: ViewModifier {
    @Binding var selectedEntity: ModelEntity?
    let onScaleUpdate: (UUID, Float) -> Void
    
    @State private var initialScale: SIMD3<Float>? = nil
    @State private var hasStartedGesture: Bool = false
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                // 확대/축소 Gesture
                MagnifyGesture()
                    .targetedToEntity(where: .has(InputTargetComponent.self))
                    .onChanged { value in
                        if EntityClassifier.classify(value.entity) == .sound { return }
                        
                        let currentEntity = value.entity
                        
                        if initialScale == nil {
                            selectEntityTemporarily(currentEntity, selectedEntity: $selectedEntity)
                            initialScale = currentEntity.scale
                        }
                        
                        currentEntity.scale = (initialScale ?? .init(repeating: 1.0)) * Float(value.magnification)
                    }
                    .onEnded { value in
                        guard let uuid = UUID(uuidString: value.entity.name) else {
                            print("❌ Entity name을 UUID로 변환 실패")
                            initialScale = nil
                            return
                        }
                        
                        let finalScale = value.entity.scale.x // uniform scale이므로 x만 사용
                        onScaleUpdate(uuid, finalScale)

                        selectEntityTemporarily(value.entity, selectedEntity: $selectedEntity)
                        
                        initialScale = nil
                    }
            )
    }
}

// MARK: - View Extension
extension View {
    func entityScaleGesture(
        selectedEntity: Binding<ModelEntity?>,
        onScaleUpdate: @escaping (UUID, Float) -> Void
    ) -> some View {
        self.modifier(EntityScaleGesture(
            selectedEntity: selectedEntity,
            onScaleUpdate: onScaleUpdate
        ))
    }
}
