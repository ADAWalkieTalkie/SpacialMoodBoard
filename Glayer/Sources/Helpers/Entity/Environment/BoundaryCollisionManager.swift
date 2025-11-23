import RealityKit
import Observation
import UIKit

/// 엔티티와 경계면 충돌을 감지하고 시각적 피드백을 제공하는 매니저
///
/// 이 클래스는 3D 공간에서 오브젝트가 이동 가능한 영역의 경계에 닿았을 때
/// 시각적 피드백을 제공하여 사용자에게 경계를 알립니다.
///
/// ## 주요 기능
/// - 경계 벽면 엔티티 생성 및 관리
/// - 실시간 충돌 감지 (5방향: 좌/우/상/전/후/ 바닥면만 제외)
/// - 충돌 시 Glow 효과 표시, 비충돌 시 자동 숨김
/// - 제스처 종료 시 모든 피드백 초기화
///
/// ## 사용 예시
/// ```swift
/// let manager = BoundaryCollisionManager()
/// manager.setupBoundaryWalls(in: rootEntity)
///
/// // 드래그 제스처 중
/// manager.checkCollision(for: draggedEntity)
///
/// // 제스처 종료 시
/// manager.clearCollisions()
/// ```
///
/// ## 성능 최적화
/// - 벽면 엔티티를 딕셔너리로 캐싱하여 O(1) 조회 성능
/// - 충돌 상태 변경 시에만 렌더링 업데이트
///
/// ## 주의사항
/// - MainActor에서만 동작 (@MainActor 속성)
/// - 벽면은 기본적으로 숨김 상태이며 충돌 시에만 표시됨
/// - 바닥면은 시각적 피드백에서 제외됨 (사용자가 바닥을 기준으로 배치하므로)
@MainActor
@Observable
final class BoundaryCollisionManager {

    // MARK: - Properties

    /// 경계 벽면 컨테이너
    ///
    /// 5개의 벽면 엔티티(좌/우/상/전/후)를 담고 있는 루트 Entity.
    /// 바닥면은 포함되지 않음 (시각적 피드백 제외)
    private(set) var boundaryWalls: Entity?

    /// 경계 벽면 참조 (성능 최적화용 캐시)
    ///
    /// Key: 벽면 방향 ("left", "right", "top", "front", "back")
    /// Value: 해당 방향의 ModelEntity
    ///
    /// 매번 Entity 트리를 탐색하지 않고 O(1) 시간에 벽면에 접근하기 위한 캐시.
    /// setupBoundaryWalls() 호출 시 생성되며 removeBoundaryWalls() 호출 시 제거됨.
    private var wallEntities: [String: ModelEntity] = [:]

    /// 이동 범위
    ///
    /// 오브젝트가 이동할 수 있는 3D 공간의 경계를 정의.
    /// 생성자에서 지정하지 않으면 SceneConstants.defaultMovementBounds 사용.
    /// 이 범위를 벗어나면 충돌로 감지되어 시각적 피드백이 표시됨.
    private let movementBounds: MovementBounds

    /// 현재 충돌 중인 벽면들
    ///
    /// 엔티티가 현재 충돌하고 있는 벽면 방향의 집합.
    /// 예: {"left", "top"} - 좌측과 상단 벽면에 동시 충돌 중
    ///
    /// 이전 프레임과 비교하여 새로 충돌한 벽면은 Glow 효과를 적용하고,
    /// 충돌이 끝난 벽면은 효과를 제거함 (차분 업데이트)
    private var activeCollisions: Set<String> = []

    // MARK: - Initialization

    /// 경계 충돌 매니저 초기화
    ///
    /// - Parameter movementBounds: 이동 가능 범위. nil이면 기본값 사용.
    ///
    /// ## 기본 이동 범위 (SceneConstants.defaultMovementBounds)
    /// floorSize = 2.0 기준:
    /// - X축: -1.0 ~ 1.0
    /// - Y축: -1.0 ~ 1.0
    /// - Z축: -1.0 ~ 1.0
    init(movementBounds: MovementBounds? = nil) {
        self.movementBounds = movementBounds ?? SceneConstants.defaultMovementBounds
    }

    // MARK: - Wall Management

