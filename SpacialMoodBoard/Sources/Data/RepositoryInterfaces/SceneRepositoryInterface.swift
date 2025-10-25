//
//  SceneRepositoryInterface.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/24/25.
//

import Foundation

// MARK: - RepositoryInterfacel

@MainActor
protocol SceneRepositoryInterface: AnyObject {
    /// 로드 직후, 기존 씬 오브젝트 배열 전체를 인덱스에 등록
    func registerObjects(_ objects: [SceneObject])

    /// 오브젝트가 배열에 추가되었을 때 호출 (인덱스 등록)
    func didAppend(_ object: SceneObject)

    /// 오브젝트가 배열에서 제거되었을 때 호출 (인덱스 해제)
    func didRemove(objectId: UUID, assetId: String)

    /// 특정 assetId를 참조하는 모든 오브젝트를 배열에서 제거하고, 제거된 ID들을 반환
    func removeAllReferencing(from objects: inout [SceneObject], assetId: String) -> [UUID]

    /// 배열 내에서 assetId를 일괄 치환하고, 인덱스도 갱신
    func remapAssetId(in objects: inout [SceneObject], old: String, new: String)
}
