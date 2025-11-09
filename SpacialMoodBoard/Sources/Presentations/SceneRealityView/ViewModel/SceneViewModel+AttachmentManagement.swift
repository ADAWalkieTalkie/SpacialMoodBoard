import Foundation
import RealityKit
import SwiftUI

// MARK: - Attachment Management

extension SceneViewModel {
    
    // MARK: - Entity Selection Handler
    /// selectedEntity 변화를 처리하는 핵심 로직
    func handleSelectedEntityChange(oldValue: ModelEntity?, newValue: ModelEntity?) {
        let oldName = oldValue?.name
        let newName = newValue?.name
        
        // 케이스 1: nil → nil (아무것도 안 함)
        guard oldName != nil || newName != nil else { return }
        
        // 케이스 2: entity → 같은 entity (중복 클릭)
        if let oldName = oldName, let newName = newName, oldName == newName {
            attachmentTimer?.reset()
            return
        }
        
        // 케이스 3: entity → nil (선택 해제)
        if oldName != nil && newName == nil {
            attachmentTimer?.cancel()
            attachmentTimer = nil
            
            if let entity = oldValue {
                removeAttachment(from: entity)
            }
            currentAttachmentEntity = nil
            return
        }
        
        // 케이스 4: nil → entity (새로운 선택)
        if oldName == nil && newName != nil {
            if let entity = newValue {
                addAttachmentAndStartTimer(for: entity)
            }
            return
        }
        
        // 케이스 5: entity → 다른 entity (선택 변경)
        if let oldName = oldName, let newName = newName, oldName != newName {
            // 기존 entity에서 attachment 제거
            if let oldEntity = oldValue {
                removeAttachment(from: oldEntity)
            }
            
            // 새 entity에 attachment 추가
            if let newEntity = newValue {
                addAttachmentAndStartTimer(for: newEntity)
            }
            return
        }
    }
    
    // MARK: - Timer Control (Public)
    
    /// 타이머를 리셋 (외부에서 호출 가능)
    func resetAttachmentTimer() {
        attachmentTimer?.reset()
    }
    
    /// 타이머를 멈춤 (외부에서 호출 가능)
    func cancelAttachmentTimer() {
        attachmentTimer?.cancel()
    }
    
    // MARK: - Private Helpers
    
    /// Entity에 attachment를 추가하고 타이머 시작
    private func addAttachmentAndStartTimer(for entity: ModelEntity) {
        guard let objectId = UUID(uuidString: entity.name),
              let sceneObject = sceneObjects.first(where: { $0.id == objectId })
        else { return }
        
        let objectType = sceneObject.type
        
        // 기존 타이머 취소
        attachmentTimer?.cancel()
        attachmentTimer = nil
        
        // Attachment 추가
        switch objectType {
        case .image:
            addImageEditBarAttachment(to: entity, objectId: objectId, objectType: objectType)
            
        case .sound:
            addSoundEditBarAttachment(to: entity, objectId: objectId, objectType: objectType, sceneObject: sceneObject)
        }
        
        // 현재 attachment entity 저장
        currentAttachmentEntity = entity
        
        // 타이머 생성 및 시작 (entity를 캡처)
        attachmentTimer = FunctionTimer(duration: 5.0) { [weak self] in
            guard let self else { return }
            
            // 타이머 생성 시점의 entity 사용
            self.removeAttachment(from: entity)
            
            // selectedEntity가 여전히 같은 entity면 nil로 설정
            if self.selectedEntity?.name == entity.name {
                self.selectedEntity = nil
            }
            
            self.currentAttachmentEntity = nil
        }
        attachmentTimer?.start()
    }
    
    /// 모든 attachment 제거 (안전성을 위한 함수)
    private func removeAllAttachments() {
        for entity in entityRepository.getCachedEntities().values {
            removeAttachment(from: entity)
        }
    }

    /// 특정 Entity의 attachment만 제거
    private func removeAttachment(from entity: ModelEntity) {
        // boundBox 제거
        entityBoundBoxApplier.removeBoundBox(from: entity)

        // objectAttachment 제거
        entity.children
            .filter { $0.name == "objectAttachment" }
            .forEach { $0.removeFromParent() }
    }
}