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
        imageEntity.position = calculateClampedPosition(from: sceneObject.position)
        
        let size = calculateSize(from: asset, imageAttrs: imageAttrs)
        
        Self.createFrontPlane(
            to: imageEntity,
            from: sceneObject,
            with: asset,
            imageAttrs: imageAttrs,
            size: size
        )
        Self.createBackPlane(
            to: imageEntity,
            from: sceneObject,
            with: asset,
            imageAttrs: imageAttrs,
            size: size
        )
        
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
    private static func calculateClampedPosition(from position: SIMD3<Float>) -> SIMD3<Float> {
        return SIMD3<Float>(
            position.x,
            max(0, position.y),
            position.z
        )
    }
    
    /// Material 생성
    private static func createMaterial(from texture: TextureResource) -> UnlitMaterial {
        var material = UnlitMaterial(color: .white)
        material.color = .init(texture: .init(texture))
        material.blending = .transparent(opacity: 1.0)
        material.opacityThreshold = 0.01
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
    
    /// 텍스처 로드 (일반)
    private static func loadTexture(from url: URL) -> TextureResource? {
        return try? TextureResource.load(contentsOf: url)
    }
    
    /// 텍스처 로드 (좌우 반전)
    private static func loadFlippedTexture(from url: URL) -> TextureResource? {
        guard let imageData = try? Data(contentsOf: url),
              let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else { return nil }
        
        let cgwidth = cgImage.width
        let cgheight = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: nil,
            width: cgwidth,
            height: cgheight,
            bitsPerComponent: 8,
            bytesPerRow: cgwidth * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        // 좌우 반전을 위한 변환 적용
        context.translateBy(x: CGFloat(cgwidth), y: 0)
        context.scaleBy(x: -1.0, y: 1.0)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgwidth, height: cgheight))
        
        guard let flippedCGImage = context.makeImage() else { return nil }
        
        return try? TextureResource(
            image: flippedCGImage,
            options: .init(semantic: .color)
        )
    }

    // MARK: - Plane Creation Methods
    
    private static func createFrontPlane(
        to imageEntity: ModelEntity,
        from sceneObject: SceneObject,
        with asset: Asset,
        imageAttrs: ImageAttributes,
        size: (width: Float, height: Float)
    ) {
        guard let texture = loadTexture(from: asset.url) else { return }
        
        let material = createMaterial(from: texture)
        let mesh = MeshResource.generatePlane(
            width: size.width,
            height: size.height
        )
        
        let frontPlane = ModelEntity(mesh: mesh, materials: [material])
        frontPlane.position = SIMD3<Float>(0, 0, 0.0005)
        
        applyRotation(to: frontPlane, rotation: imageAttrs.rotation)
        
        imageEntity.addChild(frontPlane)
    }

    private static func createBackPlane(
        to imageEntity: ModelEntity,
        from sceneObject: SceneObject,
        with asset: Asset,
        imageAttrs: ImageAttributes,
        size: (width: Float, height: Float)
    ) {
        guard let texture = loadFlippedTexture(from: asset.url) else { return }
        
        let material = createMaterial(from: texture)
        let mesh = MeshResource.generatePlane(
            width: size.width,
            height: size.height
        )
        
        let backPlane = ModelEntity(mesh: mesh, materials: [material])
        backPlane.position = SIMD3<Float>(0, 0, -0.0005)
        
        applyRotation(to: backPlane, rotation: imageAttrs.rotation, yAxisOffset: .pi)
        
        imageEntity.addChild(backPlane)
    }
}