    /// 경계 벽면 생성 및 씬에 추가
    ///
    /// 이동 범위에 맞춰 5개의 투명한 벽면 엔티티(좌/우/상/전/후)를 생성하고
    /// 부모 엔티티에 추가합니다. 기존 벽면이 있다면 자동으로 제거됩니다.
    ///
    /// - Parameter parent: 벽면을 추가할 부모 엔티티 (일반적으로 rootEntity)
    ///
    /// ## 호출 시점
    /// - SceneRealityView의 setupScene에서 호출
    /// - Volume 및 Immersive 모드 전환 시 호출
    ///
    /// ## 생성되는 벽면
    /// - 각 벽면은 기본적으로 완전 투명 (opacity: 0.0)
    /// - 충돌 감지용 CollisionComponent 포함
    /// - 기본 상태는 숨김 (isEnabled: false)
    /// - 충돌 시에만 Glow 효과와 함께 표시됨
    ///
    /// ## 성능
    /// - 벽면 엔티티를 딕셔너리로 캐싱하여 이후 빠른 접근 보장
    /// - 텍스처는 BoundaryWallEntity에서 싱글톤으로 캐싱됨
    func setupBoundaryWalls(in parent: Entity) {
        // 기존 벽면 제거 (씬 전환 등으로 중복 생성 방지)
        boundaryWalls?.removeFromParent()
        wallEntities.removeAll()

        // 새 벽면 생성 (컨테이너 + 딕셔너리)
        let (walls, entities) = BoundaryWallEntity.createWalls(for: movementBounds)
        parent.addChild(walls)
        boundaryWalls = walls
        wallEntities = entities
    }

    /// 경계 벽면 제거
    ///
    /// 씬에서 모든 경계 벽면을 제거하고 관련 상태를 초기화합니다.
    ///
    /// ## 호출 시점
    /// - SceneViewModel.reset() 호출 시
    /// - 씬 종료 또는 정리 시
    ///
    /// ## 정리 작업
    /// - 벽면 엔티티를 씬에서 제거
    /// - 벽면 캐시 딕셔너리 정리
    /// - 활성 충돌 상태 초기화
    func removeBoundaryWalls() {
        boundaryWalls?.removeFromParent()
        boundaryWalls = nil
        wallEntities.removeAll()
        activeCollisions.removeAll()
    }

    /// 모든 충돌 상태 초기화 (제스처 종료 시 호출)
    ///
    /// 제스처가 종료되면 표시 중인 모든 시각적 피드백을 숨기고
    /// 충돌 상태를 초기화합니다.
    ///
    /// ## 호출 시점
    /// - EntityDragGesture의 onEnded
    /// - SceneViewModel.endGesture()
    ///
    /// ## 동작
    /// 1. 현재 표시 중인 모든 벽면의 Glow 효과 제거
    /// 2. 벽면 엔티티를 숨김 처리 (isEnabled = false)
    /// 3. activeCollisions 집합 초기화
    ///
    /// ## 주의사항
    /// - 벽면이 없으면 경고 로그만 출력하고 조용히 종료
    /// - 벽면을 찾지 못한 경우 디버그 로그 출력 (정상적인 상황에서는 발생하지 않음)
    func clearCollisions() {
        guard boundaryWalls != nil else {
            #if DEBUG
            print("⚠️ [BoundaryCollision] boundaryWalls가 nil")
            #endif
            return
        }

        // 활성화된 모든 벽면을 숨김
        for wallName in activeCollisions {
            if let wall = wallEntities[wallName] {
                hideWall(wall)
            } else {
                #if DEBUG
                print("❌ [BoundaryCollision] 벽면을 찾을 수 없음: \(wallName)")
                #endif
            }
        }

        activeCollisions.removeAll()
    }

    // MARK: - Collision Detection

