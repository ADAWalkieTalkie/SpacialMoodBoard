import SwiftUI
import RealityKit

struct VolumeSceneView: View {
    @State private var viewModel: SceneViewModel
  
    init(viewModel: SceneViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }
  
    var body: some View {
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
}
