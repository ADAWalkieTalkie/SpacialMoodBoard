import RealityKit
import CoreGraphics

enum EntityAttachmentSizeDeterminator {
    static let scaleFactor: Float = 1
    private static let minimumObjectScale: Float = 0.05
    private static let minimumAttachmentReferenceScale: Float = 0.25
    private static let fallbackAttachmentScale: Float = 1.0
    private static let maxDistanceForScaling: Float = 20.0

    /// Attachment의 최종 스케일 계산 (모든 보정 포함)
    /// - Parameters:
    ///   - headPosition: 헤드 위치
    ///   - entity: Attachment가 붙을 대상 엔티티
    ///   - isVolumeMode: Volume 모드 여부
    /// - Returns: 최종 스케일 (SIMD3<Float>)
    static func calculateFinalScale(
        headPosition: SIMD3<Float>,
        entity: ModelEntity,
        isVolumeMode: Bool
    ) -> SIMD3<Float> {
        // 1. 엔티티의 월드 좌표 위치
        let entityWorldPosition = entity.position(relativeTo: nil)
        let entityScale = attachmentReferenceScale(from: entity.scale.x)
        
        // 2. 거리 기반 스케일 계산
        let distanceScale = calculateScale(
            headPosition: headPosition,
            entityPosition: entityWorldPosition
        )
        
        // 3. Volume 모드
        if isVolumeMode {
            let s = sanitizedAttachmentScale(2 / entityScale)
            return SIMD3<Float>(repeating: s)
        } else {
            let immersiveBase: Float = 0.8
            
            let s = sanitizedAttachmentScale(immersiveBase * distanceScale * scaleFactor / entityScale)
            return SIMD3<Float>(repeating: s)
        }
    }
        
    /// 헤드 위치와 엔티티 위치 기반으로 스케일 계산 (기본)
    /// - Parameters:
    ///   - headPosition: 헤드 위치
    ///   - entityPosition: 엔티티 위치
    /// - Returns: 계산된 스케일
    static func calculateScale(
        headPosition: SIMD3<Float>,
        entityPosition: SIMD3<Float>
    ) -> Float {
        let distance = distanceCalculation(from: headPosition, to: entityPosition)
        return sizeCalculation(from: distance)
    }

    /// 거리 계산
    /// - Parameters:
    ///   - headPosition: 머리 위치
    ///   - targetPosition: 대상 위치
    /// - Returns: 거리
    private static func distanceCalculation(from headPosition: simd_float3, to targetPosition: simd_float3) -> Float {
        let distance = simd_distance(headPosition, targetPosition)
        guard distance.isFinite else { return 1.0 }
        return distance
    }

    /// 거리에 따라 크기 계산
    /// - Parameters:
    ///   - distance: 거리
    /// - Returns: 크기 (가까울 때는 최소 1.0 유지, 멀어질 때는 1.1배씩 증가)
    private static func sizeCalculation(from distance: Float) -> Float {
        let clampedDistance = min(max(distance, 0), maxDistanceForScaling)
        let growth = pow(1.1, max(0, clampedDistance - 1.0))
        return max(1.0, growth)
    }

    private static func attachmentReferenceScale(from objectScale: Float) -> Float {
        let safeObjectScale = sanitizedObjectScale(objectScale)
        return max(safeObjectScale, minimumAttachmentReferenceScale)
    }

    private static func sanitizedObjectScale(_ objectScale: Float) -> Float {
        guard objectScale.isFinite else { return 1.0 }
        return max(abs(objectScale), minimumObjectScale)
    }

    private static func sanitizedAttachmentScale(_ scale: Float) -> Float {
        guard scale.isFinite else { return fallbackAttachmentScale }
        return max(scale, 0.001)
    }
}

// MARK: - CropAttachmentSize

extension EntityAttachmentSizeDeterminator {
    /// CropAttachment(ViewAttachment)가 RealityKit 상에서 boundBox의 크기와 정확히 동일해지도록 스케일을 조정
    /// - Parameters:
    ///   - attachment: 크기를 맞출 대상 (CropAttachment 엔티티)
    ///   - parent:  이미지 엔티티(ModelEntity)
    /// - Returns: 적용된 scaleX, scaleY (CGFloat) — SwiftUI CropOverlay 두께 조절에 사용
    @discardableResult
    static func scaleAttachmentToBound(
        _ attachment: Entity,
        on parent: ModelEntity
    ) -> (CGFloat, CGFloat) {
        guard let bound = parent.findEntity(named: "imagePlane") as? ModelEntity else {
            return (1.0, 1.0)
        }
        
        let boundVB = bound.visualBounds(relativeTo: parent)
        let targetWidth  = max(boundVB.extents.x, 0.0001)
        let targetHeight = max(boundVB.extents.y, 0.0001)
        
        let attachmentVB = attachment.visualBounds(relativeTo: parent)
        let currentWidth  = max(attachmentVB.extents.x, 0.0001)
        let currentHeight = max(attachmentVB.extents.y, 0.0001)
        
        let scaleX = targetWidth  / currentWidth
        let scaleY = targetHeight / currentHeight
        
        attachment.scale *= SIMD3<Float>(scaleX, scaleY, 1.0)
        
        let center = boundVB.center
        attachment.position = center + SIMD3<Float>(0, 0, 0.01)
        
        return (CGFloat(scaleX), CGFloat(scaleY))
    }
    
    /// RealityKit 상에서 이미지가 실제로 표시되는 plane(imagePlne)이 boundBox 안에서 차지하는 상대적인 비율을 계산
    /// - Parameter parent: 이미지 엔티티(ModelEntity)
    /// - Returns: (widthRatio, heightRatio) 0~1 범위의 비율
    static func imagePlaneRatio(
        on parent: ModelEntity
    ) -> (widthRatio: CGFloat, heightRatio: CGFloat) {
        guard
            let boundBox = parent.findEntity(named: "boundBox") as? ModelEntity,
            let imagePlane = parent.findEntity(named: "imagePlane") as? ModelEntity
        else {
            return (1.0, 1.0)
        }
        
        let boundVB = boundBox.visualBounds(relativeTo: parent)
        let imageVB = imagePlane.visualBounds(relativeTo: parent)
        
        print("boundVB: \(boundVB), imageVB:  \(imageVB)")
        
        let bw = max(boundVB.extents.x, 0.0001)
        let bh = max(boundVB.extents.y, 0.0001)
        let iw = max(imageVB.extents.x, 0.0001)
        let ih = max(imageVB.extents.y, 0.0001)
        
        let wRatio = iw / bw
        let hRatio = ih / bh
        
        return (CGFloat(wRatio), CGFloat(hRatio))
    }
}
