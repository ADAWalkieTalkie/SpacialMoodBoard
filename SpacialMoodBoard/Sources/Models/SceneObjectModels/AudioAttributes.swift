import Foundation

// MARK: - AudioAttributes(오디오 객체의 속성)
struct AudioAttributes: Codable, Hashable {
    var volume: Float 
    
    init(volume: Float = 1.0) {
        self.volume = volume
    }
}