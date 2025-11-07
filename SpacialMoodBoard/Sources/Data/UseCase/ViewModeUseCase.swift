import Foundation
import RealityKit

/// ViewMode 전환을 담당하는 UseCase
/// - ImageEntity: InputTargetComponent 제거/복원
/// - SoundEntity: InputTargetComponent 제거/복원 + Material opacity 조절
@MainActor
struct ViewModeUseCase {
    
    private let entityRepository: EntityRepositoryInterface
    private let viewMode: Bool
    
    init(entityRepository: EntityRepositoryInterface, viewMode: Bool) {
        self.entityRepository = entityRepository
        self.viewMode = viewMode
    }

    func execute() {
        if viewMode {
            viewModeOnAll()
        } else {
            viewModeOffAll()
        }
    }
    
    /// ViewMode OFF: 엔티티의 상호작용을 비활성화
    /// - Parameter entityIds: 처리할 엔티티 ID 배열
    private func viewModeOff(for entityIds: [UUID]) {
        for id in entityIds {
            guard let entity = entityRepository.getEntity(for: id) else {
                continue
            }
            
            let entityType = EntityClassifier.classify(entity)
            
            switch entityType {
            case .image:
                // ImageEntity: InputTargetComponent 제거
                entity.components.remove(InputTargetComponent.self)
                
            case .sound:
                // SoundEntity: InputTargetComponent 제거 + opacity 0
                entity.components.remove(InputTargetComponent.self)
                SoundEntity.setIconVisible(false, on: entity)
                
            case .floor, .unknown:
                // FloorEntity와 알 수 없는 타입은 처리하지 않음
                break
            }
        }
    }
    
    /// ViewMode ON: 엔티티의 상호작용을 활성화
    /// - Parameter entityIds: 처리할 엔티티 ID 배열
    private func viewModeOn(for entityIds: [UUID]) {
        for id in entityIds {
            guard let entity = entityRepository.getEntity(for: id) else {
                continue
            }
            
            let entityType = EntityClassifier.classify(entity)
            
            switch entityType {
            case .image:
                // ImageEntity: InputTargetComponent 복원
                entity.components.set(InputTargetComponent())
                
            case .sound:
                // SoundEntity: InputTargetComponent 복원 + opacity 1
                entity.components.set(InputTargetComponent())
                SoundEntity.setIconVisible(true, on: entity)
                
            case .floor, .unknown:
                // FloorEntity와 알 수 없는 타입은 처리하지 않음
                break
            }
        }
    }
    
    /// 모든 엔티티에 대해 ViewMode OFF
    func viewModeOffAll() {
        let allEntityIds = entityRepository.getCachedEntities().keys.map { $0 }
        viewModeOff(for: Array(allEntityIds))
    }
    
    /// 모든 엔티티에 대해 ViewMode ON
    func viewModeOnAll() {
        let allEntityIds = entityRepository.getCachedEntities().keys.map { $0 }
        viewModeOn(for: Array(allEntityIds))
    }
}