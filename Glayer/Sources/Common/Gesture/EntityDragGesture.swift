import SwiftUI
import RealityKit

// MARK: - Entity Drag Gesture

/// RealityKit 엔티티 드래그 제스처 처리
///
/// 3D 공간에서 엔티티를 드래그하여 이동시키는 제스처를 처리합니다.
/// 이동 범위 제한, 바닥 충돌 방지, 경계면 시각적 피드백을 포함합니다.
///
/// ## 주요 기능
/// - 3D 공간에서의 자유로운 엔티티 이동
/// - 이동 범위 제한 (MovementBounds)
/// - 바닥 충돌 방지 (엔티티가 바닥 아래로 내려가지 않음)
/// - 경계면 충돌 시각적 피드백 (Glow 효과)
/// - 위치/회전 변경 시 자동 저장
///
/// ## 사용 예시
/// ```swift
/// SceneRealityView()
///     .entityDragGesture(
///         selectedEntity: $selectedEntity,
///         onPositionUpdate: { id, pos in
///             viewModel.updateObjectPosition(id: id, position: pos)
///         },
///         onRotationUpdate: { id, rot in
///             viewModel.updateObjectRotation(id: id, rotation: rot)
///         },
///         onGestureStart: {
///             viewModel.startGesture()
///         },
///         onGestureEnd: {
///             viewModel.endGesture()
///         },
///         onBoundaryCollision: { entity in
///             viewModel.checkBoundaryCollision(for: entity)
///         },
///         movementBounds: .default
///     )
/// ```
struct EntityDragGesture: ViewModifier {
    /// 현재 선택된 엔티티 (드래그 중인 엔티티)
    @Binding var selectedEntity: ModelEntity?

    /// 위치 업데이트 콜백
    ///
    /// 제스처 종료 시 최종 위치를 저장하기 위해 호출됩니다.
    /// - Parameters:
    ///   - UUID: 엔티티 ID
    ///   - SIMD3<Float>: 최종 위치
    let onPositionUpdate: (UUID, SIMD3<Float>) -> Void

    /// 회전 업데이트 콜백
    ///
    /// 제스처 종료 시 최종 회전을 저장하기 위해 호출됩니다.
    /// - Parameters:
    ///   - UUID: 엔티티 ID
    ///   - SIMD3<Float>: 최종 회전 (Euler angles)
    let onRotationUpdate: (UUID, SIMD3<Float>) -> Void

    /// 제스처 시작 콜백 (옵션)
    ///
    /// 드래그를 시작할 때 호출됩니다.
    /// SceneViewModel.startGesture()를 호출하여 엔티티 업데이트를 일시 중지합니다.
    let onGestureStart: (() -> Void)?

    /// 제스처 업데이트 콜백 (옵션)
    ///
    /// 드래그가 진행되는 동안 매 프레임 호출됩니다.
    let onGestureUpdated: (() -> Void)?

    /// 제스처 종료 콜백 (옵션)
    ///
    /// 드래그가 끝날 때 호출됩니다.
    /// SceneViewModel.endGesture()를 호출하여 경계 충돌 피드백을 초기화합니다.
    let onGestureEnd: (() -> Void)?

    /// 경계면 충돌 콜백 (옵션)
    ///
    /// 드래그 중 매 프레임마다 호출되어 경계면 충돌을 감지합니다.
    /// BoundaryCollisionManager.checkCollision()으로 전달되어 시각적 피드백을 표시합니다.
    ///
    /// - Parameter ModelEntity: 충돌을 확인할 엔티티
    ///
    /// ## 호출 시점
    /// - onChanged 콜백에서 위치 업데이트 후 매 프레임 호출
    /// - clampedPosition 적용 후 호출되어 실제 화면 위치 기준 충돌 감지
    let onBoundaryCollision: ((ModelEntity) -> Void)?

    /// 이동 가능 범위
    ///
    /// 엔티티가 이동할 수 있는 3D 공간의 경계를 정의합니다.
    /// 이 범위를 벗어나면 위치가 자동으로 제한됩니다.
    let movementBounds: MovementBounds

    /// 제스처 시작 시 엔티티의 초기 위치
    ///
    /// onChanged에서 상대적 이동량을 계산하기 위해 사용됩니다.
    /// 제스처 종료 시 nil로 리셋됩니다.
    @State private var initialPosition: SIMD3<Float>? = nil

    /// 엔티티가 내려갈 수 있는 최소 Y 좌표
    ///
    /// 엔티티의 높이를 고려하여 바닥에 닿지 않도록 계산됩니다.
    /// 계산식: floorYOffset + (entityHeight / 3.0)
    /// - floorYOffset: 바닥의 Y 좌표
    /// - entityHeight / 3.0: 엔티티 하단이 바닥에 닿는 지점
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
                                
                                let bounds = getOriginalEntityBounds(modelEntity, relativeTo: currentEntity.parent)
                                let entityHeight = bounds.extents.y  // 전체 높이
                                let adjustedHeight = entityHeight / 3.0  // 높이의 3분의 1
                                minY = SceneConstants.floorYOffset + adjustedHeight  // 중심점이 최소 adjustedHeight 이상이어야 하단이 y=0에 닿음
                            }
                        }
                        
                        // 부모(rootEntity)의 회전을 반영하기 위해 parent 좌표계로 변환
                        guard let parent = currentEntity.parent else { return }
                        
                        let movement = value.convert(value.translation3D, from: .global, to: parent)
                        let newPosition = (initialPosition ?? .zero) + movement
                        
                        // 위치를 영역 내로 제한
                        var clampedPosition = movementBounds.clamp(newPosition)
                        clampedPosition.y = max(minY, clampedPosition.y)
                        currentEntity.position = clampedPosition

                        // 경계면 충돌 확인 및 시각적 피드백
                        //
                        // 매 프레임마다 엔티티가 경계면에 닿았는지 확인하고,
                        // 충돌 시 BoundaryCollisionManager를 통해 Glow 효과를 표시합니다.
                        //
                        // 동작:
                        // 1. 드래그 중인 엔티티를 콜백으로 전달
                        // 2. BoundaryCollisionManager가 충돌 감지
                        // 3. 충돌한 벽면에 Glow 효과 적용
                        // 4. 충돌 해제 시 효과 자동 제거
                        //
                        // 주의: clampedPosition 적용 후 호출해야
                        // 실제 화면에 표시되는 위치 기준으로 충돌 감지
                        if let modelEntity = selectedEntity {
                            onBoundaryCollision?(modelEntity)
                        }

                        onGestureUpdated?()
                        
                    }
                    .onEnded { value in
                        guard let uuid = UUID(uuidString: value.entity.name) else {
                            #if DEBUG
                            print("❌ Entity name을 UUID로 변환 실패")
                            #endif
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
        onGestureUpdated: (() -> Void)?,
        onGestureEnd: (() -> Void)?,
        onBoundaryCollision: ((ModelEntity) -> Void)? = nil,
        movementBounds: MovementBounds = .default
    ) -> some View {
        self.modifier(EntityDragGesture(
            selectedEntity: selectedEntity,
            onPositionUpdate: onPositionUpdate,
            onRotationUpdate: onRotationUpdate,
            onGestureStart: onGestureStart,
            onGestureUpdated: onGestureUpdated,
            onGestureEnd: onGestureEnd,
            onBoundaryCollision: onBoundaryCollision,
            movementBounds: movementBounds
        ))
    }
}
