import Foundation
import RealityKit
import UIKit

struct ImageEntity {
    
    /// SceneObject와 Asset을 기반으로 이미지 Entity 생성
    /// - Parameters:
    ///   - sceneObject: SceneObject 모델 (위치, 속성 포함)
    ///   - asset: Asset 모델 (이미지 파일명, URL 등)
    ///   - Returns: 설정된 ModelEntity
    static func create(
        from sceneObject: SceneObject,
        with asset: Asset
    ) -> ModelEntity? {

        guard case .image(let imageAttrs) = sceneObject.attributes else {
            print("❌ 이미지 타입이 아닙니다")
            return nil
        }

        let imageEntity = ModelEntity()
        imageEntity.name = sceneObject.id.uuidString
        imageEntity.position = sceneObject.position
        
        let size = calculateSize(from: asset, imageAttrs: imageAttrs)

        Task { @MainActor in
            await Self.createPlane(
                to: imageEntity,
                from: sceneObject,
                with: asset,
                imageAttrs: imageAttrs,
                size: size
            )
        }

        // 충돌 및 입력 처리를 위한 설정
        imageEntity.collision = CollisionComponent(
            shapes: [.generateBox(width: size.width, height: size.height, depth: 0.001)]
        )
        imageEntity.components.set(InputTargetComponent())
        imageEntity.components.set(HoverEffectComponent())
        
        return imageEntity
    }
    
    // MARK: - Helper Methods
    
    /// 크기 계산
    private static func calculateSize(from asset: Asset, imageAttrs: ImageAttributes) -> (width: Float, height: Float) {
        let baseSize: Float = 0.5
        let baseWidth = baseSize * imageAttrs.scale
        
        let imageWidth = Float(asset.image?.width ?? 1)
        let imageHeight = Float(asset.image?.height ?? 1)
        let aspectRatio = imageWidth > 0 ? (imageHeight / imageWidth) : 1.0
        
        let width = baseWidth
        let height = baseWidth * aspectRatio
        
        return (width, height)
    }
    
    /// Position 계산 (y축 0 이상으로 제한)
//    private static func calculateClampedPosition(from position: SIMD3<Float>) -> SIMD3<Float> {
//        return SIMD3<Float>(
//            position.x,
//            max(0, position.y),
//            position.z
//        )
//    }
    
    /// Material 생성 (텍스처 로딩 및 양면 렌더링 지원)
    private static func createMaterial(from url: URL) async -> UnlitMaterial? {
        guard let texture = await loadTexture(from: url) else { return nil }

        var material = UnlitMaterial(color: .white)
        material.color = .init(texture: .init(texture))
        material.blending = .transparent(opacity: 1.0)
        material.opacityThreshold = 0.01
        material.faceCulling = .none
        return material
    }
    
    /// 회전 적용
    private static func applyRotation(
        to entity: ModelEntity,
        rotation: SIMD3<Float>,
        yAxisOffset: Float = 0
    ) {
        entity.orientation = simd_quatf(
            angle: rotation.x, axis: [1, 0, 0]
        ) * simd_quatf(
            angle: rotation.y + yAxisOffset, axis: [0, 1, 0]
        ) * simd_quatf(
            angle: rotation.z, axis: [0, 0, 1]
        )
    }
    
    /// 텍스처 로드
    private static func loadTexture(from url: URL) async -> TextureResource? {
        do {
            return try await TextureResource(contentsOf: url)
        } catch {
            print("⚠️ 이미지 텍스처 로드 실패: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Plane Creation Methods

    private static func createPlane(
        to imageEntity: ModelEntity,
        from sceneObject: SceneObject,
        with asset: Asset,
        imageAttrs: ImageAttributes,
        size: (width: Float, height: Float)
    ) async {
        guard let material = await createMaterial(from: asset.url) else { return }

        let mesh = MeshResource.generatePlane(
            width: size.width,
            height: size.height
        )

        let plane = ModelEntity(mesh: mesh, materials: [material])
        plane.position = SIMD3<Float>(0, 0, 0)

        applyRotation(to: plane, rotation: imageAttrs.rotation)

        imageEntity.addChild(plane)
    }
}
