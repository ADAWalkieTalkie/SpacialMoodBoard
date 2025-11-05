import SwiftUI
import RealityKit

// MARK: - Entity Selection Gesture

struct EntitySelectionGesture: ViewModifier {
    @Binding var selectedEntity: ModelEntity?
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                // Entity 선택 - 탭 Gesture
                SpatialTapGesture()
                    .targetedToEntity(where: .has(InputTargetComponent.self))
                    .onEnded { value in
                        selectEntityTemporarily(value.entity, selectedEntity: $selectedEntity)
                    }
            )
            // 현재로는 빈칸을 selectedEntity가 nil이 되어도 아무 일도 일어나지 못함.
            // .gesture(
            //     // 선택 해제 - 빈 공간 탭 Gesture
            //     SpatialTapGesture()
            //         .onEnded { _ in
            //             if selectedEntity != nil {
            //                 selectedEntity = nil
            //                 print("🔄 선택 해제 (빈 공간 탭)")
            //             }
            //         }
            // )
    }
}

// MARK: - View Extension
extension View {
    func entitySelectionGesture(selectedEntity: Binding<ModelEntity?>) -> some View {
        self.modifier(EntitySelectionGesture(selectedEntity: selectedEntity))
    }
}