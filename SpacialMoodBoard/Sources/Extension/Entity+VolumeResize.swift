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

    @MainActor
    func volumeResize(
        _ realityViewContent: RealityViewContent,
        _ geometryProxy3D: GeometryProxy3D,
        _ defaultVolumeSize: Size3D = Size3D(width: 1.0, height: 1.0, depth: 1.0)
    ) {
        let scaledVolumeContentBoundingBox = realityViewContent.convert(
            geometryProxy3D.frame(in: .local),
            from: .local, to: .scene
        )

        let scaleX = scaledVolumeContentBoundingBox.extents.x / Float(defaultVolumeSize.width)
        let scaleY = scaledVolumeContentBoundingBox.extents.y / Float(defaultVolumeSize.height)
        let scaleZ = scaledVolumeContentBoundingBox.extents.z / Float(defaultVolumeSize.depth)

        let newScale: SIMD3<Float> = [scaleX, scaleY, scaleZ]
        self.scale = newScale
    }
}
