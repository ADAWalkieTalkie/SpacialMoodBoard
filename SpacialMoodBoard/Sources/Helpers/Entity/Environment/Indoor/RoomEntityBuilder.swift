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

    // MARK: - Constants

    private static let scaleFactor: Float = 15
    private static let wallThickness: Float = 0.01
    private static let floorThickness: Float = 0.01

    // MARK: - Initialization

    nonisolated init() {}

    // MARK: - Public Methods

    @MainActor
    func buildRoomEntity(
        from environment: SpacialEnvironment,
        rotationAngle: Float
    ) -> Entity {
        let dimensions = calculateDimensions(from: environment.groundSize)

        let room = Entity()
        room.name = "roomRoot"

        let floor = createFloor(width: dimensions.x, depth: dimensions.z)
        room.addChild(floor)

        if environment.roomType == .indoor {
            let walls = createWalls(
                width: dimensions.x,
                height: dimensions.y,
                depth: dimensions.z
            )
            walls.forEach { room.addChild($0) }
        }

        applyRotation(to: room, angle: rotationAngle)

        return room
    }

    // MARK: - Private Methods - Dimensions

    private func calculateDimensions(from groundSize: GroundSize) -> SIMD3<
        Float
    > {
        let dimensions = groundSize.dimensions
        return SIMD3<Float>(
            Float(dimensions.x) / Self.scaleFactor,
            Float(dimensions.y) / Self.scaleFactor,
            Float(dimensions.z) / Self.scaleFactor
        )
    }

    // MARK: - Private Methods - Floor

    @MainActor
    private func createFloor(width: Float, depth: Float) -> ModelEntity {
        let material = createBaseMaterial()

        let floor = ModelEntity(
            mesh: .generateBox(size: 1),
            materials: [material]
        )
        floor.scale = .init(x: width, y: Self.floorThickness, z: depth)
        floor.position = .init(x: 0, y: Self.floorThickness, z: 0)
        floor.name = "floor"

        return floor
    }

    // MARK: - Private Methods - Walls

    @MainActor
    private func createWalls(width: Float, height: Float, depth: Float)
        -> [ModelEntity]
    {
        let halfHeight = height / 2
        let halfWidth = width / 2
        let halfDepth = depth / 2
        let halfThickness = Self.wallThickness / 2

        let wallConfigs:
            [(name: String, scale: SIMD3<Float>, position: SIMD3<Float>)] = [
                (
                    name: "frontWall",
                    scale: [width, height, Self.wallThickness],
                    position: [0, halfHeight, halfDepth - halfThickness]
                ),
                (
                    name: "backWall",
                    scale: [width, height, Self.wallThickness],
                    position: [0, halfHeight, -halfDepth + halfThickness]
                ),
                (
                    name: "leftWall",
                    scale: [Self.wallThickness, height, depth],
                    position: [-halfWidth + halfThickness, halfHeight, 0]
                ),
                (
                    name: "rightWall",
                    scale: [Self.wallThickness, height, depth],
                    position: [halfWidth - halfThickness, halfHeight, 0]
                ),
            ]

        return wallConfigs.map { config in
            createWall(
                name: config.name,
                scale: config.scale,
                position: config.position
            )
        }
    }

    @MainActor
    private func createWall(
        name: String,
        scale: SIMD3<Float>,
        position: SIMD3<Float>
    ) -> ModelEntity {
        var material = createBaseMaterial()
        material.blending = .transparent(opacity: 1.0)

        let wall = ModelEntity(
            mesh: .generateBox(size: 1),
            materials: [material]
        )
        wall.scale = scale
        wall.position = position
        wall.name = name

        return wall
    }

    // MARK: - Private Methods - Material

    private func createBaseMaterial() -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .init(.gray)
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
