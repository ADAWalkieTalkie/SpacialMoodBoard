import Foundation

// MARK: - ImageAttributes(이미지 객체의 속성)
struct ImageAttributes: Codable, Hashable {
    var scale: Float
    var rotation: SIMD3<Float>
    var crop: SIMD4<Float>
    var billboardable: Bool
    
    init(
        scale: Float = 1.0,
        rotation: SIMD3<Float> = [0, 0, 0],
        crop: SIMD4<Float> = [0, 0, 1, 1],
        billboardable: Bool = true
    ) {
        self.scale = scale
        self.rotation = rotation
        self.crop = crop
        self.billboardable = billboardable
    }
}