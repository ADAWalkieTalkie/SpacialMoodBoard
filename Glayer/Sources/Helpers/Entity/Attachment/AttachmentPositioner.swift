import Foundation
import RealityKit

/// Attachment의 위치를 설정하는 헬퍼
enum AttachmentPositioner {
    
    /// 상단 위치로 Attachment 설정 (EditBarAttachment 위치)
    /// - Parameters:
    ///   - attachment: 위치를 설정할 Attachment Entity
    ///   - parent: Attachment가 첨부될 부모 Entity
    ///   - isVolumeMode: Volume 모드 여부
    static func positionAtTop(_ attachment: Entity, relativeTo parent: Entity, isVolumeMode: Bool) {
        let objectBounds = parent.visualBounds(relativeTo: parent)
        let attachmentBounds = attachment.visualBounds(relativeTo: nil)
        let parentScale: SIMD3<Float> = parent.scale(relativeTo: nil)

        let baseLine: Float
        let margin: Float

        if let imagePlane = parent.findEntity(named: "imagePlane") {
            let planeBounds = imagePlane.visualBounds(relativeTo: parent)
            let planeMargin = min(planeBounds.extents.x, planeBounds.extents.y)
            
            let width = planeBounds.extents.x
            let height = planeBounds.extents.y
            let glowCorrection = EntityBoundBoxApplier.calculateGlowCorrection(width: width, height: height)
            
            baseLine = planeBounds.max.y
            margin = planeMargin/4 - glowCorrection.height/2
        } else {
            // Sound의 경우: SoundVisual 노드 찾기
            if let soundVisual = parent.findEntity(named: "SoundVisual") {
                let soundVisualBounds = soundVisual.visualBounds(relativeTo: parent)
                baseLine = soundVisualBounds.max.y
                
                let width = soundVisualBounds.extents.x
                let height = soundVisualBounds.extents.y
                let glowCorrection = EntityBoundBoxApplier.calculateGlowCorrection(width: width, height: height)
                margin = width/4 + glowCorrection.height/2
            } else {
                // fallback: SoundVisual이 없으면 기존 방식
                let width = objectBounds.extents.x
                let height = objectBounds.extents.y
                let glowCorrection = EntityBoundBoxApplier.calculateGlowCorrection(width: width, height: height)
                
                baseLine = objectBounds.max.y
                margin = objectBounds.extents.x/4 - glowCorrection.height/2
            }
        }

        let attachmentHalfHeight = (attachmentBounds.extents.y / 2) / parentScale.y
        
        let yOffset: Float = baseLine + attachmentHalfHeight + margin // 이미지 최상단 + 어태치 먼트 바닥 + 마진(사진 마진/4 - 라인값/2)
        attachment.position = SIMD3<Float>(0, yOffset, 0.01)
    }

    /// CropAttachment를 이미지 상단에 위치시킴
    /// - Parameters:
    ///   - attachment: 위치를 설정할 CropControl Attachment Entity
    ///   - parent: Attachment가 첨부될 부모 Entity (이미지 엔티티)
    ///   - isVolumeMode: Volume 모드 여부
    static func positionAboveCrop(_ attachment: Entity, relativeTo parent: Entity, isVolumeMode: Bool) {
        guard let imagePlane = parent.findEntity(named: "imagePlane") else { return }

        let planeBounds = imagePlane.visualBounds(relativeTo: parent)
        let attachmentBounds = attachment.visualBounds(relativeTo: nil)
        let parentScale = parent.scale(relativeTo: nil)

        // planeMargin과 glowCorrection 계산
        let planeMargin = min(planeBounds.extents.x, planeBounds.extents.y)

        let width = planeBounds.extents.x
        let height = planeBounds.extents.y
        let glowCorrection = EntityBoundBoxApplier.calculateGlowCorrection(width: width, height: height)

        // imagePlane 상단에 위치
        let imagePlaneTop = planeBounds.max.y
        let attachmentHalfHeight = (attachmentBounds.extents.y / 2) / parentScale.y
        let margin = planeMargin/4 - glowCorrection.height/2

        let yOffset = imagePlaneTop + attachmentHalfHeight + margin
        attachment.position = SIMD3<Float>(0, yOffset, 0.01)
    }

    /// 중앙 위치로 Attachment 설정
    /// - Parameters:
    ///   - attachment: 위치를 설정할 Attachment Entity
    ///   - parent: Attachment가 첨부될 부모 Entity
    static func positionAtMiddle(_ attachment: Entity, relativeTo parent: Entity) {
        // 중앙 위치는 parent의 중심점
        attachment.position = SIMD3<Float>(0, 0, 0)
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
