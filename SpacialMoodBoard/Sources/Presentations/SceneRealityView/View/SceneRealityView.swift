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

    let toolbarPosition: SIMD3<Float> = SIMD3<Float>(0, -0.2, -0.5)

    @State private var headAnchor: AnchorEntity?
    @State private var rootEntity = Entity()

    private static let defaultVolumeSize = Size3D(width: 1.0, height: 1.0, depth: 1.0)

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

            } update: { content, attachments in
                if config.alignToWindowBottom {
                    rootEntity.volumeResize(content, proxy, Self.defaultVolumeSize)
                }

                // MainActor에서 실행
                MainActor.assumeIsolated {
                    updateScene(content: content, rootEntity: rootEntity)

                    // Floor material 업데이트 (Asset ID → URL 자동 조회)
                    let currentFloorURL = viewModel.floorImageURL
                    if currentFloorURL != viewModel.appliedFloorImageURL,
                       let floor = rootEntity.findEntity(named: "floorRoot") as? ModelEntity {
                        Task {
                            await viewModel.updateFloorMaterial(on: floor, with: currentFloorURL)
                        }
                    }
                }
            } attachments: {
                Attachment(id: "headToolbar"){
                    ToolBarAttachment(viewModel: viewModel)
                        .environment(appStateManager)
                }
            }
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
                    }
                )
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
            viewModel.alignFloorToWindowBottom(floor, windowHeight: Float(Self.defaultVolumeSize.height)) // VolumeWindow의 Height값

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
}
