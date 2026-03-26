//
//  FloorEntityBuilder.swift
//  Glayer
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
@MainActor
class FloorEntity {
    // MARK: - Constants

    /// 바닥의 기본 크기 (SceneConstants에서 중앙 관리)
    static var defaultFloorSize: SIMD2<Float> {
        SIMD2<Float>(x: SceneConstants.floorSize, y: SceneConstants.floorSize)
    }

    /// 바닥의 기본 위치
    static let defaultFloorPosition = SIMD3<Float>(x: 0, y: 0, z: 0)

    // MARK: - Initialization

    nonisolated init() {}

    // MARK: - floor 생성

    /// 바닥 Entity를 생성합니다
    /// - Parameter materialImageURL: 바닥 텍스처로 사용할 이미지 URL (nil이면 기본 머티리얼 사용)
    /// - Returns: "floorRoot" 이름의 바닥 ModelEntity (HumanScale 오브젝트 포함)
    static func create(
        materialImageURL: URL?
    ) async -> ModelEntity {

        let floor = await createFloor(
            size: Self.defaultFloorSize,
            position: Self.defaultFloorPosition,
            materialImageURL: materialImageURL
        )

        floor.name = "floorRoot"
        
        if materialImageURL == nil {
            applyOutline(floor: floor)
        }
        

        return floor
    }

    // MARK: - Private Methods - 바닥 생성

    /// 바닥 ModelEntity를 생성합니다 (내부 헬퍼 메서드)
    /// - Parameters:
    ///   - size: 바닥 크기
    ///   - position: 바닥 위치
    ///   - materialImageURL: 텍스처 이미지 URL (nil이면 기본 머티리얼)
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
            mesh: .generatePlane(width: size.x, depth: size.y, cornerRadius: 0.01),
            materials: [material]
        )

        floor.position = position

        return floor
    }

    // MARK: - 머티리얼 생성

    /// PBR 머티리얼을 생성합니다
    /// - Parameter texture: 텍스처 리소스 (nil이면 흰색 사용)
    /// - Returns: PhysicallyBasedMaterial (metallic: 0.0, roughness: 0.8)
    static func createMaterial(texture: TextureResource? = nil)
        -> PhysicallyBasedMaterial
    {
        var material = PhysicallyBasedMaterial()

        if let texture {
            material.baseColor = .init(texture: .init(texture))
            // 불투명 floor는 기본(opaque) 파이프라인을 사용해 depth 정합성을 유지한다.
            // transparent(opacity: 1.0)은 시각적으로는 불투명해도 정렬 이슈를 유발할 수 있다.
        } else {
            material.baseColor.tint = .init(.white)
            material.blending = .transparent(opacity: 0.5)
        }
        
        material.faceCulling = .none

        return material
    }
    
    /// Immersive 모드의 초기 floor에 사용하는 기본 머티리얼
    /// - Note: 불투명 파이프라인을 유지하고 OpacityComponent로만 투명도를 제어한다.
    static func createImmersiveInitialMaterial() -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .init(.gray)
        material.faceCulling = .none
        return material
    }
    
    static func applyOutline(floor: ModelEntity) {
        EntityBoundBoxApplier.addBoundAuto(
            to: floor
        )
    }
}
