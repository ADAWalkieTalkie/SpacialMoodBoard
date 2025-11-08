import RealityKit
import UIKit

struct EntityBoundBoxApplier {
    func addBoundAuto(to entity: ModelEntity, width: Float, height: Float) {
        switch EntityClassifier.classify(entity) {
        case .sound:
            let diameter = max(width, height)
            addCircleBound(to: entity, diameter: diameter)
        case .image:
            addRectBound(to: entity, width: width, height: height)
        default:
            return
        }
    }
    
    // MARK: - Internal: Rectangle (이미지)
    
    private func addRectBound(to entity: ModelEntity, width: Float, height: Float) {
        let offset: Float = 0.08
        let expandedW = width  + offset * 2.5 * 0.3
        let expandedH = height + offset * 2.5 * 0.3
        
        let texW: CGFloat = 1024
        let texH: CGFloat = max(768, texW * CGFloat(expandedH / max(expandedW, 0.001)))
        let cornerRadius = min(texW, texH) * 0.06
        
        guard let tex = makeGlowRectTexture(
            size: CGSize(width: texW, height: texH),
            cornerRadius: cornerRadius
        ) else { return }
        
        let plane = MeshResource.generateBox(width: expandedW, height: expandedH, depth: 0.001)
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(texture: .init(tex))
        mat.emissiveColor = .init(texture: .init(tex))
        mat.emissiveIntensity = 1.5
        mat.blending = .transparent(opacity: 1.0)
        
        let bound = ModelEntity(mesh: plane, materials: [mat])
        bound.name = "boundBox"
        
        let vb = entity.visualBounds(relativeTo: entity)
        bound.position = vb.center + SIMD3(0, 0, -0.001)
        entity.addChild(bound)
    }
    
    // MARK: - Internal: Circle (사운드)
    
    private func addCircleBound(to entity: ModelEntity, diameter: Float) {
        let offset: Float = 0.08
        let expandedD = diameter + offset * 2.5 * 0.3

        let texSize: CGFloat = 1024
        guard let tex = makeGlowCircleTexture(size: CGSize(width: texSize, height: texSize)) else { return }

        let plane = MeshResource.generateBox(width: expandedD/2, height: expandedD/2, depth: 0.001)

        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(texture: .init(tex))
        mat.emissiveColor = .init(texture: .init(tex))
        mat.emissiveIntensity = 1.5
        mat.blending = .transparent(opacity: 1.0)

        let bound = ModelEntity(mesh: plane, materials: [mat])
        bound.name = "boundBox"

        let vb = entity.visualBounds(relativeTo: entity)
        bound.position = vb.center + SIMD3<Float>(0, 0, -0.001)
        entity.addChild(bound)
    }

    
    func removeBoundBox(from entity: ModelEntity) {
        entity.children
            .filter { $0.name == "boundBox" }
            .forEach { $0.removeFromParent() }
    }
    
    // MARK: - Textures
    
    private func makeGlowRectTexture(size: CGSize, cornerRadius: CGFloat, color: UIColor = .white) -> TextureResource? {
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
            path.lineWidth = stroke + glow * 0.4
            path.stroke()
            ctx.cgContext.restoreGState()
        }
        guard let cg = image.cgImage else { return nil }
        return try? TextureResource(image: cg, options: .init(semantic: .color))
    }
    
    private func makeGlowCircleTexture(size: CGSize, color: UIColor = .white) -> TextureResource? {
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
}
