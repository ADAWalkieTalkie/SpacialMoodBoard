import SwiftUI
import RealityKit
import RealityKitContent

/// 재사용 가능한 핵심 Scene RealityView
struct SceneRealityView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    @Binding var viewModel: SceneViewModel
    let config: SceneConfig

    let toolbarPosition: SIMD3<Float> = SIMD3<Float>(0, -0.3, -0.8)

    @State private var isSoundEnabled = false
    @State private var headAnchor: AnchorEntity?
    @State private var showFloorImageAlert = false

    private var sceneViewIdentifier: String {
        let projectID = appModel.selectedProject?.id.uuidString ?? ""
        let floorImageURL = viewModel.spacialEnvironment.floorMaterialImageURL?.absoluteString ?? ""
        return "\(projectID)-\(floorImageURL)"
    }

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

                let newHeadAnchor = AnchorEntity(.head) 
                headAnchor = newHeadAnchor

                if config.useHeadAnchoredToolbar {
                    if let toolbar = attachments.entity(for: "headToolbar") {
                        // y: -0.3 = 시선보다 약간 아래
                        // z: -0.8 = 앞쪽으로 80cm
                        toolbar.position = toolbarPosition
                        newHeadAnchor.addChild(toolbar)
                    }
                    content.add(newHeadAnchor)
                }

                // Floor 중앙에 FloorImageApplyButton attachment 배치 (초기 setup)
                if config.showFloorImageApplyButton,
                   let floorAttachment = attachments.entity(for: "floorImageApplyButton"),
                   let room = content.entities.first,
                   let floor = room.findEntity(named: "floor") {
                    positionFloorAttachment(floorAttachment, on: floor, room: room)
                }

            } update: { content, attachments in
                updateScene(content: content)

                // Floor attachment 재배치 (room 변경 시에도 attachment 유지)
                if config.showFloorImageApplyButton,
                   let floorAttachment = attachments.entity(for: "floorImageApplyButton"),
                   let room = content.entities.first,
                   let floor = room.findEntity(named: "floor") {
                    positionFloorAttachment(floorAttachment, on: floor, room: room)
                }
            } attachments: {
                Attachment(id: "headToolbar"){
                    ToolBarAttachment(
                        isSoundEnabled: $isSoundEnabled,
                        onToggleImmersive: handleToggleImmersive
                    )
                }

                if config.showFloorImageApplyButton {
                    Attachment(id: "floorImageApplyButton") {
                        FloorImageApplyButton {
                            showFloorImageAlert = true
                            viewModel.isSelectingFloorImage = true
                        }
                        .frame(width: 1300, height: 1300)
                    }
                }
            }
            .id(sceneViewIdentifier)
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
                    },
                    getHeadPosition: {
                        return headAnchor?.position(relativeTo: nil) ?? SIMD3<Float>(0, 1.6, 0)
                    }
                )
            }
            
            // 회전 버튼과 Toolbar (Volume용)
            if config.showRotationButton {
                rotationButton
            }
        }
        .alert("바닥 이미지 선택", isPresented: $showFloorImageAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("바닥으로 설정할 이미지를 선택해주세요.")
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
        
        // Volume Window일 떄
        if config.alignToWindowBottom {
            content.add(room)

            // Floor 하단 정렬
            viewModel.alignRoomToWindowBottom(room: room, windowHeight: 1.5) // VolumeWindow의 Height값
            
        // Immersive일 때
        } else {
            // Immersive/Minimap 모드: 기존 방식
            room.scale = config.floorSize
            room.position = [0, 0.1, 0]
            content.add(room)

            // Immersive 전용: RealityKit Content
            if config.alignToWindowBottom == false {  // immersive 또는 minimap
                if let immersiveContent = try? await Entity(named: "ImmersiveScene", in: RealityKitContent.realityKitContentBundle) {
                    content.add(immersiveContent)
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

    // MARK: - Floor Attachment Positioning

    private func positionFloorAttachment(_ attachment: Entity, on floor: Entity, room: Entity) {
        attachment.name = "floorImageApplyButton"
        room.addChild(attachment)

        let yOffset: Float = 0.05
        attachment.position = SIMD3<Float>(0, floor.position.y + yOffset, 0)

        // Floor 크기의 1/8로 버튼 크기 설정
        let floorWidth = floor.scale.x
        let floorDepth = floor.scale.z
        let minDimension = min(floorWidth, floorDepth)
        let buttonSize = minDimension / 8
        attachment.scale = [buttonSize, buttonSize, buttonSize]

        // Rotate to lay flat on floor (X-axis rotation)
        attachment.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
    }
    
    // MARK: - 회전 버튼과 Toolbar (Volume용)
    
    @State private var isAnimating = false
    
    private var rotationButton: some View {
        VStack(spacing: 12) {
            if appModel.selectedProject == nil {
                Button {
                    openWindow(id: "MainWindow")
                    dismissWindow(id: "ImmersiveVolumeWindow")
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            } else {
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
