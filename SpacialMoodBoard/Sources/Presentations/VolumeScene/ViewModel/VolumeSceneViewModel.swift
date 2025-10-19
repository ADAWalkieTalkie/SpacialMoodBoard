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

@MainActor
@Observable
final class VolumeSceneViewModel {
  
  // MARK: - Dependencies
  
  private let sceneState: AppSceneState
  private let projectRepository: ProjectRepository
  private let entityBuilder: RoomEntityBuilder
  private let opacityAnimator: WallOpacityAnimator
  
  // MARK: - State
  
  private var cachedEntities: [UUID: Entity] = [:]
  private(set) var scenes: [UUID: VolumeScene] = [:]
  
  var rotationAngle: Float = .pi / 4
  
  // MARK: - Initialization
  
  init(
    sceneState: AppSceneState,
    projectRepository: ProjectRepository,
    entityBuilder: RoomEntityBuilder = RoomEntityBuilder(),
    opacityAnimator: WallOpacityAnimator = WallOpacityAnimator()
  ) {
    self.sceneState = sceneState
    self.projectRepository = projectRepository
    self.entityBuilder = entityBuilder
    self.opacityAnimator = opacityAnimator
  }
  
  // MARK: - Active Project Management
  
  func getActiveProjectID() -> UUID? {
    return sceneState.activeProjectID
  }
  
  func activateScene(for projectID: UUID?) {
    guard let projectID else {
      sceneState.activeProjectID = nil
      return
    }
    
    if sceneState.activeProjectID != projectID {
      sceneState.activeProjectID = projectID
      resetScene()
    }
  }
  
  func getActiveRootEntity() -> Entity? {
    guard let project = getActiveProject() else {
#if DEBUG
      print("[VolumeVM] getActiveRootEntity - ⚠️ No active project")
#endif
      return nil
    }
    
    return getOrCreateEntity(for: project)
  }
  
  private func getActiveProject() -> Project? {
    guard let activeProjectID = sceneState.activeProjectID else {
      return nil
    }
    return projectRepository.fetchProject(by: activeProjectID)
  }
  
  // MARK: - Scene Control
  
  func resetScene() {
    guard let activeProjectID = sceneState.activeProjectID,
          let rootEntity = cachedEntities[activeProjectID] else {
      return
    }
    
    opacityAnimator.cancelAllAnimations()
    rotationAngle = .pi / 4
    
    applyRotation(to: rootEntity, angle: rotationAngle, animated: false)
    opacityAnimator.applyInitialOpacity(to: rootEntity, rotationAngle: rotationAngle)
  }
  
  func rotateBy90Degrees() {
    rotationAngle += .pi / 2
    
    guard let activeProjectID = sceneState.activeProjectID,
          let rootEntity = cachedEntities[activeProjectID] else {
      return
    }
    
    applyRotation(to: rootEntity, angle: rotationAngle, animated: true)
    opacityAnimator.animateOpacity(for: rootEntity, rotationAngle: rotationAngle)
  }
  
  func applyCurrentOpacity(to rootEntity: Entity) {
    opacityAnimator.applyInitialOpacity(to: rootEntity, rotationAngle: rotationAngle)
  }
  
  // MARK: - Entity Management
  
  func getOrCreateEntity(for project: Project) -> Entity? {
    let projectID = project.id
    
    guard let scene = project.volumeScene else {
#if DEBUG
      print("[VolumeVM] getOrCreateEntity - ⚠️ VolumeScene not found: \(projectID)")
#endif
      return nil
    }
    
    if let cached = cachedEntities[projectID] {
      return cached
    }
    
    let entity = entityBuilder.buildRoomEntity(from: scene, rotationAngle: rotationAngle)
    cachedEntities[projectID] = entity
    
    return entity
  }
  
  func deleteEntityCache(for projectID: UUID) {
    opacityAnimator.reset()
    cachedEntities.removeValue(forKey: projectID)
    
    if sceneState.activeProjectID == projectID {
      sceneState.activeProjectID = nil
      rotationAngle = .pi / 4
    }
  }
  
  // MARK: - Transform Operations
  
  private func applyRotation(to entity: Entity, angle: Float, animated: Bool) {
    let rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
    
    if animated {
      var transform = entity.transform
      transform.rotation = rotation
      entity.move(to: transform, relativeTo: entity.parent, duration: 0.3)
    } else {
      entity.transform.rotation = rotation
    }
  }
  
  func alignRootToWindowBottom(
    root: Entity,
    windowHeight: Float = 1.0,
    padding: Float = 0.02
  ) {
    let bounds = root.visualBounds(relativeTo: root)
    let contentMinY = bounds.min.y
    
    let windowBottomY = -windowHeight / 2.0
    let targetContentMinY = windowBottomY + padding
    
    let offsetY = targetContentMinY - contentMinY
    var transform = root.transform
    transform.translation.y = offsetY
    root.transform = transform
  }
}
