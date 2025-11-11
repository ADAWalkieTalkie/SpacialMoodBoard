//
//  FloorEntityBuilder.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/19/25.
//

import Foundation
import RealityKit
import SwiftUI

/// 3D 공간의 바닥(Floor) Entity를 생성하는 Builder 클래스
///
/// 커스텀 이미지 텍스처 또는 기본 머티리얼을 사용하여 바닥을 생성합니다.
/// 이미지가 있으면 불투명(opacity 1.0), 없으면 반투명(opacity 0.5)으로 렌더링됩니다.
class FloorEntity {
    // MARK: - Constants

    /// 바닥의 기본 크기 (1m x 1m)
    static let defaultFloorSize = SIMD2<Float>(x: 1.0, y: 1.0)

    /// 바닥의 기본 위치
    static let defaultFloorPosition = SIMD3<Float>(x: 0, y: 0, z: 0)

    /// 휴먼 스케일 오브젝트 기본 크기
    static let defaultHumanScaleSize = SIMD2<Float>(x: 0.11, y: 0.22)

    // MARK: - Initialization

    nonisolated init() {}

    // MARK: - floor 생성

    /// 바닥 Entity를 생성합니다
    /// - Parameter materialImageURL: 바닥 텍스처로 사용할 이미지 URL (nil이면 기본 머티리얼 사용)
    /// - Returns: "floorRoot" 이름의 바닥 ModelEntity (HumanScale 오브젝트 포함)
    @MainActor
    static func create(
        materialImageURL: URL?
    ) async -> ModelEntity {

        let floor = await createFloor(
            size: Self.defaultFloorSize,
            position: Self.defaultFloorPosition,
            materialImageURL: materialImageURL
        )

        floor.name = "floorRoot"

        let humanScaleEntity = await FloorEntity.createHumanScaleObject(size: defaultHumanScaleSize)
        humanScaleEntity.name = "humanScaleEntity"

        floor.addChild(humanScaleEntity)

        return floor
    }

    // MARK: - Private Methods - 바닥 생성

    /// 바닥 ModelEntity를 생성합니다 (내부 헬퍼 메서드)
    /// - Parameters:
    ///   - size: 바닥 크기
    ///   - position: 바닥 위치
    ///   - materialImageURL: 텍스처 이미지 URL (nil이면 기본 머티리얼)
    @MainActor
    static private func createFloor(size: SIMD2<Float>, position: SIMD3<Float>, materialImageURL: URL?)
        async -> ModelEntity
    {
        let material: PhysicallyBasedMaterial

        if let imageURL = materialImageURL {
            do {
                let texture = try await TextureResource(contentsOf: imageURL)
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

        return floor
    }

    // MARK: - 머티리얼 생성

    /// PBR 머티리얼을 생성합니다
    /// - Parameter texture: 텍스처 리소스 (nil이면 흰색 사용)
    /// - Returns: PhysicallyBasedMaterial (metallic: 0.0, roughness: 0.8)
    @MainActor
    static func createMaterial(texture: TextureResource? = nil)
        -> PhysicallyBasedMaterial
    {
        var material = PhysicallyBasedMaterial()

        if let texture {
            material.baseColor = .init(texture: .init(texture))
            material.blending = .transparent(opacity: 1.0)
        } else {
            material.baseColor.tint = .init(.white)
            material.blending = .transparent(opacity: 0.5)
        }

        material.metallic = 0.0
        material.roughness = 0.8

        return material
    }
    
    // MARK: - Human Scale Entity 생성

    /// 휴먼 스케일 가이드 Entity를 생성합니다
    /// - Parameter size: 스케일 가이드 크기
    /// - Returns: HumanScaleGuide10 이미지를 사용한 ModelEntity
    @MainActor
    static func createHumanScaleObject(size: SIMD2<Float>) async -> ModelEntity {
        var material = PhysicallyBasedMaterial()

        do {
            if let uiImage = UIImage(named: "img_humanScaleGuide"),
               let cgImage = uiImage.cgImage {
                let texture = try await TextureResource(image: cgImage, options: .init(semantic: .color))

                material.baseColor = .init(texture: .init(texture))
                material.emissiveColor = .init(texture: .init(texture))
                material.emissiveIntensity = 10.0
                material.metallic = .init(floatLiteral: 0.0)
                material.roughness = .init(floatLiteral: 0.8)
                material.faceCulling = .none
                material.blending = .transparent(opacity: .init(texture: .init(texture)))
                material.opacityThreshold = 0.3
            } else {
                print("HumanScale Load 실패: Asset Catalog에서 이미지를 찾을 수 없습니다")
            }
        } catch {
            print("HumanScale Load 실패: \(error)")
            print(error.localizedDescription)
        }
        
        let humanScaleEntity = ModelEntity(
                mesh: .generatePlane(width: size.x, height: size.y),
                materials: [material]
            )

        humanScaleEntity.position = [0, (size.y / 2.55) , 0]

        return humanScaleEntity
    }
}
