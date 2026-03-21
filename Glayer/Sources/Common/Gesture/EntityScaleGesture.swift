import SwiftUI
import RealityKit

// MARK: - Entity Scale Gesture

struct EntityScaleGesture: ViewModifier {
    @Binding var selectedEntity: ModelEntity?
    let onScaleUpdate: (UUID, Float) -> Void
    let onGestureStart: (() -> Void)?
    let onGestureUpdated: (() -> Void)?
    let onGestureEnd: (() -> Void)?
    @State private var initialScale: SIMD3<Float>? = nil
    private let minObjectScale: Float = 0.05
    private let maxObjectScale: Float = 6.0
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                // 확대/축소 Gesture
                MagnifyGesture()
                    .targetedToEntity(where: .has(InputTargetComponent.self))
                    .onChanged { value in
                        if EntityClassifier.classify(value.entity) == .sound { return }
                        
                        let currentEntity = value.entity
                        
                        if let modelEntity = currentEntity as? ModelEntity {
                            if initialScale == nil {
                                // 제스처 시작 시에만 선택
                                selectedEntity = modelEntity
                                onGestureStart?()
                                initialScale = currentEntity.scale
                            }
                        }
                        
                        let magnification = sanitizedMagnification(Float(value.magnification))
                        let baseScale = initialScale ?? .init(repeating: 1.0)
                        currentEntity.scale = clampedScale(baseScale * magnification)

                        onGestureUpdated?()
                    }
                    .onEnded { value in
                        guard let uuid = UUID(uuidString: value.entity.name) else {
                            print("❌ Entity name을 UUID로 변환 실패")
                            initialScale = nil
                            return
                        }

                        let scaleMultiplier = sanitizedMagnification(Float(value.magnification))
                        onScaleUpdate(uuid, scaleMultiplier)

                        onGestureEnd?()
                        initialScale = nil
                    }
            )
    }
    
    private func sanitizedMagnification(_ magnification: Float) -> Float {
        guard magnification.isFinite else { return 1.0 }
        return max(magnification, 0.001)
    }
    
    private func clampedScale(_ scale: SIMD3<Float>) -> SIMD3<Float> {
        let x = min(max(scale.x, minObjectScale), maxObjectScale)
        let y = min(max(scale.y, minObjectScale), maxObjectScale)
        let z = min(max(scale.z, minObjectScale), maxObjectScale)
        return SIMD3<Float>(x, y, z)
    }
}

// MARK: - View Extension
extension View {
    func entityScaleGesture(
        selectedEntity: Binding<ModelEntity?>,
        onScaleUpdate: @escaping (UUID, Float) -> Void,
        onGestureStart: (() -> Void)?,
        onGestureUpdated: (() -> Void)?,
        onGestureEnd: (() -> Void)?
    ) -> some View {
        self.modifier(EntityScaleGesture(
            selectedEntity: selectedEntity,
            onScaleUpdate: onScaleUpdate,
            onGestureStart: onGestureStart,
            onGestureUpdated: onGestureUpdated,
            onGestureEnd: onGestureEnd
        ))
    }
}
