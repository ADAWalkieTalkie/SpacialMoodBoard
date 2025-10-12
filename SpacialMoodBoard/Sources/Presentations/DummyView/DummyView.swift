import SwiftUI

struct DummyView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 60) {
            ToggleImmersiveSpaceButton()
            
            if appModel.immersiveSpaceState == .open {
                HStack(spacing: 15) {
                    Text("이미지 생성")
                        .font(.headline)
                    
                    ImgCreateButton(title: "금붕어 🐟", imageName: "Goldfish")
                    ImgCreateButton(title: "잭 점프 🏃", imageName: "JackJump")
                }
            }
        }
    }
}

// MARK: - Preview
#Preview(windowStyle: .plain) {
    let previewModel = AppModel()
    previewModel.immersiveSpaceState = .open
    
    return DummyView()
        .environment(previewModel)
}
