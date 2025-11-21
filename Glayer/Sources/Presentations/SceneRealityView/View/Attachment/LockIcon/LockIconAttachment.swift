import SwiftUI

struct LockIconAttachment: View {
    let onUnlock: () -> Void
    let fontSize = 32.0
    let frameSize = 64.0

    @State private var isPressing = false
    @State private var startDate: Date?
    @State private var progress: CGFloat = 0 // 마지막 고정된 값(표시 제어용)

    private let holdDuration: Double = 1

    var body: some View {
        Image(systemName: "lock")
            .font(.system(size: fontSize, weight: .medium))
            .frame(width: frameSize, height: frameSize)
            .background(.blue.opacity(0.5), in: Circle())
            .contentShape(Circle())
            .hoverEffect()
            .overlay(
                TimelineView(.animation) { _ in
                    let currentProgress: CGFloat = {
                        if let s = startDate, isPressing {
                            return min(CGFloat(Date().timeIntervalSince(s) / holdDuration), 1)
                        } else {
                            return progress
                        }
                    }()

                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.25), lineWidth: 4)

                        Circle()
                            .trim(from: 0, to: currentProgress)
                            .stroke(
                                .white,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                    }
                    .padding(6)
                    .opacity((isPressing || currentProgress > 0) ? 1 : 0)
                }
            )
            .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 20,
                                pressing: { pressing in
                if pressing {
                    isPressing = true
                    startDate = Date()
                } else {
                    // 롱프레스 실패(시간 미만) 시 즉시 리셋
                    if let s = startDate, Date().timeIntervalSince(s) < holdDuration {
                        progress = 0
                    } else {
                        progress = 1
                    }
                    isPressing = false
                    startDate = nil
                }
            }, perform: {
                onUnlock()
                // 성공 후 다음 사용을 위해 리셋
                progress = 0
                isPressing = false
                startDate = nil
            })
    }
}

#Preview {
    LockIconAttachment(onUnlock: { print("Unlock") })
}
