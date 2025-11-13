import SwiftUI
import RealityKit

extension View {
    /// 모든 Entity Gesture를 한 번에 적용
    func immersiveEntityGestures(
        selectedEntity: Binding<ModelEntity?>,
        onPositionUpdate: @escaping (UUID, SIMD3<Float>) -> Void,
        onRotationUpdate: @escaping (UUID, SIMD3<Float>) -> Void,
        onScaleUpdate: @escaping (UUID, Float) -> Void,
        onGestureStart: (() -> Void)?,
        onGestureEnd: (() -> Void)?,
        movementBounds: MovementBounds = .default
    ) -> some View {
        self
            .entitySelectionGesture(selectedEntity: selectedEntity)
            .entityDragGesture(
                selectedEntity: selectedEntity,
                onPositionUpdate: onPositionUpdate,
                onRotationUpdate: onRotationUpdate,
                onGestureStart: onGestureStart,
                onGestureEnd: onGestureEnd,
                movementBounds: movementBounds
            )
            .entityScaleGesture(
                selectedEntity: selectedEntity,
                onScaleUpdate: onScaleUpdate,
                onGestureStart: onGestureStart,
                onGestureEnd: onGestureEnd
            )
            .entityRotationGesture(
                selectedEntity: selectedEntity,
                onRotationUpdate: onRotationUpdate,
                onGestureStart: onGestureStart,
                onGestureEnd: onGestureEnd
            )
    }
}