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
  
  func rotateScene(by angle: Float) {
    rotationAngle += angle
  }
  
  func rotateBy90Degrees() {
    rotationAngle += .pi / 2
  }
  
  func getOrCreateEntity(for project: Project) -> Entity? {
    let projectID = project.id
    
    guard let scene = project.volumeScene else {
      print("VolumeScene 찾지지 못함 \(projectID)")
      return nil
    }
    
    if let cached = cachedEntities[projectID] {
      print("Entity 재사용: \(projectID)")
      return cached
    }
    
    print("Entity 새로 생성: \(projectID)")
    let entity = makeEntities(for: scene)
    cachedEntities[projectID] = entity
    
    return entity
  }
  
  func deleteEntityCache(for projectID: UUID) {
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
  
  // MARK: - Window하단에 Content 정렬
  func alignRootToWindowBottom(root: Entity, windowHeight: Float = 1.0, padding: Float = 0.02) {
    // root Entity의 최하단 영역 측정
    let bounds = root.visualBounds(relativeTo: root)
    let contentMinY = bounds.min.y
    
    // 윈도우의 최하단 영역 측정
    let windowBottomY = -windowHeight / 2.0
    
    // rootEntity를 하단에 배치하고 패딩 추가
    let targetContentMinY = windowBottomY + padding
    
    // rootEntity가 이동해야 할 거리 계산 후 적용
    let offsetY = targetContentMinY - contentMinY
    var t = root.transform
    t.translation.y = offsetY
    root.transform = t
  }
}
