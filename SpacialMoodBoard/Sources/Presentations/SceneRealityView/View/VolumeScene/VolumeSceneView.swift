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
            GeometryReader3D { proxy in
                SceneRealityView(
                    viewModel: $viewModel,
                    config: .volume
                )
                .onDisappear {
                    viewModel.reset()

                    // 사용자가 시스템 X 버튼으로 VolumeWindow를 닫은 경우 AppState 동기화
                    if case .libraryWithVolume = appStateManager.appState {
                        appStateManager.closeProject()
                    }
                }
            }
            VStack {
                Spacer()
                VolumeSceneButton(
                    onRotate: { viewModel.rotateBy90Degrees() },
                    viewModel: viewModel
                )
            }
            .zIndex(1)
        }
    }
}
