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
                        // Entity 선택 (didSet에서 자동으로 attachment 처리)
                        if let modelEntity = value.entity as? ModelEntity {
                            selectedEntity = modelEntity
                        }
                    }
            )
//            .gesture(
//                // 선택 해제 - 빈 공간 탭 Gesture
//                SpatialTapGesture()
//                    .onEnded { _ in
//                        if selectedEntity != nil {
//                            selectedEntity = nil
//                            print("🔄 선택 해제 (빈 공간 탭)")
//                        }
//                    }
//            )
    }
}

// MARK: - View Extension
extension View {
    func entitySelectionGesture(selectedEntity: Binding<ModelEntity?>) -> some View {
        self.modifier(EntitySelectionGesture(selectedEntity: selectedEntity))
    }
}
