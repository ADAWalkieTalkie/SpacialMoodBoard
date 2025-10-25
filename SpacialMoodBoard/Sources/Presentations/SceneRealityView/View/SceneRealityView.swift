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
                   #available(visionOS 26, *) {
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
    
    // MARK: - Head-anchored Toolbar Setup (GestureComponent)

    @available(visionOS 26, *)
    private func setupHeadAnchoredToolbar(content: RealityViewContent) {
        let headAnchor = AnchorEntity(.head)
        content.add(headAnchor)

        let buttonSpacing: Float = 0.08
        let startX: Float = -buttonSpacing
        let baseY: Float = -0.3
        let baseZ: Float = -0.8

        // 버튼 1: View Mode 토글
        let viewModeButton = createToolbarButton(
            icon: "eye",
            position: SIMD3<Float>(startX, baseY, baseZ),
            isActive: appModel.selectedScene?.userSpatialState.viewMode ?? false
        ) { [self] in
            toggleViewMode()
        }
        headAnchor.addChild(viewModeButton)

        // 버튼 2: Immersive Space 토글
        let immersiveButton = createToolbarButton(
            icon: "person.and.background.dotted",
            position: SIMD3<Float>(startX + buttonSpacing, baseY, baseZ),
            isActive: appModel.immersiveSpaceState == .open
        ) { [self] in
            handleToggleImmersive()
        }
        headAnchor.addChild(immersiveButton)

        // 버튼 3: Sound 토글
        let soundButton = createToolbarButton(
            icon: isSoundEnabled ? "speaker.slash" : "speaker",
            position: SIMD3<Float>(startX + buttonSpacing * 2, baseY, baseZ),
            isActive: isSoundEnabled
        ) { [self] in
            isSoundEnabled.toggle()
            // TODO: Sound 버튼 재생성하여 아이콘 업데이트 필요
        }
        headAnchor.addChild(soundButton)
    }

    @available(visionOS 26, *)
    private func createToolbarButton(
        icon: String,
        position: SIMD3<Float>,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> Entity {
        let entity = Entity()
        entity.name = "toolbarButton_\(icon)"

        // 버튼 배경 (원형)
        let buttonRadius: Float = 0.035
        let buttonMesh = MeshResource.generatePlane(
            width: buttonRadius * 2,
            height: buttonRadius * 2,
            cornerRadius: buttonRadius
        )

        // 배경 색상 (활성화 상태에 따라)
        let backgroundColor = isActive ? UIColor.white : UIColor.clear
        var backgroundMaterial = UnlitMaterial()
        backgroundMaterial.color = .init(tint: backgroundColor)
        backgroundMaterial.blending = .transparent(opacity: isActive ? 1.0 : 0.3)

        let backgroundModel = ModelEntity(mesh: buttonMesh, materials: [backgroundMaterial])
        entity.addChild(backgroundModel)

        // 아이콘 (SF Symbol 텍스처)
        if let iconTexture = createSFSymbolTexture(systemName: icon, pointSize: 50, color: isActive ? .black : .white) {
            let iconMesh = MeshResource.generatePlane(
                width: buttonRadius * 1.5,
                height: buttonRadius * 1.5
            )
            var iconMaterial = UnlitMaterial()
            iconMaterial.color = .init(texture: .init(iconTexture))
            iconMaterial.blending = .transparent(opacity: 1.0)

            let iconModel = ModelEntity(mesh: iconMesh, materials: [iconMaterial])
            iconModel.position = SIMD3<Float>(0, 0, 0.001)  // 배경보다 약간 앞
            entity.addChild(iconModel)
        }

        entity.position = position

        // 상호작용 컴포넌트 추가
        entity.components.set(InputTargetComponent())
        entity.components.set(CollisionComponent(
            shapes: [.generateBox(width: buttonRadius * 2, height: buttonRadius * 2, depth: 0.01)],
            mode: .trigger
        ))

        // Hover Effect
        entity.components.set(HoverEffectComponent())

        // GestureComponent로 탭 제스처 추가
        let tapGesture = TapGesture()
            .onEnded { _ in
                action()
            }
        entity.components.set(GestureComponent(tapGesture))

        return entity
    }

    // SF Symbol 텍스처 생성 헬퍼
    private func createSFSymbolTexture(
        systemName: String,
        pointSize: CGFloat,
        color: UIColor
    ) -> TextureResource? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
        guard let image = UIImage(systemName: systemName, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal),
              let cgImage = image.cgImage else {
            return nil
        }

        do {
            let texture = try TextureResource.generate(
                from: cgImage,
                options: .init(semantic: .color, mipmapsMode: .allocateAndGenerateAll)
            )
            return texture
        } catch {
            print("Failed to create SF Symbol texture: \(error)")
            return nil
        }
    }

    // View Mode 토글 액션
    private func toggleViewMode() {
        guard var scene = appModel.selectedScene else { return }
        scene.userSpatialState.viewMode.toggle()
        appModel.selectedScene = scene
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
