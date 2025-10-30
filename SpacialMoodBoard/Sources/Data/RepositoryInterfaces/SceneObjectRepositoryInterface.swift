import Foundation

// SceneObjectRepositoryInterface

@MainActor
protocol SceneObjectRepositoryInterface: AnyObject {
    /// 모든 객체 조회
    func getAllObjects(from scene: SceneModel) -> [SceneObject]
    
    /// 단일 객체 조회
    func getObject(by id: UUID, from scene: SceneModel) -> SceneObject?
    
    /// 객체 추가 (인덱스 자동 등록)
    func addObject(_ object: SceneObject, to scene: inout SceneModel)
    
    /// 객체 속성 업데이트 (위치, 회전, 크기 등)
    func updateObject(id: UUID, in scene: inout SceneModel, mutate: (inout SceneObject) -> Void)
    
    /// 객체 삭제 (인덱스 자동 해제)
    func deleteObject(by id: UUID, from scene: inout SceneModel)
    
    /// 여러 객체 일괄 삭제
    func deleteObjects(by ids: [UUID], from scene: inout SceneModel)
}