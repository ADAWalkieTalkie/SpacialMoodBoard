//
//  VolumeResize.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/29/25.
//
import RealityKit
import RealityKitContent
import SwiftUI

extension Entity {

    /// Volume 윈도우의 크기 변경에 따라 Entity의 스케일을 자동으로 조정합니다.
    ///
    /// 이 메서드는 사용자가 Volume 윈도우의 크기를 조정할 때,
    /// 윈도우 내부의 3D 콘텐츠가 비례적으로 크기를 조정하도록 합니다.
    /// 기본 Volume 크기와 현재 Volume 크기의 비율을 계산하여 Entity의 scale을 설정합니다.
    ///
    /// - Parameters:
    ///   - realityViewContent: RealityView의 콘텐츠. 좌표계 변환에 사용됩니다.
    ///   - geometryProxy3D: Volume 윈도우의 3D geometry 정보를 제공하는 proxy
    ///   - defaultVolumeSize: 기준이 되는 기본 Volume 크기. 기본값은 1.0m x 1.0m x 1.0m
    ///   - baseScale: 동적 스케일 전에 적용할 기본 스케일. 기본값은 1.0
    ///
    /// - Note: 이 메서드는 반드시 Main Actor에서 호출되어야 합니다.
    ///
    /// ## 동작 원리
    /// 1. geometryProxy3D의 로컬 프레임을 씬 좌표계로 변환
    /// 2. 변환된 bounding box의 각 축(x, y, z) 크기를 기본 Volume 크기로 나누어 스케일 비율 계산
    /// 3. 계산된 비율에 baseScale을 곱하여 최종 스케일 계산
    /// 4. 최종 스케일을 Entity의 scale 속성에 적용
    ///
    /// ## 사용 예시
    /// ```swift
    /// RealityView { content in
    ///     // ...
    /// } update: { content, attachments in
    ///     rootEntity.volumeResize(content, proxy, baseScale: 0.2)
    /// }
    /// .modifier(GeometryModifier3D())
    /// ```
    @MainActor
    func volumeResize(
        _ realityViewContent: RealityViewContent,
        _ geometryProxy3D: GeometryProxy3D,
        _ defaultVolumeSize: Size3D = Size3D(width: 1.0, height: 1.0, depth: 1.0),
        baseScale: Float = 1.0
    ) {
        // Volume 윈도우의 로컬 프레임을 씬 좌표계로 변환
        let scaledVolumeContentBoundingBox = realityViewContent.convert(
            geometryProxy3D.frame(in: .local),
            from: .local, to: .scene
        )

        // 각 축별로 현재 크기 / 기본 크기 비율 계산
        let scaleX = scaledVolumeContentBoundingBox.extents.x / Float(defaultVolumeSize.width)
        let scaleY = scaledVolumeContentBoundingBox.extents.y / Float(defaultVolumeSize.height)
        let scaleZ = scaledVolumeContentBoundingBox.extents.z / Float(defaultVolumeSize.depth)

        // 계산된 스케일에 baseScale을 곱하여 최종 스케일 계산
        let newScale: SIMD3<Float> = [scaleX * baseScale, scaleY * baseScale, scaleZ * baseScale]
        self.scale = newScale
    }
}
