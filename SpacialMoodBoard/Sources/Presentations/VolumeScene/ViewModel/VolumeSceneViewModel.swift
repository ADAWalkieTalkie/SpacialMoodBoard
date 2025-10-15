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
  
  private(set) var scenes: [UUID: VolumeScene] = [:]
  private(set) var activeProjectID: UUID?
  
  var currentScene: VolumeScene? {
    guard let activeProjectID else { return nil }
    return scenes[activeProjectID]
  }
  
  var rotationAngle: Float = 0
  
  func createScene(projectID: UUID, roomType: RoomType, groundSize: GroundSize) {
    let scene = VolumeScene(groundSize: groundSize, roomType: roomType)
    scenes[projectID] = scene
  }
  
  func activateScene(for projectID: UUID) {
    activeProjectID = projectID
  }
  
  func rotateScene(by angle: Float) {
    rotationAngle += angle
  }
  
  func deleteScene(for projectID: UUID) {
    scenes.removeValue(forKey: projectID)
    if activeProjectID == projectID {
      activeProjectID = nil
    }
  }
  
  func makeEntities(for scene: VolumeScene) -> Entity {
    let meterX = Float(scene.groundSize.dimensions.x)
    let meterY = Float(scene.groundSize.dimensions.y)
    let meterZ = Float(scene.groundSize.dimensions.z)
    
    let root = Entity()
    
    let floorThickness: Float = 0.05
    let floorMesh = MeshResource.generateBox(size: [meterX, floorThickness, meterZ], cornerRadius: 0)
    let floorMaterial = SimpleMaterial(color: .gray, isMetallic: false)
    let floor = ModelEntity(mesh: floorMesh, materials: [floorMaterial])
    floor.position = [0, -floorThickness/2, 0]
    floor.name = "floor"
    root.addChild(floor)
    
    if scene.roomType == .indoor {
      let wallThickness: Float = 0.05
      let wallHeight: Float = max(meterY, 2.5)
      
      let frontBackMesh = MeshResource.generateBox(size: [meterX, wallHeight, wallThickness])
      
      let frontWall = ModelEntity(mesh: frontBackMesh, materials: [createWallMaterial()])
      frontWall.position = [0, wallHeight/2, meterZ/2 - wallThickness/2]
      frontWall.name = "frontWall"
      root.addChild(frontWall)
      
      let backWall = ModelEntity(mesh: frontBackMesh, materials: [createWallMaterial()])
      backWall.position = [0, wallHeight/2, -meterZ/2 + wallThickness/2]
      backWall.name = "backWall"
      root.addChild(backWall)
      
      let leftRightMesh = MeshResource.generateBox(size: [wallThickness, wallHeight, meterZ])
      
      let leftWall = ModelEntity(mesh: leftRightMesh, materials: [createWallMaterial()])
      leftWall.position = [-meterX/2 + wallThickness/2, wallHeight/2, 0]
      leftWall.name = "leftWall"
      root.addChild(leftWall)
      
      let rightWall = ModelEntity(mesh: leftRightMesh, materials: [createWallMaterial()])
      rightWall.position = [meterX/2 - wallThickness/2, wallHeight/2, 0]
      rightWall.name = "rightWall"
      root.addChild(rightWall)
    }
    
    return root
  }
  
  private func createWallMaterial() -> SimpleMaterial {
    var material = SimpleMaterial()
    material.color = .init(tint: .white.withAlphaComponent(0.9))
    material.metallic = .init(floatLiteral: 0.0)
    material.roughness = .init(floatLiteral: 0.8)
    return material
  }
  
  @MainActor
  func updateWallOpacity(root: Entity, cameraPosition: SIMD3<Float>) {
    guard let scene = currentScene, scene.roomType == .indoor else { return }
    
    let worldTransform = root.transform
    let localCameraPos = cameraPosition - worldTransform.translation
    
    let inverseRotation = simd_inverse(simd_quatf(angle: -rotationAngle, axis: [0, 1, 0]))
    let rotatedCameraPos = inverseRotation.act(localCameraPos)
    
    let meterX = Float(scene.groundSize.dimensions.x)
    let meterZ = Float(scene.groundSize.dimensions.z)
    
    let distToFront = abs(rotatedCameraPos.z - meterZ/2)
    let distToBack = abs(rotatedCameraPos.z + meterZ/2)
    let distToLeft = abs(rotatedCameraPos.x + meterX/2)
    let distToRight = abs(rotatedCameraPos.x - meterX/2)
    
    let distances = [
      ("frontWall", distToFront),
      ("backWall", distToBack),
      ("leftWall", distToLeft),
      ("rightWall", distToRight)
    ].sorted { $0.1 < $1.1 }
    
    let closestWalls = Set([distances[0].0, distances[1].0])
    
    for child in root.children {
      if let modelEntity = child as? ModelEntity {
        let wallName = child.name
        
        if ["frontWall", "backWall", "leftWall", "rightWall"].contains(wallName) {
          let targetOpacity: Float = closestWalls.contains(wallName) ? 0.2 : 0.9
          
          var material = SimpleMaterial()
          material.color = .init(tint: .white.withAlphaComponent(CGFloat(targetOpacity)))
          material.metallic = .init(floatLiteral: 0.0)
          material.roughness = .init(floatLiteral: 0.8)
          modelEntity.model?.materials = [material]
        }
      }
    }
  }
}
