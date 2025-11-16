import SwiftUI

struct LockIconAttachment: View {
    let onUnlock: () -> Void

    var body: some View {
        Image(systemName: "lock")
            .font(.system(size: 20, weight: .medium))
            .frame(width: 36, height: 36)
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