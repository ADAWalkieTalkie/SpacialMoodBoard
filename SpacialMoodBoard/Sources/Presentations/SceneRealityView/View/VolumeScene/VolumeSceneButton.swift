import SwiftUI

struct VolumeSceneButton: View {
    @Environment(AppStateManager.self) private var appModel

    let onRotate: () -> Void
    let viewModel: SceneViewModel

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 12) {
            if case .projectList = appModel.appState {
                Button {
                    appModel.closeProject()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            } else {
                Button {
                    guard !isAnimating else { return }
                    isAnimating = true
                    onRotate()
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 400_000_000)
                        isAnimating = false
                    }
                } label: {
                    Image(systemName: "rotate.right")
                        .font(.title2)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .opacity(isAnimating ? 0.5 : 1.0)
                .padding(.horizontal)

                ToolBarAttachment(viewModel: viewModel)
                    .environment(appModel)
            }
        }
        .padding(.bottom, 20)
    }
}
