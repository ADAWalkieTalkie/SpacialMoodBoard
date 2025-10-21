// //
// //  VolumeSceneView.swift
// //  SpacialMoodBoard
// //
// //  Created by PenguinLand on 10/14/25.
// //

// import SwiftUI
// import RealityKit

// struct VolumeSceneView: View {
//   @State private var viewModel: VolumeSceneViewModel
//   @State private var isAnimating = false
  
//   init(viewModel: VolumeSceneViewModel) {
//     _viewModel = State(wrappedValue: viewModel)
//   }
  
//   var body: some View {
//     ZStack(alignment: .bottom) {
//       RealityView { content in
//         setupScene(content: content)
//       }
//       .id(viewModel.getActiveProjectID())
      
//       rotationButton
//     }
//     .preferredWindowClippingMargins(.all, 400)
//     .onDisappear {
//       viewModel.resetScene()
//     }
//   }
  
//   // MARK: - volume 회전 버튼
//   private var rotationButton: some View {
//     VStack {
//       Button {
//         guard !isAnimating else { return }
//         isAnimating = true
//         viewModel.rotateBy90Degrees()
        
//         Task {
//           try? await Task.sleep(nanoseconds: 400_000_000)
//           isAnimating = false
//         }
//       } label: {
//         Image(systemName: "rotate.right")
//           .font(.title2)
//           .padding(12)
//           .background(.ultraThinMaterial)
//           .clipShape(Circle())
//       }
//       .buttonStyle(.plain)
//       .opacity(isAnimating ? 0.5 : 1.0)
//       .padding()
//     }
//   }
  
//   // MARK: - Setup Scene
  
//   private func setupScene(content: RealityViewContent) {
//     guard let root = viewModel.getActiveRootEntity() else {
//       print("활성화된 프로젝트가 없습니다.")
//       return
//     }
    
//     content.add(root)
    
//     viewModel.alignRootToWindowBottom(
//       root: root,
//       windowHeight: 1.0,
//       padding: 0.1
//     )
//     viewModel.applyCurrentOpacity(to: root)
//   }
// }
