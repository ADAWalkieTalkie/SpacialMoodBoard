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
  @State private var lastOpacityUpdate: Date = .distantPast
  
  private let opacityUpdateInterval: TimeInterval = 0.2
  
  @State private var isAnimating = false
  
  var body: some View {
    ZStack(alignment: .bottom) {
      RealityView { content in
        setupScene(content: content)
      } update: { [sceneVM, projectVM] content in
        updateScene(content: content, sceneVM: sceneVM, projectVM: projectVM)
      }
      .id(sceneVM.activeProjectID)
      // 제스처 실 기기에서 테스트(예정)
      .gesture(
        DragGesture(minimumDistance: 0.001, coordinateSpace: .local)
          .targetedToAnyEntity()
          .onChanged { value in
            let deltaX = Float(value.translation.width)
            let rotationDelta = deltaX * 0.01
            sceneVM.rotateScene(by: rotationDelta)
          }
      )
      rotationButtonView()
    }
    .preferredWindowClippingMargins(.all, 400)
  }
  
  // volume 회전 버튼(임시)
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
      windowHeight: 1.0,  // default 1m 높이 Volume
      padding: 0.2        // 2cm 여백
    )
  }
  
  // MARK: - Update Scene
  
  private func updateScene(
    content: RealityViewContent,
    sceneVM: VolumeSceneViewModel,
    projectVM: ProjectListViewModel
  ) {
    guard let root = content.entities.first(where: { $0.name == "roomRoot" }) else {
      return
    }
    
    guard let activeProjectID = sceneVM.activeProjectID else {
      return
    }
    
    guard let project = projectVM.projects.first(where: { $0.id == activeProjectID }) else {
      return
    }
    
    guard let scene = project.volumeScene else {
      return
    }
    
    let duration: TimeInterval = isAnimating ? 0.3 : 0
    sceneVM.applyRotation(to: root, angle: sceneVM.rotationAngle, duration: duration)
  }
}

#Preview {
  VolumeSceneView()
    .environment(ProjectListViewModel())
    .environment(VolumeSceneViewModel())
}
