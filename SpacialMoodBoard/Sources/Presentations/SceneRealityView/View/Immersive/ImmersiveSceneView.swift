import SwiftUI
import RealityKit

struct ImmersiveSceneView: View {
  @Environment(AppModel.self) private var appModel
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissWindow) private var dismissWindow 

  @State private var viewModel: SceneViewModel
  @State private var showMinimap: Bool = true
  
  init(viewModel: SceneViewModel) {
    _viewModel = State(wrappedValue: viewModel)
  }
  
  var body: some View {
    ZStack {
      // 메인 Immersive Scene
      SceneRealityView(
        viewModel: $viewModel,
        config: .immersive
      )
      
      // 좌측 상단: 미니맵
      if showMinimap {
        VStack {
          HStack {
            // minimapView
            //   .frame(width: 300, height: 300)
            //   .padding()
            // Spacer()
          }
          Spacer()
        }
      }
    }
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
  
  // MARK: - Minimap
  
  private var minimapView: some View {
    VStack(spacing: 0) {
      // 미니맵 헤더
      HStack {
        Text("Map")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        Button {
          showMinimap.toggle()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
      }
      .padding(8)
      .background(.ultraThinMaterial)
      
      // 미니맵 Scene (동일한 Core 사용!)
      SceneRealityView(
        viewModel: $viewModel,
        config: .minimap
      )
      .frame(height: 260)
      .background(.black.opacity(0.3))
    }
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .shadow(radius: 10)
  }
}