import SwiftUI

struct LockIconAttachment: View {
    let onUnlock: () -> Void
    let fontSize = 32.0
    let frameSize = 64.0

    var body: some View {
        Image(systemName: "lock")
            .font(.system(size: fontSize, weight: .medium))
            .frame(width: frameSize, height: frameSize)
            .background(.ultraThinMaterial, in: Circle())
            .contentShape(Circle())
            .hoverEffect()
            .gesture(
                LongPressGesture(minimumDuration: 2)
                    .onEnded { _ in
                        onUnlock()
                    }
            )
    }
}

#Preview {
    LockIconAttachment(onUnlock: { print("Unlock") })
}
