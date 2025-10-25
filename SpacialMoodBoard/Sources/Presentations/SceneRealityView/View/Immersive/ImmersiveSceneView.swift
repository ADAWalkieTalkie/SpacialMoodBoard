import SwiftUI
import RealityKit

struct ImmersiveSceneView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @State private var viewModel: SceneViewModel
    
    init(viewModel: SceneViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        // SceneRealityView가 모든 것을 처리 (Head-anchored Toolbar 포함)
        SceneRealityView(
            viewModel: $viewModel,
            config: .immersive
        )
        .onAppear {
            appModel.immersiveSpaceState = .open
            dismissWindow(id: "ImmersiveVolumeWindow")
        }
        .onDisappear {
            appModel.immersiveSpaceState = .closed
            viewModel.reset()
            openWindow(id: "ImmersiveVolumeWindow")
        }
    }
}