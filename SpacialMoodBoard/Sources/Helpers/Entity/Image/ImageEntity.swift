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
        
        // 크기 계산 (scale 적용)
        let baseSize: Float = 0.5
        let baseWidth = baseSize * imageAttrs.scale

        // 실제 이미지 비율 가져오기
        let imageWidth = Float(asset.image?.width ?? 1)
        let imageHeight = Float(asset.image?.height ?? 1)
        let aspectRatio = imageWidth > 0 ? (imageHeight / imageWidth) : 1.0

        // 가로는 baseWidth로 고정, 세로는 비율에 맞춰 계산
        let width = baseWidth
        let height = baseWidth * aspectRatio

        imageEntity.name = sceneObject.id.uuidString
        let clampedPosition = SIMD3<Float>(
            sceneObject.position.x,
            max(0, sceneObject.position.y),
            sceneObject.position.z
        )
        imageEntity.position = clampedPosition


        Self.createFrontPlane(to: imageEntity, from: sceneObject, with: asset, imageAttrs: imageAttrs)
        Self.createBackPlane(to: imageEntity, from: sceneObject, with: asset, imageAttrs: imageAttrs)
        
        
        // 충돌 및 입력 처리를 위한 설정
        imageEntity.collision = CollisionComponent(
             shapes: [.generateBox(width: width, height: height, depth: 0.001)]
         )
        imageEntity.components.set(InputTargetComponent())

        imageEntity.components.set(HoverEffectComponent())
        
        return imageEntity
    }


    private static func createFrontPlane(
        to imageEntity: ModelEntity, 
        from sceneObject: SceneObject,
        with asset: Asset,
        imageAttrs: ImageAttributes
        ) {

        guard let texture = try? TextureResource.load(contentsOf: asset.url) else { return }
        
        // 2. UnlitMaterial 생성 및 텍스처 적용
        var material = UnlitMaterial(color: .white)
        material.color = .init(texture: .init(texture))
        material.blending = .transparent(opacity: 1.0)
        material.opacityThreshold = 0.01
        
        // 3. 크기 계산 (scale 적용)
        let baseSize: Float = 0.5
        let baseWidth = baseSize * imageAttrs.scale

        // 실제 이미지 비율 가져오기
        let imageWidth = Float(asset.image?.width ?? 1)
        let imageHeight = Float(asset.image?.height ?? 1)
        let aspectRatio = imageWidth > 0 ? (imageHeight / imageWidth) : 1.0

        // 가로는 baseWidth로 고정, 세로는 비율에 맞춰 계산
        let width = baseWidth
        let height = baseWidth * aspectRatio
        
        // 4. 평면 메시 생성
        let mesh = MeshResource.generateBox(
            width: width,
            height: height,
            depth: 0.01
        )
        
        // 5. ModelEntity 생성 및 설정
        let frontPlane = ModelEntity(mesh: mesh, materials: [material])

        frontPlane.position = SIMD3<Float>(0, 0, 0.0005)
        
        // 6. 회전 적용
        let rotation = imageAttrs.rotation
        frontPlane.orientation = simd_quatf(
            angle: rotation.x, axis: [1, 0, 0]
        ) * simd_quatf(
            angle: rotation.y, axis: [0, 1, 0]
        ) * simd_quatf(
            angle: rotation.z, axis: [0, 0, 1]
        )

        imageEntity.addChild(frontPlane)
    }


    private static func createBackPlane(
        to imageEntity: ModelEntity, 
        from sceneObject: SceneObject,
        with asset: Asset,
        imageAttrs: ImageAttributes
        ) {

         // 1. 이미지를 로드하여 TextureResource로 변환
        guard let imageData = try? Data(contentsOf: asset.url),
            let uiImage = UIImage(data: imageData),
            let cgImage = uiImage.cgImage else { return }

        // 좌우 반전을 위한 CGContext 생성
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
        ) else { return }

        // 좌우 반전을 위한 변환 적용
        context.translateBy(x: CGFloat(cgwidth), y: 0)
        context.scaleBy(x: -1.0, y: 1.0)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgwidth, height: cgheight))

        guard let flippedCGImage = context.makeImage() else { return }

        // TextureResource 생성
        guard let texture = try? TextureResource(
            image: flippedCGImage,
            options: .init(semantic: .color)
        ) else { return }
        
        // 2. UnlitMaterial 생성 및 텍스처 적용
        var material = UnlitMaterial(color: .white)
        material.color = .init(texture: .init(texture))
        material.blending = .transparent(opacity: 1.0)
        material.opacityThreshold = 0.01
        
        // 3. 크기 계산 (scale 적용)
        let baseSize: Float = 0.5
        let baseWidth = baseSize * imageAttrs.scale

        // 실제 이미지 비율 가져오기
        let imageWidth = Float(asset.image?.width ?? 1)
        let imageHeight = Float(asset.image?.height ?? 1)
        let aspectRatio = imageWidth > 0 ? (imageHeight / imageWidth) : 1.0

        // 가로는 baseWidth로 고정, 세로는 비율에 맞춰 계산
        let width = baseWidth
        let height = baseWidth * aspectRatio
        
        // 4. 평면 메시 생성
        let mesh = MeshResource.generatePlane(
            width: width,
            height: height
        )
        
        // 5. ModelEntity(backPlane) 생성 및 설정
        let backPlane = ModelEntity(mesh: mesh, materials: [material])
        backPlane.position = SIMD3<Float>(0, 0, -0.0005)
        
        // 6. 회전 적용
        let rotation = imageAttrs.rotation
        backPlane.orientation = simd_quatf(
            angle: rotation.x, axis: [1, 0, 0]
        ) * simd_quatf(
            angle: rotation.y + .pi, axis: [0, 1, 0]
        ) * simd_quatf(
            angle: rotation.z, axis: [0, 0, 1]
        )

        imageEntity.addChild(backPlane)
    }
}
