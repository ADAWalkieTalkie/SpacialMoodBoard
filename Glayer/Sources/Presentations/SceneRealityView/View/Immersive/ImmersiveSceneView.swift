import SwiftUI
import RealityKit

struct ImmersiveSceneView: View {
    @Environment(AppStateManager.self) private var appStateManager
    @Environment(\.openWindow) private var openWindow
    
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
            // Volume으로 전환 중이 아닐 때만 reset 호출
            // Volume이 이미 열려있으면 엔티티를 재사용해야 하므로 reset 건너뜀
            if !appStateManager.appState.isVolumeOpen {
                viewModel.reset()
            }
        }
    }
}
