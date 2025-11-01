import Foundation
import RealityKit
import UIKit

/// Entity에 boundBox를 추가/제거하는 Helper
struct EntityBoundBoxApplier {
    
    /// Entity에 boundBox 추가
    /// - Parameters:
    ///   - entity: boundBox를 추가할 ModelEntity
    ///   - width: Entity의 너비
    ///   - height: Entity의 높이
    /// - Returns: 생성된 boundBox Entity (나중에 제거할 때 사용)
    func addBoundBox(to entity: ModelEntity, width: Float, height: Float) -> ModelEntity? {
        let expandedWidth = width * 1.2
        let expandedHeight = height * 1.2
        
        let cornerRadius = min(expandedWidth, expandedHeight) * 0.5
        let boundBoxMesh = MeshResource.generateBox(
            width: expandedWidth,
            height: expandedHeight,
            depth: 0.04,
            cornerRadius: cornerRadius
        )
        
        // emissiveColor와 blending을 이용해 밝고 투명하게
        var boundMaterial = UnlitMaterial()
        boundMaterial.color = .init(tint: UIColor.cyan.withAlphaComponent(0.8))
        boundMaterial.blending = .transparent(opacity: 0.5)
        
        let boundBoxEntity = ModelEntity(mesh: boundBoxMesh, materials: [boundMaterial])
        boundBoxEntity.name = "boundBox"
        boundBoxEntity.position = SIMD3(0, 0, 0)
        boundBoxEntity.setParent(entity)
        
        return boundBoxEntity
    }
    
    /// Entity에서 boundBox 제거
    /// - Parameter entity: boundBox를 제거할 ModelEntity
    func removeBoundBox(from entity: ModelEntity) {
        entity.children
            .filter { $0.name == "boundBox" }
            .forEach { $0.removeFromParent() }
    }
}