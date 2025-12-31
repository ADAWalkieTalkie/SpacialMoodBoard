import SwiftUI
import RealityKit

struct VolumeSceneView: View {
    @State private var viewModel: SceneViewModel
    @Environment(AppStateManager.self) private var appStateManager
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    init(viewModel: SceneViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            SceneRealityView(
                viewModel: $viewModel,
                config: .volume
            )
            .onDisappear {
                // Immersive로 전환 중이 아닐 때만 reset 호출
                // Immersive가 이미 열려있으면 엔티티를 재사용해야 하므로 reset 건너뜀
                if !appStateManager.appState.isImmersiveOpen {
                    viewModel.reset()
                }

                // 사용자가 시스템 X 버튼으로 VolumeWindow를 닫은 경우 AppState 동기화
                appStateManager.closeVolume()
            }
            VStack {
                Spacer()
                
                ToolBarAttachment(viewModel: viewModel)
                    .environment(appStateManager)
                    .zIndex(99999999)
            }
        }
        .toast(
            isPresented: $viewModel.showLoadingEntityToast,
            message: .loadingAssets
        )
    }
}
