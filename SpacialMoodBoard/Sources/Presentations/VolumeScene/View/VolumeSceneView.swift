//
//  VolumeSceneView.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/14/25.
//

import SwiftUI
import RealityKit

struct VolumeSceneView: View {
  @Environment(VolumeSceneViewModel.self) private var sceneVM
  @Environment(ProjectListViewModel.self) private var projectVM
  
  @State private var isAnimating = false
  
  var body: some View {
    ZStack(alignment: .bottom) {
      RealityView { content in
        setupScene(content: content)
      }
      .id(sceneVM.activeProjectID)
      
      rotationButtonView()
    }
    .preferredWindowClippingMargins(.all, 400)
    .onDisappear {
      sceneVM.resetScene()
    }
  }
  
  // volume 회전 버튼
  private func rotationButtonView() -> some View {
    VStack {
      Button {
        guard !isAnimating else { return }
        isAnimating = true
        sceneVM.rotateBy90Degrees()
        
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
      .padding()
    }
  }
  
  // MARK: - Setup Scene
  
  private func setupScene(content: RealityViewContent) {
    guard let activeProjectID = sceneVM.activeProjectID else {
      print("⚠️ No active project")
      return
    }
    
    guard let project = projectVM.projects.first(where: { $0.id == activeProjectID }) else {
      print("⚠️ Project not found: \(activeProjectID)")
      return
    }
    
    guard let scene = project.volumeScene else {
      print("⚠️ VolumeScene not found in project")
      return
    }
    
    guard let root = sceneVM.getOrCreateEntity(for: project) else {
      print("⚠️ Failed to create root entity")
      return
    }
    
    content.add(root)
    
    sceneVM.alignRootToWindowBottom(
      root: root,
      windowHeight: 1.0,
      padding: 0.1
    )
    
    sceneVM.applyCurrentOpacity(to: root)
  }
}

#Preview {
  VolumeSceneView()
    .environment(ProjectListViewModel())
    .environment(VolumeSceneViewModel())
}
