//
//  EntityRepositoryInterface.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/31/25.
//

import Foundation
import RealityKit

/// RealityKit 엔티티의 전체 라이프사이클을 관리하는 Repository 인터페이스
/// - entityMap을 통한 SceneObject 엔티티 캐싱 및 관리
/// - Floor 엔티티 생성 및 캐싱
/// - RootEntity를 기준으로 엔티티 트리 동기화
@MainActor
protocol EntityRepositoryInterface {

    // MARK: - Entity CRUD

    /// SceneObject로부터 새로운 엔티티를 생성하여 rootEntity에 추가
    /// - Parameters:
    ///   - sceneObject: 엔티티를 생성할 SceneObject
    ///   - asset: SceneObject가 참조하는 Asset (이미지/사운드 파일)
    ///   - rootEntity: 엔티티를 추가할 부모 엔티티
    /// - Returns: 생성된 ModelEntity, 실패 시 nil
    func createEntity(from sceneObject: SceneObject, asset: Asset, rootEntity: Entity) -> ModelEntity?

    /// 특정 ID의 엔티티 위치를 업데이트
    /// - Parameters:
    ///   - id: 업데이트할 SceneObject의 ID
    ///   - position: 새로운 위치
    func updateEntityPosition(id: UUID, to position: SIMD3<Float>)

    /// 특정 ID의 엔티티를 제거 (부모에서 제거 + 캐시에서 삭제)
    /// - Parameter id: 제거할 SceneObject의 ID
    func removeEntity(id: UUID)

    /// 캐시에서 엔티티 조회
    /// - Parameter id: 조회할 SceneObject의 ID
    /// - Returns: 캐시된 ModelEntity, 없으면 nil
    func getEntity(for id: UUID) -> ModelEntity?

    // MARK: - Entity Synchronization

    /// SceneObject 배열과 현재 엔티티 상태를 동기화
    /// - 삭제된 객체의 엔티티 제거
    /// - 새로운 객체의 엔티티 생성
    /// - 기존 객체의 위치 업데이트
    /// - Parameters:
    ///   - sceneObjects: 동기화할 SceneObject 배열
    ///   - rootEntity: 엔티티가 추가될 루트 엔티티
    ///   - assetRepository: Asset 조회를 위한 Repository
    func syncEntities(
        sceneObjects: [SceneObject],
        rootEntity: Entity,
        assetRepository: AssetRepositoryInterface
    )

    // MARK: - Floor Entity Management

    /// Floor 엔티티를 가져오거나 생성
    /// - 이미 캐싱된 floor가 있으면 재사용
    /// - 없으면 FloorEntity.create()로 새로 생성 후 캐싱
    /// - Parameter floorImageURL: Floor 이미지 URL (AssetRepository에서 조회된 URL)
    /// - Returns: Floor ModelEntity, 생성 실패 시 nil
    func getOrCreateFloorEntity(floorImageURL: URL?) async -> ModelEntity?

    /// Floor 엔티티 캐시를 삭제 (다음 호출 시 재생성됨)
    func clearFloorCache()

    // MARK: - Cache Management

    /// 모든 엔티티 캐시를 초기화 (entityMap + floor)
    func clearAllCaches()

    /// 현재 캐싱된 모든 엔티티 맵 조회 (read-only)
    /// - Returns: SceneObject ID → ModelEntity 매핑
    func getCachedEntities() -> [UUID: ModelEntity]
}
