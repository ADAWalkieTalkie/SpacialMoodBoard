//
//  SceneRepository.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/24/25.
//

import Foundation

// MARK: - Repository

@MainActor
final class SceneRepository: SceneRepositoryInterface {
    private let usageIndex: AssetUsageIndexProtocol

    init(usageIndex: AssetUsageIndexProtocol) {
        self.usageIndex = usageIndex
    }

    // 전체 등록(로드 직후 1회)
    func registerObjects(_ objects: [SceneObject]) {
        for o in objects {
            usageIndex.register(objectId: o.id, assetId: o.assetId)
        }
    }

    // 단건 추가 알림
    func didAppend(_ object: SceneObject) {
        usageIndex.register(objectId: object.id, assetId: object.assetId)
    }

    // 단건 제거 알림
    func didRemove(objectId: UUID, assetId: String) {
        usageIndex.unregister(objectId: objectId, assetId: assetId)
    }

    // 자산 삭제 등으로 해당 자산을 참조하는 씬 오브젝트 전부 제거
    @discardableResult
    func removeAllReferencing(from objects: inout [SceneObject], assetId: String) -> [UUID] {
        let ids = Array(usageIndex.usages(of: assetId))
        guard !ids.isEmpty else { return [] }

        let idSet = Set(ids)
        // 인덱스 먼저 정리
        for id in ids {
            usageIndex.unregister(objectId: id, assetId: assetId)
        }
        // 배열에서 일괄 제거
        objects.removeAll { idSet.contains($0.id) }
        return ids
    }

    // 파일명 변경 등으로 assetId가 바뀌었을 때, 배열/인덱스 모두 리맵
    func remapAssetId(in objects: inout [SceneObject], old: String, new: String) {
        guard old != new else { return }
        var changed: [UUID] = []
        for i in objects.indices {
            if objects[i].assetId == old {
                let id = objects[i].id
                objects[i] = SceneObject(
                    id: id,
                    assetId: new,
                    position: objects[i].position,
                    isEditable: objects[i].isEditable,
                    attributes: objects[i].attributes
                )
                changed.append(id)
            }
        }
        for id in changed {
            usageIndex.unregister(objectId: id, assetId: old)
            usageIndex.register(objectId: id, assetId: new)
        }
    }
}
