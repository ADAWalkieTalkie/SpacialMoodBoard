import RealityKit
import UIKit

/// 경계 벽면 관련 상수
///
/// 벽면 생성 및 시각적 효과에 사용되는 상수값들을 중앙에서 관리합니다.
enum BoundaryWallConstants {
    /// Glow 효과의 발광 강도
    ///
    /// emissiveIntensity 값이 높을수록 벽면이 더 밝게 빛남.
    /// 기본값 2.0은 사용자에게 충분히 눈에 띄면서도 눈부시지 않은 수준.
    static let emissiveIntensity: Float = 2.0

    /// 충돌 감지용 CollisionComponent의 깊이
    ///
    /// 벽면은 평면(Plane)이므로 실제 깊이가 없지만,
    /// 충돌 감지를 위해 매우 얇은 박스 형태의 CollisionComponent를 생성함.
    /// 0.01m = 1cm (너무 얇으면 충돌 감지 실패 가능성)
    static let collisionDepth: Float = 0.01
}

/// 이동 범위 경계면에 표시되는 벽면 엔티티 생성 및 관리
///
/// 정적 팩토리 메서드 패턴을 사용하여 경계 벽면 엔티티를 생성하고
/// Glow 효과를 적용하는 유틸리티 enum입니다.
///
/// ## 주요 기능
/// 1. **벽면 생성**: `createWalls(for:)` - 5개의 투명 벽면 엔티티 생성
/// 2. **효과 적용**: `applyGlowEffect(to:)` - 충돌 시 Glow 효과 적용
///
/// ## 설계 패턴
/// - **Enum 네임스페이스**: 인스턴스 생성 방지, 정적 메서드만 제공
/// - **싱글톤 텍스처 캐싱**: 한 번 로드한 텍스처를 재사용하여 성능 최적화
/// - **팩토리 메서드**: 복잡한 엔티티 생성 로직을 캡슐화
///
/// ## 성능 최적화
/// - 텍스처 싱글톤 캐싱: 앱 전체에서 하나의 텍스처만 사용
/// - 로드 실패 플래그: 실패 시 재시도하지 않아 불필요한 작업 방지
/// - 반환값 개선: 딕셔너리를 함께 반환하여 O(1) 조회 성능
///
/// ## 사용 예시
/// ```swift
/// let (container, wallDict) = BoundaryWallEntity.createWalls(for: bounds)
/// parent.addChild(container)
///
/// // 충돌 시
/// if let leftWall = wallDict["left"] {
///     BoundaryWallEntity.applyGlowEffect(to: leftWall)
/// }
/// ```
enum BoundaryWallEntity {

    /// 충돌 피드백 이미지 텍스처 (싱글톤 캐시)
    ///
    /// "img_collisionFeedback" 이미지를 한 번만 로드하여 재사용.
    /// 여러 벽면이 동시에 표시되어도 하나의 텍스처만 메모리에 유지됨.
    private static var collisionTexture: TextureResource?

    /// 텍스처 로드 실패 플래그
    ///
    /// 한 번 로드에 실패하면 true로 설정되어 이후 재시도하지 않음.
    /// 앱 실행 중 반복적인 로드 실패 로그를 방지.
    private static var textureLoadFailed = false

