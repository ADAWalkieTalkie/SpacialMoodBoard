import Foundation

// SceneObjectRepository

@MainActor
final class SceneObjectRepository: SceneObjectRepositoryInterface {
    
    // MARK: - Properties
    
    private let usageIndex: AssetUsageIndexProtocol
    
    
    // MARK: - Init
    
    init(usageIndex: AssetUsageIndexProtocol) {
        self.usageIndex = usageIndex
    }
    
    // MARK: - Methods
    
    func syncIndex(with objects: [SceneObject]) {
        for o in objects { usageIndex.register(objectId: o.id, assetId: o.assetId) }
    }
    
    func getAllObjects(from scene: SceneModel) -> [SceneObject] {
        return scene.sceneObjects
    }
    
    func getObject(by id: UUID, from scene: SceneModel) -> SceneObject? {
        return scene.sceneObjects.first { $0.id == id }
    }
    
    func addObject(_ object: SceneObject, to scene: inout SceneModel) {
        scene.sceneObjects.append(object)
        usageIndex.register(objectId: object.id, assetId: object.assetId)
    }
    
    func updateObject(id: UUID, in scene: inout SceneModel, mutate: (inout SceneObject) -> Void) {
        guard let idx = scene.sceneObjects.firstIndex(where: { $0.id == id }) else { return }
        let oldAssetId = scene.sceneObjects[idx].assetId
        mutate(&scene.sceneObjects[idx])
        let newAssetId = scene.sceneObjects[idx].assetId
        if oldAssetId != newAssetId {
            usageIndex.unregister(objectId: id, assetId: oldAssetId)
            usageIndex.register(objectId: id, assetId: newAssetId)
        }
    }
    
    func deleteObject(by id: UUID, from scene: inout SceneModel) {
        guard let obj = scene.sceneObjects.first(where: { $0.id == id }) else { return }
        scene.sceneObjects.removeAll { $0.id == id }
        usageIndex.unregister(objectId: id, assetId: obj.assetId)
    }
    
    
    func deleteObjects(by ids: [UUID], from scene: inout SceneModel) {
        let idSet = Set(ids)
        let removed = scene.sceneObjects.filter { idSet.contains($0.id) }
        scene.sceneObjects.removeAll { idSet.contains($0.id) }
        for o in removed { usageIndex.unregister(objectId: o.id, assetId: o.assetId) }
    }
    
    @discardableResult
    func removeAllReferencing(from scene: inout SceneModel, assetId: String) -> [SceneObject] {
        let ids = Array(usageIndex.usages(of: assetId))
        guard !ids.isEmpty else { return [] }
        
        let idSet = Set(ids)
        let removed = scene.sceneObjects.filter { idSet.contains($0.id) }
        
        scene.sceneObjects.removeAll { idSet.contains($0.id) }
        
        for id in ids {
            usageIndex.unregister(objectId: id, assetId: assetId)
        }
        
        return removed
    }
    
    @discardableResult
    func remapAssetId(in scene: inout SceneModel, old: String, new: String) -> [UUID] {
        guard old != new else { return [] }
        var affected: [UUID] = []
        
        for i in scene.sceneObjects.indices where scene.sceneObjects[i].assetId == old {
            let id = scene.sceneObjects[i].id
            scene.sceneObjects[i].assetId = new
            affected.append(id)
            
            usageIndex.unregister(objectId: id, assetId: old)
            usageIndex.register(objectId: id, assetId: new)
        }
        return affected
    }
}
