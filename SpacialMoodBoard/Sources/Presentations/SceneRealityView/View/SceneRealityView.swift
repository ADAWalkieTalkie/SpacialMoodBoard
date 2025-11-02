import SwiftUI
import RealityKit
import RealityKitContent

/// 재사용 가능한 핵심 Scene RealityView
struct SceneRealityView: View {
    @Environment(AppStateManager.self) private var appStateManager
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @Binding var viewModel: SceneViewModel
    let config: SceneConfig

    let toolbarPosition: SIMD3<Float> = SIMD3<Float>(0, -0.3, -0.8)

    @State private var headAnchor: AnchorEntity?
    @State private var showFloorImageAlert = false

    @State private var rootEntity = Entity()

    private static let defaultVolumeSize = Size3D(width: 1.0, height: 1.0, depth: 1.0)

    private var sceneViewIdentifier: String {
        let projectID = appStateManager.appState.selectedProject?.id.uuidString ?? ""
        let floorImageURL = viewModel.spacialEnvironment.floorMaterialImageURL?.absoluteString ?? ""
        return "\(projectID)-\(floorImageURL)"
    }

    var body: some View {
        GeometryReader3D { proxy in
            RealityView { content, attachments in

                rootEntity.name = "RootEntity"
                content.add(rootEntity)

                await setupScene(content: content, rootEntity: rootEntity)

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
                    let floor = rootEntity.findEntity(named: "floorRoot") {
                    positionFloorAttachment(floorAttachment, on: floor)
                }
                
            } update: { content, attachments in
                if config.alignToWindowBottom {
                    rootEntity.volumeResize(content, proxy, Self.defaultVolumeSize)
                }

                // MainActor에서 실행
                MainActor.assumeIsolated {
                    updateScene(content: content, rootEntity: rootEntity)

                    // Floor attachment 재배치
                    if config.showFloorImageApplyButton,
                    let floorAttachment = attachments.entity(for: "floorImageApplyButton"),
                    let floor = rootEntity.findEntity(named: "floor") {
                        positionFloorAttachment(floorAttachment, on: floor)
                    }
                }
            } attachments: {
                Attachment(id: "headToolbar"){
                    ToolBarAttachment(viewModel: viewModel)
                        .environment(appStateManager)
                }

                if config.showFloorImageApplyButton {
                    Attachment(id: "floorImageApplyButton") {
                        FloorImageApplyButton {
                            showFloorImageAlert = true
                            viewModel.isSelectingFloorImage = true
                        }
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
            .alert("바닥 이미지 선택", isPresented: $showFloorImageAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("바닥으로 설정할 이미지를 선택해주세요.")
            }
        }
    }
    
    // MARK: - Setup Scene

    private func setupScene(content: RealityViewContent, rootEntity: Entity) async {
        guard let floor = viewModel.getFloorEntity() else {
            return
        }

        // Volume Window일 때
        if config.alignToWindowBottom {
            rootEntity.addChild(floor)

            // Floor 하단 정렬
            viewModel.alignFloorToWindowBottom(rootEntity: floor, windowHeight: 1) // VolumeWindow의 Height값

        // Immersive일 때
        } else {
            // Immersive/Minimap 모드: 기존 방식
            floor.scale = config.floorSize
            floor.position = [0, 0.1, 0]
            rootEntity.addChild(floor)

            // Immersive 전용: RealityKit Content
            if let immersiveContent = try? await Entity(named: "Immersive", in: RealityKitContent.realityKitContentBundle) {
                rootEntity.addChild(immersiveContent)
            }
        }
    }
    
    // MARK: - Update Scene

    private func updateScene(content: RealityViewContent, rootEntity: Entity) {
        let sceneObjects = viewModel.sceneObjects

        viewModel.updateEntities(
            sceneObjects: sceneObjects,
            rootEntity: rootEntity
        )

        if config.enableAttachments {
            guard let entity = viewModel.selectedEntity,
                      let objectId = UUID(uuidString: entity.name) else { return }
            
            viewModel.updateAttachment(
                onDuplicate: { _ = viewModel.duplicateObject(rootEntity: rootEntity) },
                onCrop: { /* handle */ },
                onDelete: {
                    viewModel.removeSceneObject(id: objectId)
                }
            )
        }
    }

    // MARK: - Floor Attachment Positioning

    private func positionFloorAttachment(_ attachment: Entity, on floor: Entity) {
        attachment.name = "floorImageApplyButton"

        // rootEntity에 직접 추가 (floor 회전에 영향받지 않도록)
        if attachment.parent != rootEntity {
            rootEntity.addChild(attachment)
        }

        // floor의 world position을 기준으로 attachment 위치 계산
        let floorWorldPosition = floor.position(relativeTo: rootEntity)
        let yOffset: Float = 0.05
        attachment.position = SIMD3<Float>(floorWorldPosition.x, floorWorldPosition.y + yOffset, floorWorldPosition.z)

        // Floor 크기의 1/8로 버튼 크기 설정
        let floorWidth = floor.scale.x
        let floorDepth = floor.scale.z
        let minDimension = min(floorWidth, floorDepth)
        let buttonSize = minDimension / 8
        attachment.scale = [buttonSize, buttonSize, buttonSize]

        // floor의 회전과 무관하게 항상 같은 방향 유지
        attachment.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
    }
}
