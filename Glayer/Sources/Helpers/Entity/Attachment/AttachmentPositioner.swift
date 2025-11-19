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
        let attachmentBounds = attachment.visualBounds(relativeTo: nil)
        let parentScale = parent.scale(relativeTo: nil)

        let baseLine: Float
        let margin: Float

        if let imagePlane = parent.findEntity(named: "imagePlane") {
            let planeBounds = imagePlane.visualBounds(relativeTo: parent)
            let planeMargin = min(planeBounds.extents.x, planeBounds.extents.y) // 높이
            margin = planeMargin * 1/4
            baseLine = planeBounds.max.y
            print("planeMargin: \(planeMargin)")
        } else {
            baseLine = objectBounds.max.y
            margin = min(objectBounds.extents.x, objectBounds.extents.y) * 1/4
        }

        let attachmentHalfHeight = (attachmentBounds.extents.y / 2) * parentScale.y
        
        let yOffset: Float = baseLine + margin + attachmentHalfHeight //objectBounds.max.y + margin + attachmentMargin
        attachment.position = SIMD3<Float>(0, yOffset, 0.01)
    }
    
    /// 중앙 위치로 Attachment 설정
    /// - Parameters:
    ///   - attachment: 위치를 설정할 Attachment Entity
    ///   - parent: Attachment가 첨부될 부모 Entity
    static func positionAtMiddle(_ attachment: Entity, relativeTo parent: Entity) {
        // 중앙 위치는 parent의 중심점
        attachment.position = SIMD3<Float>(0, 0, 0.01)
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