import RealityKit
import UIKit

/// 경계 벽면 관련 상수
enum BoundaryWallConstants {
    static let emissiveIntensity: Float = 2.0
    static let collisionDepth: Float = 0.01
}

/// 이동 범위 경계면에 표시되는 벽면 엔티티 생성
enum BoundaryWallEntity {

    /// 충돌 피드백 이미지 텍스처 (싱글톤 캐시)
    private static var collisionTexture: TextureResource?
    private static var textureLoadFailed = false

    /// 5개의 경계 벽면을 생성 (좌우상전후, 바닥 제외)
    /// - Parameter bounds: 이동 범위
    /// - Returns: 컨테이너 Entity와 벽면 딕셔너리 튜플
    static func createWalls(for bounds: MovementBounds) -> (container: Entity, walls: [String: ModelEntity]) {
        let container = Entity()
        container.name = "BoundaryWalls"

        let halfSize = (bounds.maxX - bounds.minX) / 2.0

        var wallDict: [String: ModelEntity] = [:]

        // 5개 벽면 생성 (바닥 제외)
        let wallConfigs: [(name: String, width: Float, height: Float, position: SIMD3<Float>, rotation: simd_quatf)] = [
            // 좌우 벽 (YZ 평면)
            ("left", halfSize * 2, halfSize * 2, SIMD3<Float>(bounds.minX, 0, 0),
             simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 1, 0))),
            ("right", halfSize * 2, halfSize * 2, SIMD3<Float>(bounds.maxX, 0, 0),
             simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(0, 1, 0))),

            // 상단 벽 (XZ 평면) - 바닥면은 시각적 피드백 제외
            ("top", halfSize * 2, halfSize * 2, SIMD3<Float>(0, bounds.maxY, 0),
             simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))),

            // 전후 벽 (XY 평면)
            ("front", halfSize * 2, halfSize * 2, SIMD3<Float>(0, 0, bounds.minZ),
             simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))),
            ("back", halfSize * 2, halfSize * 2, SIMD3<Float>(0, 0, bounds.maxZ),
             simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0)))
        ]

        for config in wallConfigs {
            let wall = createWall(
                width: config.width,
                height: config.height,
                position: config.position,
                rotation: config.rotation,
                name: config.name
            )
            container.addChild(wall)
            wallDict[config.name] = wall
        }

        return (container, wallDict)
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

        // 기본적으로 숨김 상태 (충돌 시에만 보임)
        wall.isEnabled = false

        // 충돌 감지를 위한 컴포넌트 추가
        wall.components.set(CollisionComponent(shapes: [
            .generateBox(width: width, height: height, depth: BoundaryWallConstants.collisionDepth)
        ]))

        return wall
    }

    /// 벽면에 충돌 피드백 효과 적용
    /// - Parameter wall: 벽면 엔티티
    static func applyGlowEffect(to wall: ModelEntity) {
        #if DEBUG
        print("🎨 [BoundaryWall] applyGlowEffect 시작 - wall: \(wall.name)")
        #endif

        // 이전에 로드 실패했으면 재시도하지 않음
        guard !textureLoadFailed else { return }

        // 캐시된 텍스처가 없으면 한 번만 로드
        if collisionTexture == nil {
            guard let uiImage = UIImage(named: "img_collisionFeedback"),
                  let cgImage = uiImage.cgImage,
                  let texture = try? TextureResource(image: cgImage, options: .init(semantic: .color)) else {
                textureLoadFailed = true
                #if DEBUG
                print("❌ [BoundaryWall] 충돌 피드백 텍스처 로드 실패")
                #endif
                return
            }
            collisionTexture = texture
        }

        guard let texture = collisionTexture else { return }

        guard wall.model != nil else {
            #if DEBUG
            print("❌ [BoundaryWall] wall.model이 nil")
            #endif
            return
        }

        // Glow material 적용
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(texture: .init(texture))
        material.emissiveColor = .init(texture: .init(texture))
        material.emissiveIntensity = BoundaryWallConstants.emissiveIntensity
        material.blending = .transparent(opacity: 1.0)
        material.faceCulling = .none

        wall.model?.materials = [material]
        // 벽면을 보이게 설정
        wall.isEnabled = true
    }

}
