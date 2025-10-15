import SwiftUI

struct DummyView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(SceneModel.self) private var sceneModel

    private let assets: [Asset] = Asset.assetMockData

    var body: some View {
        VStack(spacing: 60) {
            ToggleImmersiveSpaceButton()
            
            if appModel.immersiveSpaceState == .open {
                HStack(spacing: 15) {
                    Text("이미지 생성")
                        .font(.headline)
                    
                    ImgCreateButton(asset: assets[0]){
                        sceneModel.addImageObject(from: assets[0])
                    }
                    ImgCreateButton(asset: assets[1]){
                        sceneModel.addImageObject(from: assets[1])
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview(windowStyle: .plain) {
    let previewModel = AppModel()
    let sceneModel = SceneModel()
    previewModel.immersiveSpaceState = .open
    
    return DummyView()
        .environment(sceneModel)
        .environment(previewModel)
}
