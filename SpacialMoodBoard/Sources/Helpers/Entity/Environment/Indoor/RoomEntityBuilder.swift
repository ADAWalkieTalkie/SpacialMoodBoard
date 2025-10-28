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

    private static let floorThickness: Float = 0.01

    // MARK: - Initialization

    nonisolated init() {}

    // MARK: - Public Methods

    @MainActor
    func buildRoomEntity(
        from environment: SpacialEnvironment,
        rotationAngle: Float
    ) -> Entity {
        let dimensions = SIMD3<Float>(Float(10), Float(4), Float(10))

        let room = Entity()
        room.name = "roomRoot"

        let floor = createFloor(
            width: dimensions.x,
            depth: dimensions.z,
            materialImageURL: environment.floorMaterialImageURL
        )
        room.addChild(floor)

        applyRotation(to: room, angle: rotationAngle)

        return room
    }

    // MARK: - Private Methods - Floor

    @MainActor
    private func createFloor(width: Float, depth: Float, materialImageURL: URL?)
        -> ModelEntity
    {
        let material: PhysicallyBasedMaterial

        if let imageURL = materialImageURL {
            do {
                let texture = try TextureResource.load(contentsOf: imageURL)
                material = createTextureMaterial(texture: texture)
            } catch {
                print("❌ Floor 텍스처 로드 실패 (\(imageURL.lastPathComponent)): \(error.localizedDescription)")
                material = createBaseMaterial()
            }
        } else {
            material = createBaseMaterial()
        }

        let floor = ModelEntity(
            mesh: .generateBox(size: 1),
            materials: [material]
        )
        floor.scale = .init(x: width, y: Self.floorThickness, z: depth)
        floor.position = .init(x: 0, y: Self.floorThickness, z: 0)
        floor.name = "floor"

        return floor
    }

    // MARK: - Private Methods - Material

    private func createBaseMaterial() -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .init(.gray)
        material.metallic = 0.0
        material.roughness = 0.8
        return material
    }

    @MainActor
    private func createTextureMaterial(texture: TextureResource)
        -> PhysicallyBasedMaterial
    {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(texture: .init(texture))
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
