import RealityKit
import UIKit

enum EntityBoundBoxApplier {
    static func addBoundAuto(to entity: ModelEntity) {
        switch EntityClassifier.classify(entity) {
        case .sound:
            addCircleBound(to: entity, diameter: 0.15)
        case .image:
            addRectBound(to: entity)
        case .floor:
            addRectBound(to: entity, isFloor: true)
        default:
            return
        }
    }
    
    // MARK: - Internal: Rectangle (이미지)
    
    private static func addRectBound(to entity: ModelEntity, isFloor: Bool = false) {
        let width: Float
        let height: Float
        let expandedW: Float
        let expandedH: Float

        if isFloor {
            let floorSize: Float = SceneConstants.floorSize
            width = floorSize
            height = floorSize

            let glowCorrection = calculateGlowCorrection(width: floorSize, height: floorSize)
            expandedW = floorSize + glowCorrection.width
            expandedH = floorSize + glowCorrection.height
        } else {
            // collision shapes에서 width와 height 가져오기
            if let collision = entity.collision,
            let firstShape = collision.shapes.first {
                let bounds = firstShape.bounds
                width = bounds.max.x - bounds.min.x
                height = bounds.max.y - bounds.min.y
                let baseLine = min(width, height)
                
                let glowCorrection = calculateGlowCorrection(width: width, height: height)
                expandedW = width + baseLine * 1 / 4 + glowCorrection.width
                expandedH = height + baseLine * 1 / 4 + glowCorrection.height
            } else {
                let planeEntity = entity.findEntity(named: "imagePlane") as? ModelEntity
                let planeBounds = planeEntity?.visualBounds(relativeTo: planeEntity)
                width = planeBounds?.extents.x ?? 0.0
                height = planeBounds?.extents.y ?? 0.0
                let baseLine = min(width, height)
                
                let glowCorrection = calculateGlowCorrection(width: width, height: height)
                expandedW = width + baseLine * 1 / 4 + glowCorrection.width
                expandedH = height + baseLine * 1 / 4 + glowCorrection.height
            }
        }
        
        let texW: CGFloat = 1024
        let texH: CGFloat = max(768, texW * CGFloat(expandedH / max(expandedW, 0.001)))
        let cornerRadius = isFloor ? 0.01 : min(texW, texH) * 0.06
        
        guard let tex = makeGlowRectTexture(
            size: CGSize(width: texW, height: texH),
            cornerRadius: cornerRadius,
            isFloor: isFloor
        ) else { return }
        
        let plane = MeshResource.generatePlane(width: expandedW, height: expandedH)
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(texture: .init(tex))
        mat.emissiveColor = .init(texture: .init(tex))
        mat.emissiveIntensity = 1.5
        mat.blending = .transparent(opacity: 1.0)
        mat.faceCulling = .none
        
        let bound = ModelEntity(mesh: plane, materials: [mat])
        bound.name = "boundBox"
        
        if isFloor {
            bound.position = SIMD3(0, 0.0001, 0)
            let rotationAngle: Float = -.pi / 2.0
            let rotationAxis = SIMD3<Float>(x: 1.0, y: 0.0, z: 0.0)
            bound.orientation = simd_quatf(angle: rotationAngle, axis: rotationAxis)
        }
        
        entity.addChild(bound)
    }
    
    // MARK: - Internal: Circle (사운드)
    
    private static func addCircleBound(to entity: ModelEntity, diameter: Float) {
        let offset: Float = 0.08
        let expandedD = diameter + offset * 2.5 * 0.3

        let texSize: CGFloat = 1024
        guard let tex = makeGlowCircleTexture(size: CGSize(width: texSize, height: texSize)) else { return }

        let plane = MeshResource.generatePlane(width: expandedD/2, height: expandedD/2)

        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(texture: .init(tex))
        mat.emissiveColor = .init(texture: .init(tex))
        mat.emissiveIntensity = 1.5
        mat.blending = .transparent(opacity: 1.0)
        mat.faceCulling = .none

        let bound = ModelEntity(mesh: plane, materials: [mat])
        bound.name = "boundBox"

        let vb = entity.visualBounds(relativeTo: entity)
        bound.position = vb.center + SIMD3<Float>(0, 0, -0.001)
        entity.addChild(bound)
    }

    
    static func removeBoundBox(from entity: ModelEntity) {
        entity.children
            .filter { $0.name == "boundBox" }
            .forEach { $0.removeFromParent() }
    }
    
    // MARK: - Textures
    
    private static func makeGlowRectTexture(size: CGSize, cornerRadius: CGFloat, color: UIColor = .white, isFloor: Bool, rotation: SIMD3<Float>? = nil) -> TextureResource? {
        let stroke: CGFloat = 1.5
        let glow: CGFloat = 40
        let inset = glow + stroke / 1.5
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            ctx.cgContext.saveGState()
            ctx.cgContext.setShadow(offset: .zero, blur: glow * 0.6,
                                    color: color.withAlphaComponent(0.4).cgColor)
            color.withAlphaComponent(1).setStroke()
            path.lineWidth = isFloor ? (stroke + glow * 0.4) / 2 : stroke + glow * 0.4
            path.stroke()
            ctx.cgContext.restoreGState()
        }
        guard let cg = image.cgImage else { return nil }
        return try? TextureResource(image: cg, options: .init(semantic: .color))
    }
    
    private static func makeGlowCircleTexture(size: CGSize, color: UIColor = .white) -> TextureResource? {
        let stroke: CGFloat = 1.5
        let glow: CGFloat = 48
        let inset = glow + stroke / 1.5
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
        let path = UIBezierPath(ovalIn: rect)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            ctx.cgContext.saveGState()
            ctx.cgContext.setShadow(offset: .zero, blur: glow * 0.6,
                                    color: color.withAlphaComponent(0.4).cgColor)
            color.withAlphaComponent(1).setStroke()
            path.lineWidth = stroke + glow * 0.4
            path.stroke()
            ctx.cgContext.restoreGState()
            
            color.withAlphaComponent(0.25).setStroke()
            path.lineWidth = stroke
            path.stroke()
        }
        guard let cg = image.cgImage else { return nil }
        return try? TextureResource(image: cg, options: .init(semantic: .color))
    }

    /// Glow 효과로 인해 줄어드는 크기를 보정하기 위한 값 계산
    static func calculateGlowCorrection(width: Float, height: Float) -> (width: Float, height: Float) {
        let texW: CGFloat = 1024
        let texH: CGFloat = max(768, texW * CGFloat(height / max(width, 0.001)))
        let inset: CGFloat = 41  // makeGlowRectTexture의 inset 값 (glow + stroke/1.5)
        
        let correctionW = Float((inset * 2) / texW) * width
        let correctionH = Float((inset * 2) / texH) * height
        
        return (correctionW, correctionH)
    }
}
