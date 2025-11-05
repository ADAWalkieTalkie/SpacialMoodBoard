import SwiftUI
import RealityKit

extension View {
    /// 모든 Entity Gesture를 한 번에 적용
    func immersiveEntityGestures(
        selectedEntity: Binding<ModelEntity?>,
        onPositionUpdate: @escaping (UUID, SIMD3<Float>) -> Void,
        onRotationUpdate: @escaping (UUID, SIMD3<Float>) -> Void,
        onScaleUpdate: @escaping (UUID, Float) -> Void
    ) -> some View {
        self
            .entitySelectionGesture(selectedEntity: selectedEntity)
            .entityDragGesture(
                onPositionUpdate: onPositionUpdate,
                onRotationUpdate: onRotationUpdate
            )
            .entityScaleGesture(onScaleUpdate: onScaleUpdate)
            .entityRotationGesture(
                onRotationUpdate: onRotationUpdate
            )
    }
}