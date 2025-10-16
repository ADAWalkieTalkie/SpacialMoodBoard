//
//  VolumeSceneViewModel.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/14/25.
//

import Foundation
import RealityKit
import Observation
import SwiftUI

@Observable
final class VolumeSceneViewModel {
  static let volumeWindowID = "VolumeWindow"

  private var cachedEntities: [UUID: Entity] = [:]
  private var wallOpacities: [String: Float] = [:]
  private var opacityAnimationTasks: [String: Task<Void, Never>] = [:]
  
  private(set) var scenes: [UUID: VolumeScene] = [:]
  private(set) var activeProjectID: UUID?
  
  var rotationAngle: Float = .pi / 4
  
  var currentScene: VolumeScene? {
    guard let activeProjectID else { return nil }
    return scenes[activeProjectID]
  }
  
  func activateScene(for projectID: UUID) {
    activeProjectID = projectID
    rotationAngle = .pi / 4
  }
  
  func resetScene() {
    guard let activeProjectID = activeProjectID,
          let rootEntity = cachedEntities[activeProjectID] else {
      return
    }
    
    // 진행 중인 모든 애니메이션 취소
    for (_, task) in opacityAnimationTasks {
      task.cancel()
    }
    opacityAnimationTasks.removeAll()
    
    // 회전 각도 초기화
    rotationAngle = .pi / 4
    
    // Entity 회전 즉시 초기화
    applyRotation(to: rootEntity, angle: rotationAngle, duration: 0)
    
    // Opacity 초기화 (애니메이션 없이 즉시 적용)
    applyCurrentOpacity(to: rootEntity)
  }
  
  func applyCurrentOpacity(to rootEntity: Entity) {
    // Volume이 열릴 때 현재 rotation angle에 맞는 opacity를 즉시 적용
    var normalizedAngle = rotationAngle.truncatingRemainder(dividingBy: .pi * 2)
    if normalizedAngle < 0 {
      normalizedAngle += .pi * 2
    }
    
    let segment = Int(normalizedAngle / (.pi / 2)) % 4
    let transparentWalls: Set<String>
    
    switch segment {
    case 0:
      transparentWalls = ["frontWall", "leftWall"]
    case 1:
      transparentWalls = ["leftWall", "backWall"]
    case 2:
      transparentWalls = ["backWall", "rightWall"]
    case 3:
      transparentWalls = ["rightWall", "frontWall"]
    default:
      transparentWalls = ["frontWall", "leftWall"]
    }
    
    for child in rootEntity.children {
      guard let modelEntity = child as? ModelEntity else { continue }
      
      let wallName = child.name
      if ["leftWall", "rightWall", "frontWall", "backWall"].contains(wallName) {
        let targetOpacity: Float = transparentWalls.contains(wallName) ? 0.0 : 1.0
        wallOpacities[wallName] = targetOpacity
        updateMaterialOpacity(for: modelEntity, opacity: targetOpacity)
      }
    }
  }
  
  func rotateBy90Degrees() {
    rotationAngle += .pi / 2
    
    if let activeProjectID = activeProjectID,
       let rootEntity = cachedEntities[activeProjectID] {
      applyRotation(to: rootEntity, angle: rotationAngle, duration: 0.3)
      updateWallOpacity(for: rootEntity)
    }
  }
  
  func applyRotation(to entity: Entity, angle: Float, duration: TimeInterval = 0) {
    let rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
    
    if duration > 0 {
      var transform = entity.transform
      transform.rotation = rotation
      entity.move(to: transform, relativeTo: entity.parent, duration: duration)
    } else {
      entity.transform.rotation = rotation
    }
  }
  
  func getOrCreateEntity(for project: Project) -> Entity? {
    let projectID = project.id
    
    guard let scene = project.volumeScene else {
      print("VolumeScene not found: \(projectID)")
      return nil
    }
    
    if let cached = cachedEntities[projectID] {
      print("Entity reused: \(projectID)")
      return cached
    }
    
    print("Entity created: \(projectID)")
    let entity = makeEntities(for: scene)
    cachedEntities[projectID] = entity
    
    return entity
  }
  
  func deleteEntityCache(for projectID: UUID) {
    let wallNames = ["leftWall", "rightWall", "frontWall", "backWall"]
    for wallName in wallNames {
      opacityAnimationTasks[wallName]?.cancel()
      opacityAnimationTasks.removeValue(forKey: wallName)
      wallOpacities.removeValue(forKey: wallName)
    }
    
    cachedEntities.removeValue(forKey: projectID)
    
    if activeProjectID == projectID {
      activeProjectID = nil
      rotationAngle = .pi / 4
    }
  }
  
  // MARK: - Entity 생성
  
  func makeEntities(for scene: VolumeScene) -> Entity {
    let scaleFactor: Float = 15
    
    let meterX = Float(scene.groundSize.dimensions.x) / scaleFactor
    let meterY = Float(scene.groundSize.dimensions.y) / scaleFactor
    let meterZ = Float(scene.groundSize.dimensions.z) / scaleFactor
    
    let root = Entity()
    root.name = "roomRoot"
    
    let floor = createFloor(width: meterX, depth: meterZ)
    root.addChild(floor)

    if scene.roomType == .indoor {
      let walls = createWalls(
        width: meterX,
        height: meterY,
        depth: meterZ
      )
      walls.forEach { root.addChild($0) }
    }
    
    applyRotation(to: root, angle: rotationAngle)
    
    return root
  }
  
