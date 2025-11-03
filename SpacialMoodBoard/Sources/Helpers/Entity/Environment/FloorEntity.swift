//
//  FloorEntityBuilder.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/19/25.
//

import Foundation
import RealityKit
import SwiftUI

/// Entity 생성을 전담하는 Builder 클래스
class FloorEntity {
    // MARK: - Constants
    static let defaultFloorSize = SIMD2<Float>(x: 1.0, y: 1.0)
    static let defaultFloorPosition = SIMD3<Float>(x: 0, y: 0, z: 0)

    // MARK: - Initialization

    nonisolated init() {}

    // MARK: - floor 생성

    @MainActor
    static func create(
        materialImageURL: URL?
    ) -> ModelEntity {

        let floor = createFloor(
            size: Self.defaultFloorSize,
            position: Self.defaultFloorPosition,
            materialImageURL: materialImageURL
        )

        floor.name = "floorRoot"

        return floor
    }

    // MARK: - Private Methods - 바닥 생성

    @MainActor
    static private func createFloor(size: SIMD2<Float>, position: SIMD3<Float>, materialImageURL: URL?)
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

        // Floor 위치 설정
        floor.position = position

        // Floor 투명도 설정
        floor.components[OpacityComponent.self] = .init(opacity: 0.3)

        return floor
    }

    // MARK: - 머티리얼 생성
    @MainActor
    static func createMaterial(texture: TextureResource? = nil)
        -> PhysicallyBasedMaterial
    {
        var material = PhysicallyBasedMaterial()
        if let texture {
            material.baseColor = .init(texture: .init(texture))
        } else {
            material.baseColor.tint = .init(.white)
        }

        material.metallic = 0.0
        material.roughness = 0.8
        return material
    }
}
