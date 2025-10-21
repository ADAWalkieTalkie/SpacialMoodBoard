import SwiftUI
import RealityKit

extension View {
    /// 모든 Entity Gesture를 한 번에 적용
    func immersiveEntityGestures(
        selectedEntity: Binding<ModelEntity?>,
        onPositionUpdate: @escaping (UUID, SIMD3<Float>) -> Void
    ) -> some View {
        self
            .simultaneousGesture(
                // Entity 선택 - 탭 Gesture
                SpatialTapGesture()
                    .targetedToEntity(where: .has(InputTargetComponent.self))
                    .onEnded { value in
                        selectedEntity.wrappedValue = value.entity as? ModelEntity
                        print("👆 탭 선택: \(value.entity.name)")
                    }
            )
            .gesture(
                // 선택 해제 - 빈 공간 탭 Gesture
                SpatialTapGesture()
                    .onEnded { _ in
                        if selectedEntity.wrappedValue != nil {
                            selectedEntity.wrappedValue = nil
                            print("🔄 선택 해제 (빈 공간 탭)")
                        }
                    }
            )
            .simultaneousGesture(
                // Entity 이동 - 드래그 Gesture
                DragGesture()
                    .targetedToEntity(where: .has(InputTargetComponent.self))
                    .onChanged { value in
                        // 드래그 중 Entity 위치 실시간 업데이트
                        value.entity.position = value.convert(
                            value.location3D,
                            from: .local,
                            to: value.entity.parent!
                        )
                    }
                    .onEnded { value in
                        // 드래그 종료 - SceneModel에 반영
                        guard let uuid = UUID(uuidString: value.entity.name) else {
                            print("❌ Entity name을 UUID로 변환 실패")
                            return
                        }
                        
                        onPositionUpdate(uuid, value.entity.position)
                        print("📍 위치 업데이트: \(uuid)")
                    }
            )
    }
}
