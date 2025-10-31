import RealityKit


/// Entity를 분류하는 유틸리티 구조체
struct EntityClassifier {
    
    /// Entity의 타입을 반환
    /// - Parameter entity: 분류할 Entity
    /// - Returns: EntityType (.image, .sound, .floor, 또는 .unknown)
    static func classify(_ entity: Entity) -> EntityType {
        guard let modelEntity = entity as? ModelEntity else {
            return .unknown
        }
        
        // 1. SoundEntity는 SoundControllerComponent를 가지고 있음
        if modelEntity.components[SoundControllerComponent.self] != nil {
            return .sound
        }
        
        // 2. FloorEntity는 name이 "floorRoot"로 설정되어 있음
        if modelEntity.name == "floorRoot" {
            return .floor
        }
        
        // 3. SoundControllerComponent가 없고 name도 "floorRoot"가 아니면 ImageEntity로 가정
        return .image
    }
    
    /// Entity가 SoundEntity인지 확인
    /// - Parameter entity: 확인할 Entity
    /// - Returns: SoundEntity면 true, 아니면 false
    static func isSoundEntity(_ entity: Entity) -> Bool {
        return classify(entity) == .sound
    }
    
    /// Entity가 ImageEntity인지 확인
    /// - Parameter entity: 확인할 Entity
    /// - Returns: ImageEntity면 true, 아니면 false
    static func isImageEntity(_ entity: Entity) -> Bool {
        return classify(entity) == .image
    }
    
    /// Entity가 FloorEntity인지 확인
    /// - Parameter entity: 확인할 Entity
    /// - Returns: FloorEntity면 true, 아니면 false
    static func isFloorEntity(_ entity: Entity) -> Bool {
        return classify(entity) == .floor
    }
}