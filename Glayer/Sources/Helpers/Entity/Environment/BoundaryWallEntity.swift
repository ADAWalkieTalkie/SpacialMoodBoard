import RealityKit
import UIKit

/// 이동 범위 경계면에 표시되는 벽면 엔티티 생성
enum BoundaryWallEntity {

    /// 6개의 경계 벽면을 생성 (상하좌우전후)
    /// - Parameter bounds: 이동 범위
    /// - Returns: 6개의 벽면 엔티티를 담은 Entity
    static func createWalls(for bounds: MovementBounds) -> Entity {
        let container = Entity()
        container.name = "BoundaryWalls"

        let halfSize = (bounds.maxX - bounds.minX) / 2.0

        // 6개 벽면 생성
        let walls = [
            // 좌우 벽 (YZ 평면)
            createWall(width: halfSize * 2, height: halfSize * 2,
                      position: SIMD3<Float>(bounds.minX, 0, 0),
                      rotation: simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 1, 0)),
                      name: "left"),
            createWall(width: halfSize * 2, height: halfSize * 2,
                      position: SIMD3<Float>(bounds.maxX, 0, 0),
                      rotation: simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(0, 1, 0)),
                      name: "right"),

            // 상하 벽 (XZ 평면)
            createWall(width: halfSize * 2, height: halfSize * 2,
                      position: SIMD3<Float>(0, bounds.minY, 0),
                      rotation: simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0)),
                      name: "bottom"),
            createWall(width: halfSize * 2, height: halfSize * 2,
                      position: SIMD3<Float>(0, bounds.maxY, 0),
                      rotation: simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0)),
                      name: "top"),

            // 전후 벽 (XY 평면)
            createWall(width: halfSize * 2, height: halfSize * 2,
                      position: SIMD3<Float>(0, 0, bounds.minZ),
                      rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0)),
                      name: "front"),
            createWall(width: halfSize * 2, height: halfSize * 2,
                      position: SIMD3<Float>(0, 0, bounds.maxZ),
                      rotation: simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0)),
                      name: "back")
        ]

        walls.forEach { container.addChild($0) }

        return container
    }

    /// 개별 벽면 엔티티 생성
    private static func createWall(
        width: Float,
        height: Float,
        position: SIMD3<Float>,
        rotation: simd_quatf,
        name: String
    ) -> ModelEntity {
        let mesh = MeshResource.generatePlane(width: width, height: height)

        // 투명한 기본 material
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .clear)
        material.blending = .transparent(opacity: 0.0)
        material.faceCulling = .none

        let wall = ModelEntity(mesh: mesh, materials: [material])
        wall.name = "boundaryWall_\(name)"
        wall.position = position
        wall.orientation = rotation

        // 충돌 감지를 위한 컴포넌트 추가
        wall.components.set(CollisionComponent(shapes: [
            .generateBox(width: width, height: height, depth: 0.01)
        ]))

        return wall
    }

    /// 벽면에 충돌 피드백 효과 적용
    /// - Parameters:
    ///   - wall: 벽면 엔티티
    ///   - intensity: 효과 강도 (0.0 ~ 1.0)
    static func applyGlowEffect(to wall: ModelEntity, intensity: Float = 1.0) {
        // Assets에서 img_collisionFeedback 이미지 로드
        guard let uiImage = UIImage(named: "img_collisionFeedback"),
              let cgImage = uiImage.cgImage,
              let texture = try? TextureResource(image: cgImage, options: .init(semantic: .color))
        else {
            print("⚠️ img_collisionFeedback 이미지를 로드할 수 없습니다.")
            return
        }

        // Glow material 적용
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(texture: .init(texture))
        material.emissiveColor = .init(texture: .init(texture))
        material.emissiveIntensity = 2.0 * intensity
        material.blending = .transparent(opacity: 1.0)
        material.faceCulling = .none

        wall.model?.materials = [material]
    }

}
