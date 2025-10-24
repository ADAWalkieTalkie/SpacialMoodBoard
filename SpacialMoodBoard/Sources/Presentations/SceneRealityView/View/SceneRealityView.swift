import SwiftUI
import RealityKit
import RealityKitContent

/// 재사용 가능한 핵심 Scene RealityView
struct SceneRealityView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    @Binding var viewModel: SceneViewModel
    let config: SceneConfig
    
    @State private var isSoundEnabled = false
    
    private let assets: [Asset] = Asset.assetMockData
    
    var body: some View {
        ZStack(alignment: .bottom) {
            RealityView { content in
                await setupScene(content: content)
            
                let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, 0))
                anchor.name = "RootSceneAnchor"
                content.add(anchor)

                if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    anchor.addChild(immersiveContentEntity)
                }
                
                // Head-anchored Toolbar (Immersive 전용)
                if config.useHeadAnchoredToolbar,
                   #available(visionOS 2.6, *) {
                    setupHeadAnchoredToolbar(content: content)
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
            
            // 회전 버튼과 Toolbar (Volume용)
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
        
        room.scale = [config.scale, config.scale, config.scale]
        content.add(room)
        
        if config.alignToWindowBottom {
            viewModel.alignRoomToWindowBottom(room: room)
        }
        
        if config.applyWallOpacity {
            viewModel.applyOpacity(to: room)
        }
        
        if !config.applyWallOpacity {
            if let immersiveContent = try? await Entity(named: "ImmersiveScene", in: RealityKitContent.realityKitContentBundle) {
                room.addChild(immersiveContent)
            }
        }
    }
    
    // MARK: - Head-anchored Toolbar Setup
    
    @available(visionOS 2.6, *)
    private func setupHeadAnchoredToolbar(content: RealityViewContent) {
        let headAnchor = AnchorEntity(.head)
        content.add(headAnchor)
        
        let toolbarEntity = Entity()
        toolbarEntity.name = "headToolbar"
        
        let attachment = ViewAttachmentComponent(
            rootView: ToolBarAttachment(
                isSoundEnabled: $isSoundEnabled,
                onToggleImmersive: handleToggleImmersive
            )
            .environment(appModel)
        )
        toolbarEntity.components.set(attachment)
        toolbarEntity.position = SIMD3<Float>(0, -0.3, -0.8)
        
        headAnchor.addChild(toolbarEntity)
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
        
        if config.enableAttachments {
            viewModel.updateAttachment(
                onDuplicate: { _ = viewModel.duplicateObject() },
                onCrop: { /* handle */ },
                onDelete: {
                    guard let entity = viewModel.selectedEntity,
                          let objectId = UUID(uuidString: entity.name) else { return }
                    viewModel.removeSceneObject(id: objectId)
                }
            )
        }
    }
    
    // MARK: - 회전 버튼과 Toolbar (Volume용)
    
    @State private var isAnimating = false
    
    private var rotationButton: some View {
        VStack(spacing: 12) {
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
            .padding(.horizontal)

            ToolBarAttachment(
                isSoundEnabled: $isSoundEnabled,
                onToggleImmersive: handleToggleImmersive
            )
            .environment(appModel)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Actions
    
    private func handleToggleImmersive() {
        Task { @MainActor in
            await viewModel.toggleImmersiveSpace(
                appModel: appModel,
                dismissImmersiveSpace: dismissImmersiveSpace,
                openImmersiveSpace: openImmersiveSpace
            )
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