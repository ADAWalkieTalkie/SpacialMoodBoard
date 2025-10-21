//import SwiftUI
//
//struct DummyView: View {
//    @Environment(AppModel.self) private var appModel
//    @Environment(SceneModel.self) private var sceneModel
//
//    private let projects: [Project] = Project.mockData
//    private let assets: [Asset] = Asset.assetMockData
//
//    // 3열 그리드 설정
//    private let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 3)
//
//
//    var body: some View {
//        VStack(spacing: 60) {
//                            
//            // MARK: - Immersive 공간이 닫혀있을 때: 프로젝트 선택
//            if appModel.immersiveSpaceState == .closed {
//                VStack(spacing: 20) {
//                    Text("프로젝트 선택")
//                        .font(.title)
//                        .fontWeight(.bold)
//                    
//                    Text("작업할 프로젝트를 선택하세요")
//                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//                    
//                    // 프로젝트 그리드
//                    LazyVGrid(columns: columns, spacing: 20) {
//                        ForEach(projects) { project in
//                            ProjectSelectionButton(project: project)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//                .padding(.top, 40)
//            }
//            
//            // MARK: - Immersive 공간이 열려있을 때: 기존 컨트롤들
//            
//            if appModel.immersiveSpaceState == .open {
//                // ViewMode 토글
//                VStack(spacing: 20) {
//                    Toggle(isOn: Binding(
//                        get: { sceneModel.userSpatialState.viewMode },
//                        set: { _ in sceneModel.toggleViewMode() }
//                    )) {
//                        Text("뷰 모드")
//                            .font(.headline)
//                    }
//                    .toggleStyle(.switch)
//                    .tint(sceneModel.userSpatialState.viewMode ? .green : .gray)
//                    .fixedSize()
//                    
//                    // 이미지 생성 버튼
//                    HStack(spacing: 15) {
//                        Text("이미지 생성")
//                            .font(.headline)
//                        
//                        ImgCreateButton(asset: assets[0]){
//                            sceneModel.addImageObject(from: assets[0])
//                        }
//                        ImgCreateButton(asset: assets[1]){
//                            sceneModel.addImageObject(from: assets[1])
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//
////// MARK: - Preview
////#Preview(windowStyle: .plain) {
////    let previewModel = AppModel()
////    previewModel.immersiveSpaceState = .closed
////    
////    return DummyView()
////        .environment(previewModel)
////}
