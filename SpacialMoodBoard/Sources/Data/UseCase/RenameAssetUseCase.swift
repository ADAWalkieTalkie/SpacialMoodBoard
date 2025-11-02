//
//  RenameAssetUseCase.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/31/25.
//

import Foundation

struct RenameAssetResult {
    let oldId: String
    let newId: String
    let affectedObjectIds: [UUID]
}

struct RenameAssetUseCase {
    let assetRepository: AssetRepositoryInterface
    let sceneObjectRepository: SceneObjectRepositoryInterface
    
    /// 에셋의 이름을 변경하고, 이름 변경으로 인해 변경된 `assetId`를 참조 중인 모든 `SceneObject`에 일괄 반영(remap)하는 유즈케이스
    /// - Parameters:
    ///   - assetId: 이름을 변경할 대상 에셋의 식별자
    ///   - newBaseName: 변경할 새 기본 파일명(확장자는 자동 유지됨)
    ///   - scene: 현재 씬 모델(`inout`으로 전달되어 내부의 참조가 갱신됨)
    /// - Returns: 이름 변경 전/후의 에셋 ID와, 영향을 받은 `SceneObject`들의 ID 목록
    /// - Note:
    ///   - 내부적으로 `AssetRepository.renameAsset`을 호출하여 에셋을 rename한 뒤,
    ///     `SceneObjectRepository.remapAssetId`를 통해 씬 내 참조를 일관성 있게 갱신
    ///   - 이름만 바뀌고 `assetId`가 변하지 않은 경우(`oldId == newId`)에는 씬 수정 없이 빈 결과를 반환
    ///   - Floor 이미지 참조도 자동으로 업데이트됨
    @MainActor
    func execute(assetId: String, newBaseName: String, scene: inout SceneModel) throws -> RenameAssetResult {
        let oldId = assetId

        // Rename 전 기존 Asset의 상대 경로 계산
        let oldRelativePath: String? = {
            guard let oldAsset = assetRepository.asset(withId: oldId),
                  let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
            }
            let documentsPath = documentsURL.path + "/"
            guard oldAsset.url.path.hasPrefix(documentsPath) else { return nil }
            return String(oldAsset.url.path.dropFirst(documentsPath.count))
        }()

        // Asset rename 실행
        let updated = try assetRepository.renameAsset(id: oldId, to: newBaseName)
        let newId = updated.id

        guard newId != oldId else {
            return .init(oldId: oldId, newId: newId, affectedObjectIds: [])
        }

        // SceneObject 참조 업데이트
        let affected = sceneObjectRepository.remapAssetId(in: &scene, old: oldId, new: newId)

        // Floor 이미지 참조 업데이트
        if let oldPath = oldRelativePath,
           scene.spacialEnvironment.floorImageRelativePath == oldPath {

            // 새 Asset의 상대 경로 계산
            if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let documentsPath = documentsURL.path + "/"
                if updated.url.path.hasPrefix(documentsPath) {
                    let newRelativePath = String(updated.url.path.dropFirst(documentsPath.count))
                    scene.spacialEnvironment.floorImageRelativePath = newRelativePath
                }
            }
        }

        return .init(oldId: oldId, newId: newId, affectedObjectIds: affected)
    }
}
