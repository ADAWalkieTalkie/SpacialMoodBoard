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
  
  var body: some View {
    RealityView { content in
      setupScene(content: content)
    } update: { [sceneVM, projectVM] content in
      updateScene(content: content, sceneVM: sceneVM, projectVM: projectVM)
    }
    .id(sceneVM.activeProjectID)
    .gesture(
      DragGesture(minimumDistance: 0.001, coordinateSpace: .local)
        .targetedToAnyEntity()
        .onChanged { value in
          let deltaX = Float(value.translation.width)
          let rotationDelta = deltaX * 0.01
          sceneVM.rotateScene(by: rotationDelta)
        }
    )
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
      padding: 0.02       // 2cm 여백
    )
  }
  
  // MARK: - Update Scene
  
  private func updateScene(
    content: RealityViewContent,
    sceneVM: VolumeSceneViewModel,
    projectVM: ProjectListViewModel
  ) {
    // Find root entity by name (now properly set in makeEntities)
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
  }
}

#Preview {
  VolumeSceneView()
    .environment(ProjectListViewModel())
    .environment(VolumeSceneViewModel())
}
