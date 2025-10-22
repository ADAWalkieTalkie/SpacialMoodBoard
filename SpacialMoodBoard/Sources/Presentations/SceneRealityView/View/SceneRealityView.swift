// SceneRealityView.swift

import SwiftUI
import RealityKit
import RealityKitContent

/// 재사용 가능한 핵심 Scene RealityView
struct SceneRealityView: View {
    @Environment(AppModel.self) private var appModel
    @Binding var viewModel: SceneViewModel
    
    let config: SceneConfig
    
    private let assets: [Asset] = Asset.assetMockData
    
    var body: some View {
        ZStack(alignment: .bottom) {
            RealityView { content in
                await setupScene(content: content)
            
                let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, 0))
                anchor.name = "RootSceneAnchor"
                content.add(anchor)

                // Add the initial RealityKit content
                if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    anchor.addChild(immersiveContentEntity)
                }
                
            } update: { content in
                updateScene(content: content)
            }
            .id(appModel.selectedProject?.id)
            .if(config.enableGestures) { view in
                view.immersiveEntityGestures(
                    selectedEntity: $viewModel.selectedEntity,
                    onPositionUpdate: { uuid, position in
                        viewModel.updateObjectPosition(id: uuid, position: position)
                    }
                )
            }
            
            // 회전 버튼 (옵션)
            if config.showRotationButton {
                rotationButton
            }
        }
    }
    
    // MARK: - Setup Scene
    
    private func setupScene(content: RealityViewContent) async {
        guard let room = viewModel.getRoomEntity(
            for: appModel.selectedProject,
            rotationAngle: viewModel.rotationAngle
        ) else {
            return
        }
        
        // 스케일 적용 (미니맵용)
        room.scale = [config.scale, config.scale, config.scale]
        
        content.add(room)
        
        // Volume 전용: 위치 조정
        if config.alignToWindowBottom {
            viewModel.alignRoomToWindowBottom(room: room)
        }
        
        // Volume 전용: 벽면 투명도
        if config.applyWallOpacity {
            viewModel.applyOpacity(to: room)
        }
        
        // Immersive 전용: RealityKit Content
        if !config.applyWallOpacity {  // immersive 또는 minimap
            if let immersiveContent = try? await Entity(named: "ImmersiveScene", in: RealityKitContent.realityKitContentBundle) {
                room.addChild(immersiveContent)
            }
        }
    }
    
    // MARK: - Update Scene
    
    private func updateScene(content: RealityViewContent) {
        guard let room = content.entities.first else { return }
        
        let sceneObjects = viewModel.sceneObjects
        
        viewModel.updateEntities(
            sceneObjects: sceneObjects,
            anchor: room,
            assets: assets
        )
        
        // Attachment (옵션)
        if config.enableAttachments {
            viewModel.updateAttachment(
                onDuplicate: { /* handle */ },
                onCrop: { /* handle */ },
                onDelete: { /* handle */ }
            )
        }
    }
    
    // MARK: - 회전 버튼
    
    @State private var isAnimating = false
    
    private var rotationButton: some View {
        VStack {
            Button {
                guard !isAnimating else { return }
                isAnimating = true
                viewModel.rotateBy90Degrees()
                
                Task {
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    isAnimating = false
                }
            } label: {
                Image(systemName: "rotate.right")
                    .font(.title2)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .opacity(isAnimating ? 0.5 : 1.0)
            .padding()
        }
    }
}

// MARK: - View Extension

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
