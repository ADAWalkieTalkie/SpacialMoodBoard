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
    
    /// 모든 attachment 제거 (안전성을 위한 함수)
    func removeAllAttachments() {
        for entity in entityRepository.getCachedEntities().values {
            removeAttachment(from: entity)
        }
    }

    /// 특정 Entity의 attachment만 제거
    func removeAttachment(from entity: ModelEntity) {
        // boundBox 제거
        entityBoundBoxApplier.removeBoundBox(from: entity)

        // objectAttachment 제거
        entity.children
            .filter { $0.name == "objectAttachment" }
            .forEach { $0.removeFromParent() }

        // soundNameAttachment 제거 추가
        entity.children
            .filter { $0.name == "soundNameAttachment" }
            .forEach { $0.removeFromParent() }
        }
}