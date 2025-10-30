import Foundation

// SceneObjectRepository

@MainActor
final class SceneObjectRepository: SceneObjectRepositoryInterface {
    private let usageIndex: AssetUsageIndexProtocol
    
    init(usageIndex: AssetUsageIndexProtocol) {
        self.usageIndex = usageIndex
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
        print("🆕 Added SceneObject: \(object.id)")
    }
    
    func updateObject(id: UUID, in scene: inout SceneModel, mutate: (inout SceneObject) -> Void) {
        guard let index = scene.sceneObjects.firstIndex(where: { $0.id == id }) else {
            return
        }
        mutate(&scene.sceneObjects[index])
    }
    
    func deleteObject(by id: UUID, from scene: inout SceneModel) {
        guard let object = scene.sceneObjects.first(where: { $0.id == id }) else {
            return
        }
        
        scene.sceneObjects.removeAll { $0.id == id }
        usageIndex.unregister(objectId: id, assetId: object.assetId)
        print("🗑️ Removed SceneObject: \(id)")
    }
    
    func deleteObjects(by ids: [UUID], from scene: inout SceneModel) {
        let idSet = Set(ids)
        let objectsToRemove = scene.sceneObjects.filter { idSet.contains($0.id) }
        
        scene.sceneObjects.removeAll { idSet.contains($0.id) }
        
        for object in objectsToRemove {
            usageIndex.unregister(objectId: object.id, assetId: object.assetId)
        }
        print("🗑️ Removed \(objectsToRemove.count) SceneObjects")
    }
}