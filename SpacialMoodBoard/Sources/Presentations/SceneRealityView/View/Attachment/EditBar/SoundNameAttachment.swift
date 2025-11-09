import RealityKit
import SwiftUI

struct SoundNameAttachment: View {
    let filename: String
    
    var body: some View {
        Text(filename)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(.ultraThinMaterial)
            )
    }
}

#Preview {
    SoundNameAttachment(filename: "example.mp3")
}