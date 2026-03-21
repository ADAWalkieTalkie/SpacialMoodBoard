import RealityKit
import SwiftUI

struct SoundNameAttachment: View {
    let filename: String
    @State private var isVisible: Bool = false
    
    var body: some View {
        Text(filename.deletingPathExtension)
            .font(.system(size: 15, weight: .medium))
            .lineLimit(1)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: 128)
            .glassBackgroundEffect(in: Capsule())
            .opacity(isVisible ? 1.0 : 0.0)
            .onAppear {
                isVisible = false
                withAnimation(.easeOut(duration: 0.2)) {
                    isVisible = true
                }
            }
    }
}

#Preview {
    SoundNameAttachment(filename: "example.mp3")
}
