import RealityKit
import SwiftUI

struct SoundNameAttachment: View {
    let filename: String
    
    var body: some View {
        Text(filename.deletingPathExtension)
            .font(.system(size: 15, weight: .medium))
            .lineLimit(1)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: 128)
            .glassBackgroundEffect(in: Capsule())
    }
}

#Preview {
    SoundNameAttachment(filename: "example.mp3")
}