    /// 5개의 경계 벽면을 생성 (좌우상전후, 바닥 제외)
    ///
    /// 지정된 이동 범위에 맞춰 5개의 투명한 평면 벽면을 생성하고,
    /// 컨테이너 Entity와 빠른 접근을 위한 딕셔너리를 함께 반환합니다.
    ///
    /// - Parameter bounds: 이동 가능 범위 (3D 공간의 경계)
    /// - Returns: (컨테이너 Entity, 방향별 벽면 딕셔너리) 튜플
    ///   - container: 5개 벽면을 담은 루트 Entity ("BoundaryWalls")
    ///   - walls: 방향(String) → ModelEntity 매핑 딕셔너리
    ///
    /// ## 생성되는 벽면
    /// - **좌측 (left)**: YZ 평면, X = minX
    /// - **우측 (right)**: YZ 평면, X = maxX
    /// - **상단 (top)**: XZ 평면, Y = maxY
    /// - **전면 (front)**: XY 평면, Z = minZ
    /// - **후면 (back)**: XY 평면, Z = maxZ
    /// - **바닥**: 제외 (사용자가 바닥 기준으로 배치)
    ///
    /// ## 벽면 속성
    /// - 크기: bounds 크기에 맞춰 자동 계산
    /// - Material: 완전 투명 (opacity: 0.0)
    /// - 기본 상태: 숨김 (isEnabled: false)
    /// - 이름 규칙: "boundaryWall_{방향}"
    /// - CollisionComponent: 포함 (충돌 감지용)
    ///
    /// ## 반환값
    /// ```swift
    /// let (container, walls) = createWalls(for: bounds)
    /// // container: 5개 벽면의 부모 Entity
    /// // walls: ["left": leftWall, "right": rightWall, ...]
    /// ```
    ///
    /// ## 성능
    /// - 벽면 조회: O(1) - 딕셔너리 사용
    /// - 메모리: 5개 평면 엔티티 + 텍스처(지연 로드)
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
    ///
    /// 지정된 크기, 위치, 회전으로 투명한 평면 벽면 엔티티를 생성합니다.
    /// 기본적으로 완전히 투명하고 숨김 상태이며, 충돌 시에만 Glow 효과와 함께 표시됩니다.
    ///
    /// - Parameters:
    ///   - width: 벽면의 너비 (미터 단위)
    ///   - height: 벽면의 높이 (미터 단위)
    ///   - position: 벽면의 3D 공간 위치 (부모 좌표계 기준)
    ///   - rotation: 벽면의 회전 (Quaternion)
    ///   - name: 벽면의 방향 이름 ("left", "right", etc.)
    /// - Returns: 생성된 ModelEntity
    ///
    /// ## 엔티티 구성
    /// 1. **Mesh**: Plane (width × height)
    /// 2. **Material**: PhysicallyBasedMaterial
    ///    - 완전 투명 (opacity: 0.0)
    ///    - 양면 렌더링 (faceCulling: .none)
    /// 3. **CollisionComponent**: 얇은 박스 (깊이: 0.01m)
    /// 4. **초기 상태**: 숨김 (isEnabled: false)
    ///
    /// ## 이름 규칙
    /// 엔티티 이름: "boundaryWall_{name}"
    /// - 예: "boundaryWall_left", "boundaryWall_top"
    ///
    /// ## Material 설정 이유
    /// - **완전 투명**: 평소에는 보이지 않음
    /// - **faceCulling: none**: 벽면의 양쪽에서 모두 보임
    /// - **blending**: 텍스처 적용 시 부드러운 전환
    ///
    /// ## CollisionComponent 깊이
    /// 평면은 2D지만 충돌 감지를 위해 3D 박스 필요.
    /// 0.01m = 1cm 깊이로 얇은 박스 생성.
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
    ///
    /// 충돌이 감지된 벽면에 빛나는 Glow 효과를 적용합니다.
    /// 텍스처는 싱글톤으로 캐싱되어 한 번만 로드됩니다.
    ///
    /// - Parameter wall: Glow 효과를 적용할 벽면 엔티티
    ///
    /// ## 동작 과정
    /// 1. **로드 실패 체크**: 이전에 실패했으면 재시도 안 함
    /// 2. **텍스처 로드**: 캐시에 없으면 "img_collisionFeedback" 로드
    /// 3. **Material 생성**: PhysicallyBasedMaterial with Glow
    ///    - baseColor: 텍스처 적용
    ///    - emissiveColor: 텍스처 적용 (발광)
    ///    - emissiveIntensity: 2.0 (밝기)
    ///    - blending: 완전 불투명 (opacity: 1.0)
    /// 4. **엔티티 표시**: isEnabled = true
    ///
    /// ## Glow 효과 구현
    /// Glow 효과는 `emissiveColor`와 `emissiveIntensity`를 통해 구현됩니다:
    /// - **emissiveColor**: 텍스처를 발광색으로 사용
    /// - **emissiveIntensity**: 발광 강도 (2.0 = 2배)
    /// - **baseColor + emissive**: 기본색과 발광색 조합
    ///
    /// ## 텍스처 캐싱
    /// ```
    /// 첫 번째 호출: UIImage 로드 → TextureResource 생성 → 캐시 저장
    /// 이후 호출: 캐시에서 즉시 반환 (로딩 없음)
    /// ```
    ///
    /// ## 성능
    /// - 첫 로드: ~10-50ms (이미지 디코딩 포함)
    /// - 캐시 히트: ~1ms 미만
    /// - 메모리: 텍스처 1개만 유지 (모든 벽면이 공유)
    ///
    /// ## 에러 처리
    /// - UIImage 로드 실패 → textureLoadFailed = true, 이후 재시도 안 함
    /// - wall.model이 nil → 경고 로그, 조용히 종료
    ///
    /// ## 주의사항
    /// - UIKit 의존성: UIImage 사용 (visionOS에서도 사용 가능)
    /// - MainActor: UI 작업이므로 메인 스레드에서 실행 필요
    /// - 디버그 로그: #if DEBUG로 프로덕션 빌드에서 제거됨
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
