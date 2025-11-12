import SwiftUI
import RealityKit

struct ImmersiveSceneView: View {
    @Environment(AppStateManager.self) private var appStateManager

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
        .onInactive {
            appStateManager.openVolume()
        }
        .onDisappear {
            viewModel.reset()
        }
    }
}
