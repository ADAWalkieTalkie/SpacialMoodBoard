import RealityKit
import UIKit

struct EntityBoundBoxApplier {
    
    func addBoundBox(to entity: ModelEntity, width: Float, height: Float) {
        let offset: Float = 0.08
        let expandedW = width + offset * 2.5
        let expandedH = height + offset * 2.5
        
        // 텍스처 파라미터 조정
        let texW: CGFloat = 1024
        let texH: CGFloat = max(768, texW * CGFloat(expandedH / max(expandedW, 0.001)))
        let cornerRadius = min(texW, texH) * 0.06
        
        guard let tex = makeGlowTexture(
            size: CGSize(width: texW, height: texH),
            cornerRadius: cornerRadius
        ) else { return }
        
        let plane = MeshResource.generateBox(width: expandedW, height: expandedH, depth: 0.001)
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(texture: .init(tex))
        mat.emissiveColor = .init(texture: .init(tex))
        mat.emissiveIntensity = 1.5
        mat.blending = .transparent(opacity: 1.0)
        
        let boundBox = ModelEntity(mesh: plane, materials: [mat])
        boundBox.name = "boundBox"
        
        let vb = entity.visualBounds(relativeTo: entity)
        boundBox.position = vb.center + SIMD3(0, 0, -0.001)
        entity.addChild(boundBox)
    }
    
    func removeBoundBox(from entity: ModelEntity) {
        entity.children
            .filter { $0.name == "boundBox" }
            .forEach { $0.removeFromParent() }
    }
    
    // 향후 color 변환 시 color 변수 변화
    private func makeGlowTexture(size: CGSize, cornerRadius: CGFloat, color: UIColor = .white) -> TextureResource? {
        let stroke: CGFloat = 1.5
        let glow: CGFloat = 40
        let inset = glow + stroke / 1.5
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // 외곽 글로우 (더 넓고 부드럽게)
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
}
