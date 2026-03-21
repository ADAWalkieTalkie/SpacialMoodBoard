//
//  ObjectPlacementPolicy.swift
//  Glayer
//
//  Created by jeongminji on 1/4/26.
//

import Foundation
import simd

struct ObjectPlacementPolicy {
    
    // MARK: - Properties

    private let movementBounds: MovementBounds
    private let minDistance: Float
    
    // MARK: - Init

    /// Init
    /// - Parameters:
    ///   - movementBounds: 배치 가능한 xyz 범위
    ///   - minDistance: 다른 오브젝트와의 최소 거리
    init(
           movementBounds: MovementBounds? = nil,
           minDistance: Float = 0.08
    ) {
        self.movementBounds = movementBounds ?? SceneConstants.defaultMovementBounds
        self.minDistance = minDistance
    }

    // MARK: - Public Methods

    /// 새 오브젝트의 최종 배치 위치 계산
    /// - Parameters:
    ///   - base: 사용자가 의도한 기본 위치 (예: 원본 오브젝트 근처, 카메라 앞 등)
    ///   - existingPositions: 현재 씬에 존재하는 모든 SceneObject의 position 배열
    /// - Returns: MovementBounds 안에 있으며, 기존 오브젝트와 최소 거리를 만족하려고 시도한 최종 위치
    ///
    /// 동작 순서:
    /// 1. base 위치를 bounds 안으로 clamp
    /// 2. 기존 오브젝트들과 minDistance 이상 떨어져 있다면 그대로 사용
    /// 3. 겹친다면, base 주변을 원형/나선형으로 돌며 비어 있는 위치를 탐색
    /// 4. 끝까지 못 찾으면 clamp된 위치를 그대로 반환 (최악의 fallback)
    func adjustedPosition(
        base: SIMD3<Float>,
        existingPositions: [SIMD3<Float>]
    ) -> SIMD3<Float> {
        let clamped = clampPosition(base, bounds: movementBounds, margin: minDistance)

        if isFreePosition(clamped,
                          existingPositions: existingPositions,
                          minDistance: minDistance) {
            return clamped
        }

        let maxRadiusX = max(movementBounds.maxX - clamped.x,
                             clamped.x - movementBounds.minX)
        let maxRadiusZ = max(movementBounds.maxZ - clamped.z,
                             clamped.z - movementBounds.minZ)
        let maxRadius = min(maxRadiusX, maxRadiusZ)
        
        let angleStep: Float = .pi / 12
        let radiusStep: Float = minDistance * 0.8

        var angle: Float = 0
        var radius: Float = minDistance

        var steps = 0
        let maxSteps = 2000

        while radius <= maxRadius && steps < maxSteps {
            let offset = SIMD3<Float>(
                x: cos(angle) * radius,
                y: 0,
                z: sin(angle) * radius
            )

            var candidate = clamped + offset
            candidate = clampPosition(candidate,
                                      bounds: movementBounds,
                                      margin: minDistance)

            if isFreePosition(candidate,
                              existingPositions: existingPositions,
                              minDistance: minDistance) {
                return candidate
            }

            angle += angleStep
            if angle >= 2 * .pi {
                angle -= 2 * .pi
                radius += radiusStep
            }

            steps += 1
        }

        return clamped
    }

    // MARK: - Private Methods

    /// 주어진 위치가 bounds 안에 있도록 xyz를 clamp
    /// - Parameters:
    ///   - position: 보정 대상이 되는 원본 위치
    ///   - bounds: 오브젝트가 이동할 수 있는 허용 영역 범위
    ///   - margin: 경계와의 최소 거리(여유 거리). 이 값만큼 안쪽으로 제한됨
    /// - Returns: bounds 범위 안으로 보정된 안전한 위치 값
    private func clampPosition(
        _ position: SIMD3<Float>,
        bounds: MovementBounds,
        margin: Float
    ) -> SIMD3<Float> {
        var result = position

        result.x = min(max(result.x, bounds.minX + margin), bounds.maxX - margin)
        result.y = min(max(result.y, bounds.minY + margin), bounds.maxY - margin)
        result.z = min(max(result.z, bounds.minZ + margin), bounds.maxZ - margin)

        return result
    }

    /// 특정 위치가 기존 오브젝트들과 충분히 떨어져 있는지 검사
    /// 기존 객체들과의 거리 중 하나라도 minDistance보다 작으면 겹친 것으로 간주
    /// - Parameters:
    ///   - position: 검사할 대상 위치
    ///   - existingPositions: 현재 씬에 존재하는 모든 오브젝트의 위치 목록
    ///   - minDistance: 유지해야 하는 최소 거리 값
    /// - Returns: 모든 오브젝트와의 거리를 만족하면 true, 아니면 false
    private func isFreePosition(
        _ position: SIMD3<Float>,
        existingPositions: [SIMD3<Float>],
        minDistance: Float
    ) -> Bool {
        for existing in existingPositions {
            if simd_distance(existing, position) < minDistance {
                return false
            }
        }
        return true
    }
}
