import Foundation
import RealityKit

// MARK: - SceneObject Entity Management

extension SceneViewModel {

    /// SceneObject 배열과 엔티티를 동기화
    func updateEntities(
        sceneObjects: [SceneObject],
        rootEntity: Entity
    ) {
        // rootEntity 참조 저장 (회전 등의 작업에 사용)
        self.rootEntity = rootEntity

        entityRepository.syncEntities(
            sceneObjects: sceneObjects,
            rootEntity: rootEntity,
            assetRepository: assetRepository,
            viewMode: userSpatialState.viewMode
        )
    }

    func loadEntities(
        sceneObjects: [SceneObject],
        rootEntity: Entity
    ) async {  // async 추가
        // rootEntity 참조 저장
        self.rootEntity = rootEntity
        
        // Volume 모드일 때만 로딩 토스트 표시
        if appStateManager.appState.isVolumeOpen {
            showLoadingEntityToast = true
            
            // UI가 업데이트될 시간을 주기 위해 짧은 딜레이
            try? await Task.sleep(for: .milliseconds(50))
        }
        
        // syncEntities 실행 (동기 함수지만 async 컨텍스트에서 호출)
        // viewMode를 전달하여 SoundEntity가 올바른 초기 상태로 생성되도록 함
        entityRepository.syncEntities(
            sceneObjects: sceneObjects,
            rootEntity: rootEntity,
            assetRepository: assetRepository,
            viewMode: userSpatialState.viewMode
        )

        if appStateManager.appState.isVolumeOpen {
            // 최소 표시 시간 보장
            try? await Task.sleep(for: .milliseconds(300))

            // 토스트 숨김
            showLoadingEntityToast = false
        }
    }

    /// 특정 ID의 엔티티를 가져오기
    func getEntity(for id: UUID) -> ModelEntity? {
        return entityRepository.getEntity(for: id)
    }
    
    /// Floor 엔티티를 가져오거나 생성
    func getFloorEntity() async -> ModelEntity? {
        return await entityRepository.getOrCreateFloorEntity(floorImageURL: self.floorImageURL)
    }

    /// 경계 벽면 설정
    func setupBoundaryWalls(in rootEntity: Entity) {
        boundaryCollisionManager.setupBoundaryWalls(in: rootEntity)
    }

    /// 엔티티 위치 변경 시 경계면 충돌 확인
    func checkBoundaryCollision(for entity: ModelEntity) {
        boundaryCollisionManager.checkCollision(for: entity)
    }
}
