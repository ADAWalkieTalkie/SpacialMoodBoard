import Foundation

// MARK: - SceneObject Factory Methods

extension SceneObject {
    /// 이미지 객체 생성
    static func createImage(
        id: UUID = UUID(),
        assetId: UUID,
        position: SIMD3<Float> = [0, 1.5, -2],
        isEditable: Bool = true,
        scale: Float = 1.0,
        rotation: SIMD3<Float> = [0, 0, 0],
        crop: SIMD4<Float> = [0, 0, 1, 1],
        billboardable: Bool = true
    ) -> SceneObject {
        let imageAttrs = ImageAttributes(
            scale: scale,
            rotation: rotation,
            crop: crop,
            billboardable: billboardable
        )
        
        return SceneObject(
            id: id,
            assetId: assetId,
            position: position,
            isEditable: isEditable,
            attributes: .image(imageAttrs)
        )
    }
    
    /// 오디오 객체 생성
    static func createAudio(
        id: UUID = UUID(),
        sceneId: UUID,
        assetId: UUID,
        position: SIMD3<Float> = [0, 1.5, -2],
        isEditable: Bool = true,
        volume: Float = 1.0
    ) -> SceneObject {
        let audioAttrs = AudioAttributes(volume: volume)
        
        return SceneObject(
            id: id,
            assetId: assetId,
            position: position,
            isEditable: isEditable,
            attributes: .audio(audioAttrs)
        )
    }
}
