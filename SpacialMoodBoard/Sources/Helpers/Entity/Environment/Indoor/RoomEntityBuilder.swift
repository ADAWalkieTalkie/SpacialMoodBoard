//
//  RoomEntityBuilder.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/19/25.
//

import Foundation
import RealityKit
import SwiftUI

/// Entity 생성을 전담하는 Builder 클래스
struct RoomEntityBuilder {

    // MARK: - Initialization

    nonisolated init() {}

    // MARK: - Public Methods

    @MainActor
    func buildRoomEntity(
        from environment: SpacialEnvironment,
        rotationAngle: Float
    ) -> Entity {
        let room = Entity()
        room.name = "roomRoot"
        
        let floorSize = SIMD2<Float>(x: 1, y: 1)
        let floorPosition = SIMD3<Float>(x: 0, y: 0, z: 0)

        let floor = createFloor(
            size: floorSize,
            position: floorPosition,
            materialImageURL: environment.floorMaterialImageURL
        )
        room.addChild(floor)

        return room
    }

    // MARK: - Private Methods - Floor

    @MainActor
    private func createFloor(size: SIMD2<Float>, position: SIMD3<Float>, materialImageURL: URL?)
        -> ModelEntity
    {
        let material: PhysicallyBasedMaterial

        if let imageURL = materialImageURL {
            do {
                let texture = try TextureResource.load(contentsOf: imageURL)
                material = createMaterial(texture: texture)
            } catch {
                material = createMaterial()
            }
        } else {
            material = createMaterial()
        }
        
        let floor = ModelEntity(
            mesh: .generatePlane(width: size.x, depth: size.y),
            materials: [material]
        )
        floor.position = position
        floor.name = "floor"

        return floor
    }

    // MARK: - Private Methods - Material
    @MainActor
    private func createMaterial(texture: TextureResource? = nil)
        -> PhysicallyBasedMaterial
    {
        var material = PhysicallyBasedMaterial()
        if let texture {
            material.baseColor = .init(texture: .init(texture))
        } else {
            material.baseColor.tint = .init(.gray)
        }
        
        material.metallic = 0.0
        material.roughness = 0.8
        return material
    }

    // MARK: - Private Methods - Transform

    @MainActor
    private func applyRotation(to entity: Entity, angle: Float) {
        let rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
        entity.transform.rotation = rotation
    }
}
