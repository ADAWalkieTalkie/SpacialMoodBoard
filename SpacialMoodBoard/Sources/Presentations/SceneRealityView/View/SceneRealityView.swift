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

    let toolbarPosition: SIMD3<Float> = SIMD3<Float>(0, -0.3, -0.8)
    
    @State private var isSoundEnabled = false
    var body: some View {
        ZStack(alignment: .bottom) {
            RealityView { content, attachments in
                await setupScene(content: content)
            
                let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, 0))
                anchor.name = "RootSceneAnchor"
                content.add(anchor)

                if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    anchor.addChild(immersiveContentEntity)
                }

                let headAnchor = AnchorEntity(.head)

                if config.useHeadAnchoredToolbar {
                    if let toolbar = attachments.entity(for: "headToolbar") {
                        // y: -0.3 = 시선보다 약간 아래
                        // z: -0.8 = 앞쪽으로 80cm
                        toolbar.position = toolbarPosition
                        headAnchor.addChild(toolbar)
                    }
                    
                    content.add(headAnchor)
                }
                
            } update: { content, attachments in
                updateScene(content: content)
            } attachments: {
                Attachment(id: "headToolbar"){
                    ToolBarAttachment(
                        isSoundEnabled: $isSoundEnabled,
                        onToggleImmersive: handleToggleImmersive
                    )
                }
            }
            .id(appModel.selectedProject?.id)
            .if(config.enableGestures) { view in
                view.immersiveEntityGestures(
                    selectedEntity: $viewModel.selectedEntity,
                    onPositionUpdate: { uuid, position in
                        viewModel.updateObjectPosition(id: uuid, position: position)
                    },
                    onRotationUpdate: { uuid, rotation in
                        viewModel.updateObjectRotation(id: uuid, rotation: rotation)
                    },
                    onScaleUpdate: { uuid, scale in
                        viewModel.updateObjectScale(id: uuid, scale: scale)
                    },
                    onBillboardableChange: { uuid, billboardable in
                        viewModel.updateBillboardable(id: uuid, billboardable: billboardable)
                    },
                    getBillboardableState: { uuid in
                        viewModel.getBillboardableState(id: uuid)
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

        if let volumeSize = config.volumeSize {
            // Volume 모드: 자동 scale 계산 및 content 직접 추가
            // 최종 크기를 0.6m로 고정 (RealityKit volumetric window 렌더링 보장)
            let roomDimensions = viewModel.spacialEnvironment.groundSize.dimensions
            let roomWidth = Float(roomDimensions.x)
            let roomDepth = Float(roomDimensions.z)
            let roomHeight = Float(roomDimensions.y)

            let maxDimension = max(roomWidth, roomDepth, roomHeight)
            let autoScale = 0.6 / maxDimension

            room.scale = [autoScale, autoScale, autoScale]
            content.add(room)

            // Floor 하단 정렬
            viewModel.alignRoomToWindowBottom(room: room, windowHeight: volumeSize)
        } else {
            // Immersive/Minimap 모드: 기존 방식
            room.scale = [config.scale, config.scale, config.scale]
            content.add(room)

            if config.alignToWindowBottom {
                viewModel.alignRoomToWindowBottom(room: room)
            }

            // Immersive 전용: RealityKit Content
            if config.alignToWindowBottom == false {  // immersive 또는 minimap
                if let immersiveContent = try? await Entity(named: "ImmersiveScene", in: RealityKitContent.realityKitContentBundle) {
                    room.addChild(immersiveContent)
                }
            }
        }
    }
    
    // MARK: - Update Scene
    
    private func updateScene(content: RealityViewContent) {
        guard let room = content.entities.first else { return }
        
        let sceneObjects = viewModel.sceneObjects
        
        viewModel.updateEntities(
            sceneObjects: sceneObjects,
            anchor: room
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