    /// 엔티티가 경계면에 닿았는지 확인하고 시각적 피드백 제공
    ///
    /// 드래그 제스처 중 매 프레임마다 호출되어 엔티티의 위치를 기반으로
    /// 경계면과의 충돌을 감지하고 시각적 피드백을 업데이트합니다.
    ///
    /// - Parameter entity: 충돌을 확인할 ModelEntity (드래그 중인 오브젝트)
    ///
    /// ## 호출 시점
    /// - EntityDragGesture의 onChanged 콜백에서 호출
    /// - SceneViewModel.checkBoundaryCollision(for:)을 통해 호출
    ///
    /// ## 동작 과정
    /// 1. 엔티티의 실제 렌더링 크기(visualBounds) 계산
    /// 2. 부모 좌표계 기준으로 위치 획득
    /// 3. 5방향(좌/우/상/전/후)에 대한 충돌 감지
    /// 4. 이전 프레임과 비교하여 변경된 충돌 상태만 업데이트 (차분 업데이트)
    ///    - 새 충돌: Glow 효과 표시
    ///    - 충돌 해제: 효과 제거
    ///
    /// ## 성능 최적화
    /// - 충돌 상태가 변경된 벽면만 렌더링 업데이트
    /// - 텍스처는 싱글톤 캐싱으로 한 번만 로드
    /// - 벽면 조회는 O(1) 딕셔너리 접근
    ///
    /// ## 주의사항
    /// - 부모 엔티티가 없으면 조용히 종료 (정상적인 상황에서는 발생하지 않음)
    /// - 바닥면(minY) 충돌은 EntityDragGesture에서 별도로 처리됨
    func checkCollision(for entity: ModelEntity) {
        guard let parent = entity.parent else { return }

        // 엔티티의 실제 bounds 계산 (부모 좌표계 기준)
        let bounds = getEntityBounds(entity, relativeTo: parent)
        let position = entity.position(relativeTo: parent)

        // 각 축에 대한 충돌 확인
        let collisions = detectBoundaryCollisions(bounds: bounds, position: position)

        // 변경된 충돌 상태 업데이트 (차분 업데이트)
        updateCollisionFeedback(collisions)
    }

    /// 엔티티의 실제 bounds 계산
    ///
    /// visualBounds를 사용하여 실제 렌더링되는 크기를 기준으로 계산합니다.
    /// 이는 엔티티의 scale, rotation 등이 모두 반영된 최종 크기입니다.
    ///
    /// - Parameters:
    ///   - entity: 크기를 계산할 엔티티
    ///   - parent: 기준이 되는 부모 엔티티
    /// - Returns: 엔티티의 extents (width, height, depth)
    ///
    /// ## visualBounds vs bounds
    /// - `visualBounds`: 실제 렌더링 크기 (회전, 스케일 반영)
    /// - `bounds`: 원본 모델 크기 (변환 미반영)
    ///
    /// ## 좌표계
    /// - relativeTo: parent를 지정하면 부모 좌표계 기준
    /// - relativeTo: nil이면 월드 좌표계 기준
    private func getEntityBounds(_ entity: ModelEntity, relativeTo parent: Entity?) -> SIMD3<Float> {
        // visualBounds를 사용하여 실제 렌더링 크기 기준으로 계산
        let visualBounds = entity.visualBounds(relativeTo: parent)
        return visualBounds.extents
    }

    /// 경계면과의 충돌 감지
    ///
    /// 엔티티의 5개 면(좌/우/상/전/후, 바닥 제외)이 이동 범위를 벗어났는지 검사합니다.
    ///
    /// - Parameters:
    ///   - bounds: 엔티티의 크기 (extents)
    ///   - position: 엔티티의 중심 위치
    /// - Returns: 충돌한 벽면 방향들의 집합 (예: {"left", "top"})
    ///
    /// ## 충돌 판정 기준
    /// 엔티티의 가장자리(edge)가 경계선을 넘으면 충돌로 판정합니다.
    ///
    /// ### X축 (좌우)
    /// - 좌측 충돌: `position.x - halfBounds.x <= minX`
    /// - 우측 충돌: `position.x + halfBounds.x >= maxX`
    ///
    /// ### Y축 (상하)
    /// - 상단 충돌: `position.y + halfBounds.y >= maxY`
    /// - 하단: 시각적 피드백 제외 (EntityDragGesture에서 위치 제한)
    ///
    /// ### Z축 (전후)
    /// - 전면 충돌: `position.z - halfBounds.z <= minZ`
    /// - 후면 충돌: `position.z + halfBounds.z >= maxZ`
    ///
    /// ## 동시 충돌
    /// 코너나 모서리에서는 여러 방향 동시 충돌 가능
    /// 예: {"left", "top", "front"} - 좌측 상단 전면 코너
    ///
    /// ## 바닥면을 제외하는 이유
    /// 사용자가 바닥을 기준으로 오브젝트를 배치하므로,
    /// 바닥 충돌은 자연스러운 동작이며 피드백이 불필요함.
    private func detectBoundaryCollisions(
        bounds: SIMD3<Float>,
        position: SIMD3<Float>
    ) -> Set<String> {
        var collisions: Set<String> = []

        let halfBounds = bounds / 2.0

        // X축 충돌 (좌우) - 경계선을 넘었을 때만 감지
        let leftEdge = position.x - halfBounds.x
        let rightEdge = position.x + halfBounds.x

        if leftEdge <= movementBounds.minX {
            collisions.insert("left")
        }

        if rightEdge >= movementBounds.maxX {
            collisions.insert("right")
        }

        // Y축 충돌 (상단) - 경계선을 넘었을 때만 감지
        // 바닥면(minY)은 제외: 사용자가 바닥을 기준으로 배치하므로
        let topEdge = position.y + halfBounds.y

        if topEdge >= movementBounds.maxY {
            collisions.insert("top")
        }

        // Z축 충돌 (전후) - 경계선을 넘었을 때만 감지
        let frontEdge = position.z - halfBounds.z
        let backEdge = position.z + halfBounds.z

        if frontEdge <= movementBounds.minZ {
            collisions.insert("front")
        }

        if backEdge >= movementBounds.maxZ {
            collisions.insert("back")
        }

        return collisions
    }

