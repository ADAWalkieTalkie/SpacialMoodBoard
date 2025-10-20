// //
// //  ProjectSelectionButton.swift
// //  SpacialMoodBoard
// //

// import SwiftUI

// struct ProjectSelectionButton: View {
//     let project: Project
    
//     @Environment(AppModel.self) private var appModel
//     @Environment(SceneModel.self) private var sceneModel
//     @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
//     var body: some View {
//         Button {
//             Task { @MainActor in
//                 // 1. 프로젝트 선택
//                 appModel.selectedProject = project
                
//                 // 2. SceneModel에 프로젝트 로드
//                 sceneModel.loadProject(project)
                
//                 // 3. Immersive 공간 열기
//                 appModel.immersiveSpaceState = .inTransition
//                 switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
//                 case .opened:
//                     print("✅ Immersive 공간 오픈: \(project.title)")
//                     break
                    
//                 case .userCancelled, .error:
//                     fallthrough
//                 @unknown default:
//                     appModel.immersiveSpaceState = .closed
//                     print("❌ Immersive 공간 오픈 실패")
//                 }
//             }
//         } label: {
//             VStack(spacing: 8) {
//                 // 썸네일 영역
//                 RoundedRectangle(cornerRadius: 16)
//                     .fill(Color.blue.opacity(0.1))
//                     .overlay {
//                         if let thumbnailImage = project.thumbnailImage {
//                             Image(thumbnailImage)
//                                 .resizable()
//                                 .scaledToFill()
//                         } else {
//                             Image(systemName: "photo")
//                                 .font(.system(size: 40))
//                                 .foregroundStyle(.secondary)
//                         }
//                     }
//                     .frame(width: 200, height: 150)
//                     .clipShape(RoundedRectangle(cornerRadius: 12))
                
//                 // 프로젝트 제목
//                 Text(project.title)
//                     .font(.headline)
//                     .foregroundStyle(.primary)
//                     .lineLimit(2)
//                     .multilineTextAlignment(.center)
//                     .frame(width: 200)
//             }
//             .padding(12)
//             .background(Color.secondary.opacity(0.1))
//             .cornerRadius(16)
//         }
//         .buttonStyle(.plain)
//         .hoverEffect()
//     }
// }