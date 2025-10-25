import SwiftUI

struct DummyAttachment: View {
    @State private var isToggled = false
    @State private var tapCount = 0
    
    var body: some View {
        VStack {
            Text("Taps: \(tapCount)")
                .foregroundStyle(.white)
                .padding(4)
            
            Button(action: {
                isToggled.toggle()
                tapCount += 1
                print("🔥 Button tapped! isToggled: \(isToggled), count: \(tapCount)")
            }) {
                Image(systemName: "star.fill")
                    .font(.system(size: 19))
                    .foregroundStyle(isToggled ? .black : .white)
                    .frame(width: 44, height: 44)
                    .background(isToggled ? Color.white : Color.clear)
                    .clipShape(Circle())
            }
            .buttonStyle(.borderless)  // .plain 대신 .borderless 시도
        }
        .padding(12)
        .glassBackgroundEffect()
    }
}