  private func createFloor(width: Float, depth: Float) -> ModelEntity {
    var floorMaterial = PhysicallyBasedMaterial()
    floorMaterial.baseColor.tint = .init(.gray)
    floorMaterial.metallic = 0.0
    floorMaterial.roughness = 0.8
    
    let floorModel = ModelEntity(
      mesh: .generateBox(size: 1),
      materials: [floorMaterial]
    )
    floorModel.scale = .init(x: width, y: 0.01, z: depth)
    floorModel.position = .init(x: 0, y: 0.01, z: 0)
    floorModel.name = "floor"
    
    return floorModel
  }
  
  private func createWalls(width: Float, height: Float, depth: Float) -> [ModelEntity] {
    let wallThickness: Float = 0.01
    let halfHeight = height / 2
    
    var wallMaterial = PhysicallyBasedMaterial()
    wallMaterial.baseColor.tint = .init(.gray)
    wallMaterial.metallic = 0.0
    wallMaterial.roughness = 0.8
    wallMaterial.blending = .transparent(opacity: 1.0)
    
    let wallConfigs: [(String, SIMD3<Float>, SIMD3<Float>)] = [
      ("frontWall", [width, height, wallThickness], [0, halfHeight, depth/2 - wallThickness/2]),
      ("backWall", [width, height, wallThickness], [0, halfHeight, -depth/2 + wallThickness/2]),
      ("leftWall", [wallThickness, height, depth], [-width/2 + wallThickness/2, halfHeight, 0]),
      ("rightWall", [wallThickness, height, depth], [width/2 + wallThickness/2, halfHeight, 0])
    ]
    
    return wallConfigs.map { name, scale, position in
      let wall = ModelEntity(
        mesh: .generateBox(size: 1),
        materials: [wallMaterial]
      )
      wall.scale = scale
      wall.position = position
      wall.name = name
      return wall
    }
  }
  
  // MARK: - Wall Opacity 업데이트
  
  private func updateWallOpacity(for rootEntity: Entity) {
    var normalizedAngle = rotationAngle.truncatingRemainder(dividingBy: .pi * 2)
    if normalizedAngle < 0 {
      normalizedAngle += .pi * 2
    }
    
    let segment = Int(normalizedAngle / (.pi / 2)) % 4
    let transparentWalls: Set<String>
    
    switch segment {
    case 0:
      transparentWalls = ["frontWall", "leftWall"]
    case 1:
      transparentWalls = ["leftWall", "backWall"]
    case 2:
      transparentWalls = ["backWall", "rightWall"]
    case 3:
      transparentWalls = ["rightWall", "frontWall"]
    default:
      transparentWalls = ["frontWall", "leftWall"]
    }
    
    for child in rootEntity.children {
      guard let modelEntity = child as? ModelEntity else { continue }
      
      let wallName = child.name
      if ["leftWall", "rightWall", "frontWall", "backWall"].contains(wallName) {
        let targetOpacity: Float = transparentWalls.contains(wallName) ? 0.0 : 1.0
        setOpacityAnimated(for: modelEntity, targetOpacity: targetOpacity, duration: 0.3)
      }
    }
  }
  
  private func setOpacityAnimated(for entity: ModelEntity, targetOpacity: Float, duration: TimeInterval) {
    let wallName = entity.name
    
    opacityAnimationTasks[wallName]?.cancel()
    
    let currentOpacity = wallOpacities[wallName] ?? 1.0
    
    if abs(currentOpacity - targetOpacity) < 0.01 {
      return
    }
    
    let task = Task {
      let steps = 30
      let stepDuration = duration / Double(steps)
      
      for step in 0...steps {
        if Task.isCancelled { break }
        
        let progress = Float(step) / Float(steps)
        let easedProgress = easeInOutQuad(progress)
        let newOpacity = currentOpacity + (targetOpacity - currentOpacity) * easedProgress
        
        wallOpacities[wallName] = newOpacity
        updateMaterialOpacity(for: entity, opacity: newOpacity)
        
        if step < steps {
          try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
      }
      
      wallOpacities[wallName] = targetOpacity
      updateMaterialOpacity(for: entity, opacity: targetOpacity)
      
      opacityAnimationTasks.removeValue(forKey: wallName)
    }
    
    opacityAnimationTasks[wallName] = task
  }
  
  private func easeInOutQuad(_ t: Float) -> Float {
    if t < 0.5 {
      return 2 * t * t
    } else {
      return 1 - pow(-2 * t + 2, 2) / 2
    }
  }
  
  private func updateMaterialOpacity(for entity: ModelEntity, opacity: Float) {
    var newMaterial = PhysicallyBasedMaterial()
    newMaterial.baseColor.tint = .init(.gray)
    newMaterial.metallic = 0.0
    newMaterial.roughness = 0.8
    
    if opacity < 1.0 {
      newMaterial.blending = .transparent(opacity: .init(floatLiteral: opacity))
      newMaterial.opacityThreshold = 0.0
    } else {
      newMaterial.blending = .transparent(opacity: 1.0)
    }
    
    entity.model?.materials = [newMaterial]
  }
  
  // MARK: - Window 하단에 Content 정렬
  
  func alignRootToWindowBottom(root: Entity, windowHeight: Float = 1.0, padding: Float = 0.02) {
    let bounds = root.visualBounds(relativeTo: root)
    let contentMinY = bounds.min.y
    
    let windowBottomY = -windowHeight / 2.0
    let targetContentMinY = windowBottomY + padding
    
    let offsetY = targetContentMinY - contentMinY
    var t = root.transform
    t.translation.y = offsetY
    root.transform = t
  }
}
