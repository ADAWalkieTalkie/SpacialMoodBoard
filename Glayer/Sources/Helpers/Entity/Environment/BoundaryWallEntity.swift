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

    /// 벽면에 Blue Glow 효과 적용
    /// - Parameter wall: 벽면 엔티티
    static func applyGlowEffect(to wall: ModelEntity, intensity: Float = 1.0) {
        guard let mesh = wall.model?.mesh else { return }

        // 벽면 크기 계산
        let bounds = mesh.bounds
        let width = bounds.extents.x
        let height = bounds.extents.y
        
        let cornerRadius = 0.1

        // Blue glow texture 생성
        let texSize = CGSize(width: 1024, height: 1024)
        guard let texture = makeBlueGlowTexture(
            size: texSize,
            width: width,
            height: height,
            cornerRadius: cornerRadius
        ) else { return }

        // Glow material 적용
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(texture: .init(texture))
        material.emissiveColor = .init(texture: .init(texture))
        material.emissiveIntensity = 2.0 * intensity
        material.blending = .transparent(opacity: 1.0)
        material.faceCulling = .none

        wall.model?.materials = [material]
    }

    /// Blue Glow 테두리 텍스처 생성
    private static func makeBlueGlowTexture(
        size: CGSize,
        width: Float,
        height: Float,
        cornerRadius: CGFloat
    ) -> TextureResource? {
        let stroke: CGFloat = 2.0
        let glow: CGFloat = 50
        let inset = glow + stroke / 1.5

        let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
        let path = UIBezierPath(rect: rect)

        // Blue 컬러 (#0080FF)
        let blueColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            ctx.cgContext.saveGState()

            // Glow 효과 (퍼지는 느낌)
            ctx.cgContext.setShadow(
                offset: .zero,
                blur: stroke + glow * 0.6,
                color: blueColor.withAlphaComponent(0.6).cgColor
            )

            blueColor.withAlphaComponent(1.0).setStroke()
            path.lineWidth = stroke
            path.stroke()

            ctx.cgContext.restoreGState()
        }

        guard let cgImage = image.cgImage else { return nil }
        return try? TextureResource(image: cgImage, options: .init(semantic: .color))
    }
}
