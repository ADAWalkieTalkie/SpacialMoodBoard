//
//  FloorEntityBuilder.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/19/25.
//

import Foundation
import RealityKit
import SwiftUI

/// # FloorEntity
///
/// 3D 공간 무드보드의 바닥(Floor) Entity를 생성하는 Builder 클래스입니다.
///
/// ## 개요
/// `FloorEntity`는 RealityKit의 ModelEntity를 사용하여 3D 씬의 바닥면을 생성합니다.
/// 사용자가 업로드한 이미지를 텍스처로 사용하거나, 기본 흰색 머티리얼을 적용할 수 있습니다.
///
/// ## 주요 기능
/// - 커스텀 이미지 텍스처를 사용한 바닥 생성
/// - 기본 머티리얼(흰색)을 사용한 바닥 생성
/// - 바닥 투명도 설정 (기본값: 0.3)
/// - PBR(Physically Based Rendering) 머티리얼 적용
///
/// ## 사용 예시
/// ```swift
/// // 이미지가 있는 바닥 생성
/// let floorWithImage = FloorEntity.create(materialImageURL: imageURL)
///
/// // 기본 바닥 생성
/// let defaultFloor = FloorEntity.create(materialImageURL: nil)
/// ```
///
/// ## 기술적 세부사항
/// - **크기**: 기본 1.0m x 1.0m (defaultFloorSize)
/// - **위치**: 원점 (0, 0, 0)
/// - **투명도**: 0.3 (OpacityComponent)
/// - **머티리얼**: PhysicallyBasedMaterial
///   - Metallic: 0.0 (비금속)
///   - Roughness: 0.8 (거친 표면)
///
/// ## 아키텍처 내 역할
/// `FloorEntity`는 `RoomEntityBuilder`에 의해 사용되며, 3D 씬의 환경을 구성하는 핵심 요소입니다.
/// Volume 모드와 Immersive 모드 모두에서 공간의 기준면 역할을 합니다.
///
/// ## 주의사항
/// - 모든 메서드는 `@MainActor`에서 실행되어야 합니다 (RealityKit 요구사항)
/// - 이미지 로드 실패 시 자동으로 기본 머티리얼로 폴백됩니다
/// - 바닥은 항상 "floorRoot"라는 이름을 가집니다
class FloorEntity {
    // MARK: - Constants

    /// 바닥의 기본 크기 (1m x 1m)
    /// - Note: x는 너비(width), y는 깊이(depth)를 의미합니다
    static let defaultFloorSize = SIMD2<Float>(x: 1.0, y: 1.0)

    /// 바닥의 기본 위치 (원점)
    /// - Note: 3D 공간의 중심에 배치됩니다
    static let defaultFloorPosition = SIMD3<Float>(x: 0, y: 0, z: 0)

    // MARK: - Initialization

    /// 초기화 메서드
    /// - Note: 이 클래스는 주로 static 메서드를 사용하므로 인스턴스화가 불필요합니다
    nonisolated init() {}

    // MARK: - floor 생성

    /// 바닥 Entity를 생성합니다
    ///
    /// 이 메서드는 바닥의 전체 생성 프로세스를 관리하는 메인 팩토리 메서드입니다.
    /// 제공된 이미지 URL을 사용하여 텍스처를 적용하거나, nil인 경우 기본 머티리얼을 사용합니다.
    ///
    /// - Parameter materialImageURL: 바닥에 적용할 이미지의 URL (옵셔널)
    ///   - nil인 경우: 기본 흰색 머티리얼 사용
    ///   - URL이 제공된 경우: 해당 이미지를 텍스처로 로드하여 적용
    ///
    /// - Returns: 설정이 완료된 바닥 ModelEntity
    ///   - name: "floorRoot"
    ///   - size: defaultFloorSize (1m x 1m)
    ///   - position: defaultFloorPosition (0, 0, 0)
    ///   - opacity: 0.3
    ///
    /// - Note: 이미지 로드에 실패하면 자동으로 기본 머티리얼로 폴백됩니다
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

    /// 실제 바닥 Entity를 생성하고 설정하는 내부 메서드
    ///
    /// 이 메서드는 바닥의 물리적 속성을 설정하고 머티리얼을 적용합니다.
    ///
    /// - Parameters:
    ///   - size: 바닥의 크기 (너비 x 깊이)
    ///   - position: 바닥의 3D 공간 상 위치
    ///   - materialImageURL: 텍스처로 사용할 이미지 URL (옵셔널)
    ///
    /// - Returns: 설정이 완료된 ModelEntity
    ///
    /// - Note: 투명도는 항상 0.3으로 고정되어 약간 투명한 바닥을 제공합니다
    @MainActor
    static private func createFloor(size: SIMD2<Float>, position: SIMD3<Float>, materialImageURL: URL?)
        -> ModelEntity
    {
        let material: PhysicallyBasedMaterial

        // 머티리얼 생성: 이미지 텍스처 또는 기본 머티리얼
        if let imageURL = materialImageURL {
            do {
                let texture = try TextureResource.load(contentsOf: imageURL)
                material = createMaterial(texture: texture)
            } catch {
                // 이미지 로드 실패 시 기본 머티리얼 사용
                material = createMaterial()
            }
        } else {
            material = createMaterial()
        }

        // Plane 메시로 바닥 Entity 생성
        let floor = ModelEntity(
            mesh: .generatePlane(width: size.x, depth: size.y),
            materials: [material]
        )

        // Floor 위치 설정
        floor.position = position

        // Floor 투명도 설정 (0.3 = 30% 투명)
        floor.components[OpacityComponent.self] = .init(opacity: 0.3)

        return floor
    }

    // MARK: - 머티리얼 생성

    /// PBR(Physically Based Rendering) 머티리얼을 생성합니다
    ///
    /// 이 메서드는 바닥의 시각적 속성을 정의하는 머티리얼을 생성합니다.
    /// 텍스처가 제공되면 이를 적용하고, 그렇지 않으면 흰색 색조를 사용합니다.
    ///
    /// - Parameter texture: 바닥에 적용할 텍스처 리소스 (옵셔널)
    ///   - nil인 경우: 흰색 색조 적용
    ///   - 제공된 경우: 해당 텍스처를 baseColor로 사용
    ///
    /// - Returns: 설정이 완료된 PhysicallyBasedMaterial
    ///
    /// - Note: 거친 비금속 표면 설정은 바닥이 자연스럽고 부드러운 외관을 가지도록 합니다
    @MainActor
    static func createMaterial(texture: TextureResource? = nil)
        -> PhysicallyBasedMaterial
    {
        var material = PhysicallyBasedMaterial()

        // 베이스 컬러 설정: 텍스처 또는 흰색
        if let texture {
            material.baseColor = .init(texture: .init(texture))
        } else {
            material.baseColor.tint = .init(.white)
        }

        // 비금속 재질로 설정 (나무, 천, 플라스틱 등)
        material.metallic = 0.0

        // 거친 표면으로 설정 (자연스러운 확산 반사)
        material.roughness = 0.8

        return material
    }
}
