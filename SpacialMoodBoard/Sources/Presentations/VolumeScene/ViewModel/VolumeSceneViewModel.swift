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
    
    private let appModel: AppModel
    private let projectRepository: ProjectRepository
    private let entityBuilder: RoomEntityBuilder
    private let opacityAnimator: WallOpacityAnimator
    
    // MARK: - State
    
    private var cachedEntities: [UUID: Entity] = [:]
    
    var rotationAngle: Float = .pi / 4
    
    // MARK: - Initialization
    
    init(
        appModel: AppModel,
        projectRepository: ProjectRepository,
        entityBuilder: RoomEntityBuilder = RoomEntityBuilder(),
        opacityAnimator: WallOpacityAnimator = WallOpacityAnimator()
    ) {
        self.appModel = appModel
        self.projectRepository = projectRepository
        self.entityBuilder = entityBuilder
        self.opacityAnimator = opacityAnimator
    }
    
    // MARK: - Active Project Management
    
    func getActiveProjectID() -> UUID? {
        return appModel.selectedProject?.id
    }
    
    func activateScene(for project: Project?) {
        guard let project else {
        appModel.selectedProject = nil
        return
        }
        
        if appModel.selectedProject?.id != project.id {
        appModel.selectedProject = project
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
        
        return getOrCreateEntity()
    }
    
    private func getActiveProject() -> Project? {
        guard let activeProject = appModel.selectedProject else {
        return nil
        }
        return projectRepository.fetchProject(activeProject)
    }
    
    // MARK: - Scene Control
    
    func resetScene() {
        guard let activeProject = appModel.selectedProject,
            let rootEntity = cachedEntities[activeProject.id] else {
        return
        }
        
        opacityAnimator.cancelAllAnimations()
        rotationAngle = .pi / 4
        
        applyRotation(to: rootEntity, angle: rotationAngle, animated: false)
        opacityAnimator.applyInitialOpacity(to: rootEntity, rotationAngle: rotationAngle)
    }
    
    func rotateBy90Degrees() {
        rotationAngle += .pi / 2
        
        guard let activeProject = appModel.selectedProject,
            let rootEntity = cachedEntities[activeProject.id] else {
        return
        }
        
        applyRotation(to: rootEntity, angle: rotationAngle, animated: true)
        opacityAnimator.animateOpacity(for: rootEntity, rotationAngle: rotationAngle)
    }
    
    func applyCurrentOpacity(to rootEntity: Entity) {
        opacityAnimator.applyInitialOpacity(to: rootEntity, rotationAngle: rotationAngle)
    }
    
    // MARK: - Entity Management
    
    func getOrCreateEntity() -> Entity? {
    guard let scene = appModel.selectedScene else {
      print("[VolumeVM] getOrCreateEntity - ⚠️ Volume not found: \(appModel.selectedProject?.id ?? UUID())")
      return nil
    }
    
        let entity = entityBuilder.buildRoomEntity(from: scene.spacialEnvironment, rotationAngle: rotationAngle)

        return entity
    }
    
    func deleteEntityCache(for project: Project) {
        opacityAnimator.reset()
        cachedEntities.removeValue(forKey: project.id)
        
        if appModel.selectedProject?.id == project.id {
        appModel.selectedProject = nil
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
