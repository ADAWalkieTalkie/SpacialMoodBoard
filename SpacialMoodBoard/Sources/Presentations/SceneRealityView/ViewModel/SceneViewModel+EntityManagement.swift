import Foundation
import RealityKit

// MARK: - SceneObject Entity Management

extension SceneViewModel {

    func updateEntities(
        sceneObjects: [SceneObject],
        anchor: Entity
    ) {
        let currentObjectIds = Set(sceneObjects.map { $0.id })
        let existingEntityIds = Set(entityMap.keys)

        // 1. 삭제된 객체 제거
        removeDeletedEntities(
            currentIds: currentObjectIds,
            existingIds: existingEntityIds
        )

        // 2. 새로운 객체 추가 또는 업데이트
        updateOrCreateEntities(
            sceneObjects: sceneObjects,
            anchor: anchor
        )
    }

    // MARK: - Private Helpers

    private func removeDeletedEntities(
        currentIds: Set<UUID>,
        existingIds: Set<UUID>
    ) {
        for removedId in existingIds.subtracting(currentIds) {
            if let entity = entityMap[removedId] {
                entity.removeFromParent()
                entityMap.removeValue(forKey: removedId)
            }
        }
    }

    private func updateOrCreateEntities(
        sceneObjects: [SceneObject],
        anchor: Entity
    ) {
        for sceneObject in sceneObjects {
            guard let asset = assetRepository.asset(withId: sceneObject.assetId)
            else { continue }

            if let existingEntity = entityMap[sceneObject.id] {
                // 기존 Entity 위치 업데이트
                existingEntity.position = sceneObject.position
            } else {
                // 새로운 Entity 생성
                createAndAddEntity(
                    sceneObject: sceneObject,
                    asset: asset,
                    anchor: anchor
                )
            }
        }
    }

    private func createAndAddEntity(
        sceneObject: SceneObject,
        asset: Asset,
        anchor: Entity
    ) {
        if let entity = ImageEntity.create(
            from: sceneObject,
            with: asset,
            viewMode: false
        ) {
            anchor.addChild(entity)
            entityMap[sceneObject.id] = entity
        }
    }

    //MARK: - 바닥에 이미지 적용
    func applyFloorImage(from asset: Asset) {
        guard asset.type == .image else {
            return
        }

        // Documents 디렉토리로부터의 상대 경로 계산
        let relativePath: String?
        if let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first {
            let documentsPathWithSlash = documentsURL.path + "/"
            if asset.url.path.hasPrefix(documentsPathWithSlash) {
                relativePath = String(
                    asset.url.path.dropFirst(documentsPathWithSlash.count)
                )
            } else {
                print("⚠️ Asset이 Documents 디렉토리 내에 없음: \(asset.url.path)")
                relativePath = nil
            }
        } else {
            print("⚠️ Documents 디렉토리를 찾을 수 없음")
            relativePath = nil
        }

        // SpacialEnvironment에 floor material URL과 상대 경로 저장
        var updatedEnvironment = spacialEnvironment
        updatedEnvironment.floorMaterialImageURL = asset.url
        updatedEnvironment.floorImageRelativePath = relativePath
        spacialEnvironment = updatedEnvironment

        // Room entity 캐시 무효화 (다음 getRoomEntity 호출 시 새 material로 재생성됨)
        if let projectId = appModel.selectedProject?.id {
            roomEntities.removeValue(forKey: projectId)
        }

        // 선택 모드 해제
        isSelectingFloorImage = false

        // 변경사항 저장
        saveScene()
    }

}
