import Foundation

// MARK: - AudioAttributes(오디오 객체의 속성)
struct AudioAttributes: Codable, Hashable {
    var volume: Float 
    
    init(volume: Float = 1.0) {
        self.volume = volume
    }
}

extension SceneObject {
    var audioVolumeOrNil: Double? {
        if case .audio(let attrs) = attributes { return Double(attrs.volume) }
        return nil
    }
    var audioVolumeOrDefault: Double { audioVolumeOrNil ?? 1.0 }
}
