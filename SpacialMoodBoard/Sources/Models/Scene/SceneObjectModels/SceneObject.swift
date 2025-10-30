import Foundation

// MARK: - SceneObject(3D 공간에 배치되는 모든 객체)
struct SceneObject: Identifiable, Codable, Hashable {
    let id: UUID                // object_id (PK)
    var assetId: String           // asset_id (FK) - 단일 Asset 참조
    
    var position: SIMD3<Float>  // x, y, z 통합
    var isEditable: Bool        // 편집 가능 여부
    
    var type: AssetType {
        switch attributes {
        case .image: return .image
        case .audio: return .sound
        }
    }
    
    private(set) var attributes: ObjectAttributes
    
    init(
        id: UUID = UUID(),
        assetId: String,
        position: SIMD3<Float> = [0, 0, 0],
        isEditable: Bool = true,
        attributes: ObjectAttributes
    ) {
        self.id = id
        self.assetId = assetId
        self.position = position
        self.isEditable = isEditable
        self.attributes = attributes
    }
}

// MARK: - SceneObject Mutating Methods (속성 업데이트)

extension SceneObject {

    /// 이미지 position 이동
    mutating func move(to position: SIMD3<Float>) {
        self.position = position
    }
    /// 이미지 scale 변경
    mutating func setScale(_ scale: Float) {
        guard case .image(var attrs) = attributes else { return }
        attrs.scale = scale
        self.attributes = .image(attrs)
    }
    
    /// 이미지 rotation 변경
    mutating func setRotation(_ rotation: SIMD3<Float>) {
        guard case .image(var attrs) = attributes else { return }
        attrs.rotation = rotation
        self.attributes = .image(attrs)
    }
    
    /// 이미지 crop 변경
    mutating func setCrop(_ crop: SIMD4<Float>) {
        guard case .image(var attrs) = attributes else { return }
        attrs.crop = crop
        self.attributes = .image(attrs)
    }
    
    /// 이미지 billboardable 변경
    mutating func setBillboardable(_ billboardable: Bool) {
        guard case .image(var attrs) = attributes else { return }
        attrs.billboardable = billboardable
        self.attributes = .image(attrs)
    }
    
    /// 오디오 volume 변경
    mutating func setVolume(_ volume: Float) {
        guard case .audio(var attrs) = attributes else { return }
        attrs.volume = volume
        self.attributes = .audio(attrs)
    }
}
