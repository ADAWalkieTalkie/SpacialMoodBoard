import Foundation
import RealityKit

/// Attachment의 위치를 설정하는 헬퍼
enum AttachmentPositioner {
    
    /// 상단 위치로 Attachment 설정 (EditBarAttachment 위치)
    /// - Parameters:
    ///   - attachment: 위치를 설정할 Attachment Entity
    ///   - parent: Attachment가 첨부될 부모 Entity
    static func positionAtTop(_ attachment: Entity, relativeTo parent: Entity) {
        let objectBounds = parent.visualBounds(relativeTo: parent)
        let attachmentBounds = attachment.visualBounds(relativeTo: parent)
        
        let yOffset = objectBounds.max.y + attachmentBounds.extents.y / 2 + 0.05 * 0.125
        attachment.position = SIMD3<Float>(0, yOffset, 0)
    }
    
    /// 중앙 위치로 Attachment 설정
    /// - Parameters:
    ///   - attachment: 위치를 설정할 Attachment Entity
    ///   - parent: Attachment가 첨부될 부모 Entity
    static func positionAtMiddle(_ attachment: Entity, relativeTo parent: Entity) {
        // 중앙 위치는 parent의 중심점
        attachment.position = SIMD3<Float>(0, 0, 0.1)
    }
    
    /// 하단 위치로 Attachment 설정
    /// - Parameters:
    ///   - attachment: 위치를 설정할 Attachment Entity
    ///   - parent: Attachment가 첨부될 부모 Entity
    static func positionAtBottom(_ attachment: Entity, relativeTo parent: Entity) {
        let objectBounds = parent.visualBounds(relativeTo: parent)
        let attachmentBounds = attachment.visualBounds(relativeTo: parent)
        
        let yOffset = objectBounds.min.y - attachmentBounds.extents.y / 2 - 0.05 * 0.125
        attachment.position = SIMD3<Float>(0, yOffset, 0)
    }
}