    /// 충돌 상태에 따른 시각적 피드백 업데이트
    ///
    /// 이전 프레임의 충돌 상태(`activeCollisions`)와 현재 프레임의 충돌 상태(`newCollisions`)를
    /// 비교하여 변경된 벽면에 대해서만 시각적 피드백을 업데이트합니다.
    ///
    /// - Parameter newCollisions: 현재 프레임에서 감지된 충돌 벽면 집합
    ///
    /// ## 동작 원리
    /// 1. **새 충돌 감지**: `newCollisions`에는 있지만 `activeCollisions`에 없음
    ///    - 해당 벽면에 Glow 효과 적용 (텍스처, emissive 설정)
    ///    - 벽면을 보이게 설정 (isEnabled = true)
    ///
    /// 2. **충돌 종료 감지**: `activeCollisions`에는 있지만 `newCollisions`에 없음
    ///    - 해당 벽면을 숨김 처리 (isEnabled = false)
    ///
    /// 3. **계속 충돌 중**: 양쪽 모두에 존재
    ///    - 아무 작업도 하지 않음 (이미 효과가 적용되어 있음)
    ///
    /// ## 예시
    /// ```
    /// // 프레임 1
    /// activeCollisions = {"left"}
    /// newCollisions = {"left", "top"}
    /// 결과: "top" 벽면에 Glow 적용
    ///
    /// // 프레임 2
    /// activeCollisions = {"left", "top"}
    /// newCollisions = {"top"}
    /// 결과: "left" 벽면 숨김
    /// ```
    ///
    /// ## 성능 최적화
    /// - 변경된 벽면만 업데이트하여 불필요한 렌더링 방지
    /// - Set 연산으로 O(n) 시간 복잡도 (n은 최대 5개)
    ///
    /// ## 주의사항
    /// - 벽면이 설정되지 않았으면 조용히 종료
    /// - 벽면을 찾지 못한 경우 디버그 로그 출력 (비정상 상황)
    private func updateCollisionFeedback(_ newCollisions: Set<String>) {
        guard boundaryWalls != nil else { return }

        // 새로 충돌한 벽면: glow 효과 적용
        for wallName in newCollisions {
            if !activeCollisions.contains(wallName) {
                // 새 충돌 - glow 효과 적용
                if let wall = wallEntities[wallName] {
                    BoundaryWallEntity.applyGlowEffect(to: wall)
                } else {
                    #if DEBUG
                    print("❌ [BoundaryCollision] 벽면을 찾을 수 없음: \(wallName)")
                    #endif
                }
            }
        }

        // 충돌이 끝난 벽면: 숨김 처리
        for wallName in activeCollisions {
            if !newCollisions.contains(wallName) {
                if let wall = wallEntities[wallName] {
                    hideWall(wall)
                }
            }
        }

        // 상태 업데이트 (다음 프레임에서 비교용)
        activeCollisions = newCollisions
    }

    /// 벽면을 완전히 숨김
    ///
    /// 충돌이 끝난 벽면을 화면에서 제거합니다.
    /// Material 속성은 유지되므로 다음 충돌 시 빠르게 재표시 가능합니다.
    ///
    /// - Parameter wall: 숨길 벽면 엔티티
    ///
    /// ## 동작
    /// - `isEnabled = false`: 렌더링 및 충돌 감지 비활성화
    /// - Material은 유지: 재사용 시 텍스처 재로드 불필요
    ///
    /// ## isEnabled vs isActive
    /// - `isEnabled`: 렌더링만 비활성화, 엔티티는 씬에 유지
    /// - `isActive`: 엔티티를 완전히 비활성화
    private func hideWall(_ wall: ModelEntity) {
        wall.isEnabled = false
    }
}
