import Foundation
import RealityKit
import UIKit

/// Human Scale 가이드 Entity를 생성하는 헬퍼
enum HumanScaleEntity {
    
    /// 휴먼 스케일 오브젝트 기본 크기
    static let defaultSize = SIMD2<Float>(x: 0.11, y: 0.22)
    
    /// 휴먼 스케일 가이드 Entity를 생성합니다
    /// - Parameter size: 스케일 가이드 크기
    /// - Returns: HumanScaleGuide 이미지를 사용한 ModelEntity
    @MainActor
    static func create(size: SIMD2<Float>? = nil) async -> ModelEntity {
        let actualSize = size ?? defaultSize

        var material = PhysicallyBasedMaterial()

        do {
            if let uiImage = UIImage(named: "img_humanScaleGuide"),
               let cgImage = uiImage.cgImage {
                let texture = try await TextureResource(image: cgImage, options: .init(semantic: .color))

                material.baseColor = .init(texture: .init(texture))
                material.emissiveColor = .init(texture: .init(texture))
                material.emissiveIntensity = 10.0
                material.metallic = .init(floatLiteral: 0.0)
                material.roughness = .init(floatLiteral: 0.8)
                material.faceCulling = .none
                material.blending = .transparent(opacity: .init(texture: .init(texture)))
                material.opacityThreshold = 0.3
            } else {
                print("⚠️ HumanScale Load 실패: Asset Catalog에서 이미지를 찾을 수 없습니다")
            }
        } catch {
            print("❌ HumanScale Load 실패: \(error)")
            print(error.localizedDescription)
        }
        
        let humanScaleEntity = ModelEntity(
            mesh: .generatePlane(width: actualSize.x, height: actualSize.y),
            materials: [material]
        )
        
        humanScaleEntity.name = "humanScaleEntity"

        return humanScaleEntity
    }
}