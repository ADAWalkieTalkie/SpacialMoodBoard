import SwiftUI
import RealityKit

struct VolumeSceneView: View {
    @State private var viewModel: SceneViewModel
    @Environment(AppModel.self) private var appModel
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
                .onAppear {
                    viewModel.resetRotation()
                }
                .onDisappear {
                    viewModel.reset()
                }
            }
            VStack {
                Spacer()
                VolumeSceneButton(
                    onRotate: { viewModel.rotateBy90Degrees() }
                )
            }
            .zIndex(1)
        }
    }
}
