//
//  VolumeSceneView.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/14/25.
//

import SwiftUI
import RealityKit

struct VolumeSceneView: View {
  @Environment(VolumeSceneViewModel.self) private var viewModel
  @State private var lastOpacityUpdate: Date = .distantPast
  
  private let opacityUpdateInterval: TimeInterval = 0.2
  
  var body: some View {
    RealityView { content in
      setupScene(content: content)
    } update: { content in
      updateScene(content: content)
    }
    .id(viewModel.currentScene?.id)
    .gesture(
      DragGesture()
        .targetedToAnyEntity()
        .onChanged { value in
          let deltaX = Float(value.translation.width)
          let rotationDelta = deltaX * 0.01
          viewModel.rotateScene(by: rotationDelta)
        }
    )
  }
  
  private func setupScene(content: RealityViewContent) {
    guard let scene = viewModel.currentScene else { return }
    
    let root = viewModel.makeEntities(for: scene)
    root.name = "roomRoot"
    root.transform.rotation = simd_quatf(angle: viewModel.rotationAngle, axis: [0, 1, 0])
    
    content.add(root)
    
    if scene.roomType == .indoor {
      let estimatedCameraPosition: SIMD3<Float> = [0, 1.6, 2.0]
      viewModel.updateWallOpacity(root: root, cameraPosition: estimatedCameraPosition)
      lastOpacityUpdate = Date()
    }
  }
  
  private func updateScene(content: RealityViewContent) {
    guard let root = content.entities.first(where: { $0.name == "roomRoot" }) else {
      return
    }
    
    root.transform.rotation = simd_quatf(angle: viewModel.rotationAngle, axis: [0, 1, 0])
    
    if let scene = viewModel.currentScene, scene.roomType == .indoor {
      let now = Date()
      if now.timeIntervalSince(lastOpacityUpdate) >= opacityUpdateInterval {
        let estimatedCameraPosition: SIMD3<Float> = [0, 1.6, 2.0]
        viewModel.updateWallOpacity(root: root, cameraPosition: estimatedCameraPosition)
        lastOpacityUpdate = now
      }
    }
  }
}
