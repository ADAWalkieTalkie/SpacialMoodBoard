import Foundation

/// 씬의 `SceneObject` 컬렉션을 **단일 진입점**으로 관리하는 저장소 인터페이스
/// - 모든 변경 메서드는 내부적으로 **AssetUsageIndex**(assetId ↔ objectId 인덱스)를 함께 갱신해
///   **배열(state)과 인덱스의 일관성**을 보장
/// - UI 스레드 안전성을 위해 전체가 `@MainActor`로 선언되어 있음
@MainActor
protocol SceneObjectRepositoryInterface: AnyObject {

    // MARK: - 초기 동기화

    /// 앱 로드 직후, 기존 `SceneObject` 목록을 받아 **인덱스에 일괄 등록**합니다.
    /// - Important: 배열 자체는 변경하지 않으며, **인덱스만 초기화/동기화**합니다.
    /// - Parameter objects: 현재 씬에 존재하는 모든 `SceneObject` 목록.
    func syncIndex(with objects: [SceneObject])

    // MARK: - 조회

    /// 씬에 포함된 **모든** `SceneObject`를 반환
    /// - Parameter scene: 조회 대상 `SceneModel`
    /// - Returns: `scene.sceneObjects`의 스냅샷(값 타입 복사)
    func getAllObjects(from scene: SceneModel) -> [SceneObject]

    /// 주어진 ID에 해당하는 `SceneObject` 반환
    /// - Parameters:
    ///   - id: 찾을 오브젝트의 식별자
    ///   - scene: 조회 대상 `SceneModel`
    /// - Returns: 일치 항목이 있으면 `SceneObject`, 없으면 `nil`
    func getObject(by id: UUID, from scene: SceneModel) -> SceneObject?

    // MARK: - 변경 (배열 & 인덱스 일관성 보장)

    /// 새 `SceneObject`를 씬에 추가하고, **인덱스에도 등록**
    /// - Parameters:
    ///   - object: 추가할 오브젝트
    ///   - scene: 수정 대상 `SceneModel`(값 타입이므로 `inout`)
    func addObject(_ object: SceneObject, to scene: inout SceneModel)

    /// 지정한 오브젝트를 **변경 클로저**로 수정
    /// 변경 전에/후에 `assetId`가 달라졌다면, **인덱스도 자동으로 리맵**
    /// - Parameters:
    ///   - id: 수정할 오브젝트의 식별자
    ///   - scene: 수정 대상 `SceneModel`(값 타입이므로 `inout`)
    ///   - mutate: 오브젝트를 직접 수정하는 클로저(`inout SceneObject`)
    func updateObject(id: UUID, in scene: inout SceneModel, mutate: (inout SceneObject) -> Void)

    /// 지정한 오브젝트를 씬에서 삭제하고, **인덱스에서도 해제**
    /// - Parameters:
    ///   - id: 삭제할 오브젝트의 식별자
    ///   - scene: 수정 대상 `SceneModel`(값 타입이므로 `inout`)
    func deleteObject(by id: UUID, from scene: inout SceneModel)

    /// 여러 오브젝트를 **일괄 삭제**하고, 대응되는 인덱스도 함께 일괄 해제
    /// - Parameters:
    ///   - ids: 삭제할 오브젝트 ID 배열
    ///   - scene: 수정 대상 `SceneModel`(값 타입이므로 `inout`)
    func deleteObjects(by ids: [UUID], from scene: inout SceneModel)

    // MARK: - 유틸리티 (의도 중심 고수준 API)

    /// 특정 `assetId`를 **참조하는 모든** `SceneObject`를 찾아 **원자적으로 제거**
    /// 내부적으로 인덱스에서 대상 집합을 먼저 조회하여 효율적으로 동작
    /// - Parameters:
    ///   - scene: 수정 대상 `SceneModel`(값 타입이므로 `inout`)
    ///   - assetId: 참조 제거 기준이 되는 에셋 식별자.
    /// - Returns: 제거된 `SceneObject`들의 스냅샷(후속 처리: 엔티티 정리/로깅 등)
    @discardableResult
    func removeAllReferencing(from scene: inout SceneModel, assetId: String) -> [SceneObject]

    /// 배열 내에서 `assetId`를 **일괄 치환**하고, 인덱스(usage)도 **새 값으로 재등록**
    /// - Parameters:
    ///   - scene: 수정 대상 `SceneModel`(값 타입이므로 `inout`)
    ///   - old: 기존 에셋 식별자
    ///   - new: 새 에셋 식별자
    /// - Returns: 영향을 받은 오브젝트들의 ID 목록(선택적 UI 갱신/로깅에 사용)
    @discardableResult
    func remapAssetId(in scene: inout SceneModel, old: String, new: String) -> [UUID]
}
