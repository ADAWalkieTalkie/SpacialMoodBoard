import Foundation
import RealityKit

struct ImageEntity {
    
    /// SceneObject와 Asset을 기반으로 이미지 Entity 생성
    /// - Parameters:
    ///   - sceneObject: SceneObject 모델 (위치, 속성 포함)
    ///   - asset: Asset 모델 (이미지 파일명, URL 등)
    /// - Returns: 설정된 ModelEntity
    static func create(
        from sceneObject: SceneObject,
        with asset: Asset
    ) -> ModelEntity? {
        guard case .image(let imageAttrs) = sceneObject.attributes else {
            print("❌ 이미지 타입이 아닙니다")
            return nil
        }
        
        // 1. 이미지를 로드하여 TextureResource로 변환
        guard let texture = try? TextureResource.load(named: asset.filename) else {
            print("❌ 이미지 로드 실패: \(asset.filename)")
            return nil
        }
        
        // 2. PhysicallyBasedMaterial 생성 및 텍스처 적용
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(texture: .init(texture))
        material.opacityThreshold = 0.0
        material.blending = .transparent(opacity: 1.0)
        
        // 3. 크기 계산 (scale 적용)
        let baseSize: Float = 0.5
        let width = baseSize * imageAttrs.scale
        let height = baseSize * imageAttrs.scale
        
        // 4. 평면 메시 생성
        let mesh = MeshResource.generatePlane(
            width: width,
            height: height,
            cornerRadius: 0.02
        )
        
        // 5. ModelEntity 생성 및 설정
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        modelEntity.position = sceneObject.position
        modelEntity.name = sceneObject.id.uuidString
        
        // 6. 회전 적용
        let rotation = imageAttrs.rotation
        modelEntity.orientation = simd_quatf(
            angle: rotation.x, axis: [1, 0, 0]
        ) * simd_quatf(
            angle: rotation.y, axis: [0, 1, 0]
        ) * simd_quatf(
            angle: rotation.z, axis: [0, 0, 1]
        )
        
        // 7. 충돌 및 입력 처리를 위한 설정
        // modelEntity.collision = CollisionComponent(
        //     shapes: [.generateBox(width: width, height: height, depth: 0.01)]
        // )
        // modelEntity.components.set(InputTargetComponent())
        
        // 8. Billboard 설정
        if imageAttrs.billboardable {
            modelEntity.components.set(BillboardComponent())
        }
        return modelEntity
    }
}