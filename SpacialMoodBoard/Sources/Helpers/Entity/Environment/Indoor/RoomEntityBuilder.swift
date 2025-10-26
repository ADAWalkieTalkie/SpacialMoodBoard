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
        let dimensions = calculateDimensions(from: environment.groundSize)

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

    // MARK: - Private Methods - Dimensions

    private func calculateDimensions(from groundSize: GroundSize) -> SIMD3<
        Float
    > {
        let dimensions = groundSize.dimensions
        return SIMD3<Float>(
            Float(dimensions.x),
            Float(dimensions.y),
            Float(dimensions.z)
        )
    }

    // MARK: - Private Methods - Floor

    @MainActor
    private func createFloor(width: Float, depth: Float, materialImageURL: URL?) -> ModelEntity {
        let material: PhysicallyBasedMaterial

        if let imageURL = materialImageURL,
           let texture = try? TextureResource.load(contentsOf: imageURL) {
            print("✅ Floor texture loaded: \(imageURL.lastPathComponent)")
            material = createTextureMaterial(
                texture: texture,
                floorWidth: width,
                floorDepth: depth
            )
        } else {
            if materialImageURL != nil {
                print("❌ Failed to load floor texture from URL")
            }
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
    private func createTextureMaterial(
        texture: TextureResource,
        floorWidth: Float,
        floorDepth: Float
    ) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()

        // Texture를 baseColor에 적용
        // RealityKit은 기본적으로 texture를 0-1 UV 범위에 매핑하며
        // 이미지가 floor 전체를 덮도록 자동으로 스트레치됩니다
        material.baseColor = .init(texture: .init(texture))
        material.metallic = 0.0
        material.roughness = 0.8

        print("📐 Floor dimensions: \(floorWidth) x \(floorDepth)")
        print("🖼️ Texture dimensions: \(texture.width) x \(texture.height)")

        return material
    }

    // MARK: - Private Methods - Transform

    @MainActor
    private func applyRotation(to entity: Entity, angle: Float) {
        let rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
        entity.transform.rotation = rotation
    }
}
