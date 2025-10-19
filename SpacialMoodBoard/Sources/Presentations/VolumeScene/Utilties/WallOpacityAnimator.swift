//
//  WallOpacityAnimator.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/19/25.
//

import Foundation
import RealityKit
import SwiftUI

/// Wall의 Opacity 애니메이션을 관리하는 클래스
final class WallOpacityAnimator {
  
  // MARK: - Constants
  
  private static let wallNames: Set<String> = ["leftWall", "rightWall", "frontWall", "backWall"]
  private static let animationDuration: TimeInterval = 0.3
  private static let animationSteps: Int = 30
  
  // MARK: - Properties
  
  private var wallOpacities: [String: Float] = [:]
  private var animationTasks: [String: Task<Void, Never>] = [:]
  
  // MARK: - Initialization
  
  nonisolated init() {}
  
  // MARK: - Public Methods
  
  @MainActor
  func applyInitialOpacity(to rootEntity: Entity, rotationAngle: Float) {
    let transparentWalls = getTransparentWalls(for: rotationAngle)
    
    for child in rootEntity.children {
      guard let modelEntity = child as? ModelEntity,
            Self.wallNames.contains(child.name) else {
        continue
      }
      
      let targetOpacity: Float = transparentWalls.contains(child.name) ? 0.0 : 1.0
      wallOpacities[child.name] = targetOpacity
      updateMaterialOpacity(for: modelEntity, opacity: targetOpacity)
    }
  }
  
  @MainActor
  func animateOpacity(for rootEntity: Entity, rotationAngle: Float) {
    let transparentWalls = getTransparentWalls(for: rotationAngle)
    
    for child in rootEntity.children {
      guard let modelEntity = child as? ModelEntity,
            Self.wallNames.contains(child.name) else {
        continue
      }
      
      let targetOpacity: Float = transparentWalls.contains(child.name) ? 0.0 : 1.0
      animateOpacity(
        for: modelEntity,
        to: targetOpacity,
        duration: Self.animationDuration
      )
    }
  }
  
  func cancelAllAnimations() {
    for (_, task) in animationTasks {
      task.cancel()
    }
    animationTasks.removeAll()
  }
  
  func reset() {
    cancelAllAnimations()
    wallOpacities.removeAll()
  }
  
  // MARK: - Private Methods - Transparency Logic
  
  private func getTransparentWalls(for angle: Float) -> Set<String> {
    var normalizedAngle = angle.truncatingRemainder(dividingBy: .pi * 2)
    if normalizedAngle < 0 {
      normalizedAngle += .pi * 2
    }
    
    let segment = Int(normalizedAngle / (.pi / 2)) % 4
    
    switch segment {
    case 0:
      return ["frontWall", "leftWall"]
    case 1:
      return ["leftWall", "backWall"]
    case 2:
      return ["backWall", "rightWall"]
    case 3:
      return ["rightWall", "frontWall"]
    default:
      return ["frontWall", "leftWall"]
    }
  }
  
  // MARK: - Private Methods - Animation
  
  @MainActor
  private func animateOpacity(
    for entity: ModelEntity,
    to targetOpacity: Float,
    duration: TimeInterval
  ) {
    let wallName = entity.name
    
    // 기존 애니메이션 취소
    animationTasks[wallName]?.cancel()
    
    let currentOpacity = wallOpacities[wallName] ?? 1.0
    
    // 변화가 거의 없으면 skip
    guard abs(currentOpacity - targetOpacity) >= 0.01 else {
      return
    }
    
    let task = Task {
      let stepDuration = duration / Double(Self.animationSteps)
      
      for step in 0...Self.animationSteps {
        if Task.isCancelled { break }
        
        let progress = Float(step) / Float(Self.animationSteps)
        let easedProgress = easeInOutQuad(progress)
        let newOpacity = currentOpacity + (targetOpacity - currentOpacity) * easedProgress
        
        wallOpacities[wallName] = newOpacity
        updateMaterialOpacity(for: entity, opacity: newOpacity)
        
        if step < Self.animationSteps {
          try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
      }
      
      // 최종값 보장
      wallOpacities[wallName] = targetOpacity
      updateMaterialOpacity(for: entity, opacity: targetOpacity)
      
      animationTasks.removeValue(forKey: wallName)
    }
    
    animationTasks[wallName] = task
  }
  
  // MARK: - Private Methods - Easing
  
  private func easeInOutQuad(_ t: Float) -> Float {
    if t < 0.5 {
      return 2 * t * t
    } else {
      return 1 - pow(-2 * t + 2, 2) / 2
    }
  }
  
  // MARK: - Private Methods - Material Update
  
  @MainActor
  private func updateMaterialOpacity(for entity: ModelEntity, opacity: Float) {
    var material = PhysicallyBasedMaterial()
    material.baseColor.tint = .init(.gray)
    material.metallic = 0.0
    material.roughness = 0.8
    
    if opacity < 1.0 {
      material.blending = .transparent(opacity: .init(floatLiteral: opacity))
      material.opacityThreshold = 0.0
    } else {
      material.blending = .transparent(opacity: 1.0)
    }
    
    entity.model?.materials = [material]
  }
}
