import SwiftUI

struct DummyView: View {
    @Environment(AppModel.self) private var appModel
    @State private var viewModel: SceneViewModel
    
    private let assets: [Asset] = Asset.assetMockData
    
    init(viewModel: SceneViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 60) {
            // MARK: - Immersive 토글 버튼 (항상 표시)
            VStack(spacing: 20) {
                ToggleImmersiveSpaceButton()
            }
            
            // MARK: - 컨트롤 버튼들 (항상 표시 - Volume이 있으므로)
            VStack(spacing: 20) {
                // ViewMode 토글
                Toggle(isOn: Binding(
                    get: { viewModel.userSpatialState.viewMode },
                    set: { _ in viewModel.toggleViewMode() }
                )) {
                    Text("뷰 모드")
                        .font(.headline)
                }
                .toggleStyle(.switch)
                .tint(viewModel.userSpatialState.viewMode ? .green : .gray)
                .fixedSize()
                
                // 이미지 생성 버튼
                HStack(spacing: 15) {
                    Text("이미지 생성")
                        .font(.headline)
                    
                    ImgCreateButton(asset: assets[0]) {
                        viewModel.addImageObject(from: assets[0])
                    }
                    ImgCreateButton(asset: assets[1]) {
                        viewModel.addImageObject(from: assets[1])
                    }
                }
            }
        }
    }
}