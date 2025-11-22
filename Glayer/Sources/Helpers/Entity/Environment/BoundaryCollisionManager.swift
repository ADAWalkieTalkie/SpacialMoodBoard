import RealityKit
import Observation

/// 엔티티와 경계면 충돌을 감지하고 시각적 피드백을 제공하는 매니저
@MainActor
@Observable
final class BoundaryCollisionManager {

    // MARK: - Properties

    /// 경계 벽면 컨테이너
    private(set) var boundaryWalls: Entity?

    /// 이동 범위
    private let movementBounds: MovementBounds

    /// 현재 충돌 중인 벽면들 (벽면 이름 → 강도)
    private var activeCollisions: [String: Float] = [:]

    // MARK: - Initialization

    init(movementBounds: MovementBounds? = nil) {
        self.movementBounds = movementBounds ?? SceneConstants.defaultMovementBounds
    }

    // MARK: - Wall Management

    /// 경계 벽면 생성 및 씬에 추가
    /// - Parameter parent: 벽면을 추가할 부모 엔티티
    func setupBoundaryWalls(in parent: Entity) {
        // 기존 벽면 제거
        boundaryWalls?.removeFromParent()

        // 새 벽면 생성
        let walls = BoundaryWallEntity.createWalls(for: movementBounds)
        parent.addChild(walls)
        boundaryWalls = walls

    }

    /// 경계 벽면 제거
    func removeBoundaryWalls() {
        boundaryWalls?.removeFromParent()
        boundaryWalls = nil
        activeCollisions.removeAll()
    }

    // MARK: - Collision Detection

    /// 엔티티가 경계면에 닿았는지 확인하고 시각적 피드백 제공
    /// - Parameter entity: 확인할 엔티티
    func checkCollision(for entity: ModelEntity) {
        guard let parent = entity.parent else { return }

        // 엔티티의 실제 bounds 계산 (부모 좌표계 기준)
        let bounds = getEntityBounds(entity, relativeTo: parent)
        let position = entity.position(relativeTo: parent)

        // 각 축에 대한 충돌 확인
        let collisions = detectBoundaryCollisions(bounds: bounds, position: position)

        // 변경된 충돌 상태 업데이트
        updateCollisionFeedback(collisions)
    }

    /// 엔티티의 실제 bounds 계산
    private func getEntityBounds(_ entity: ModelEntity, relativeTo parent: Entity?) -> SIMD3<Float> {
        // visualBounds를 사용하여 실제 렌더링 크기 기준으로 계산
        let vb = entity.visualBounds(relativeTo: parent)
        return vb.extents
    }

    /// 경계면과의 충돌 감지
    /// - Returns: 충돌한 벽면 이름과 충돌 강도 (접촉 시 1.0, 아니면 감지 안 됨)
    private func detectBoundaryCollisions(
        bounds: SIMD3<Float>,
        position: SIMD3<Float>
    ) -> [String: Float] {
        var collisions: [String: Float] = [:]

        let halfBounds = bounds / 2.0

        // X축 충돌 (좌우) - 경계선을 넘었을 때만 감지
        let leftEdge = position.x - halfBounds.x
        let rightEdge = position.x + halfBounds.x

        if leftEdge <= movementBounds.minX {
            collisions["left"] = 1.0
        }

        if rightEdge >= movementBounds.maxX {
            collisions["right"] = 1.0
        }

        // Y축 충돌 (상하) - 경계선을 넘었을 때만 감지
        let bottomEdge = position.y - halfBounds.y
        let topEdge = position.y + halfBounds.y

        if bottomEdge <= movementBounds.minY {
            collisions["bottom"] = 1.0
        }

        if topEdge >= movementBounds.maxY {
            collisions["top"] = 1.0
        }

        // Z축 충돌 (전후) - 경계선을 넘었을 때만 감지
        let frontEdge = position.z - halfBounds.z
        let backEdge = position.z + halfBounds.z

        if frontEdge <= movementBounds.minZ {
            collisions["front"] = 1.0
        }

        if backEdge >= movementBounds.maxZ {
            collisions["back"] = 1.0
        }

        return collisions
    }

    /// 충돌 상태에 따른 시각적 피드백 업데이트
    private func updateCollisionFeedback(_ newCollisions: [String: Float]) {
        guard let wallsContainer = boundaryWalls else { return }

        // 새로 충돌한 벽면: glow 효과 적용
        for (wallName, intensity) in newCollisions {
            if activeCollisions[wallName] == nil {
                // 새 충돌 - glow 효과 적용
                if let wall = findWall(named: wallName, in: wallsContainer) {
                    BoundaryWallEntity.applyGlowEffect(to: wall, intensity: intensity)
                }
            } else if activeCollisions[wallName] != intensity {
                // 강도 변경 - glow 업데이트
                if let wall = findWall(named: wallName, in: wallsContainer) {
                    BoundaryWallEntity.applyGlowEffect(to: wall, intensity: intensity)
                }
            }
        }

        // 충돌이 끝난 벽면: 투명하게 복원
        for wallName in activeCollisions.keys {
            if newCollisions[wallName] == nil {
                if let wall = findWall(named: wallName, in: wallsContainer) {
                    resetWall(wall)
                }
            }
        }

        // 상태 업데이트
        activeCollisions = newCollisions
    }

    /// 벽면 찾기
    private func findWall(named name: String, in container: Entity) -> ModelEntity? {
        return container.findEntity(named: "boundaryWall_\(name)") as? ModelEntity
    }

    /// 벽면을 투명 상태로 복원
    private func resetWall(_ wall: ModelEntity) {
        var material = PhysicallyBasedMaterial()
        material.blending = .transparent(opacity: 0.0)
        material.faceCulling = .none

        wall.model?.materials = [material]
    }
}
