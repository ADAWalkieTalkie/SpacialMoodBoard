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
                await setupScene(content: content, rootEntity: rootEntity)
                content.add(rootEntity)
                
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

                // Volume 모드: base scale (0.2) × dynamic scale
                if appStateManager.appState.isVolumeOpen {
                    rootEntity.volumeResize(content, proxy, Self.defaultVolumeSize)
                }
                
                // MainActor에서 실행
                MainActor.assumeIsolated {

                    updateAttachments()

                    // Gesture 진행 중이 아닐 때만 updateScene 호출
                    if !viewModel.isGestureActive {
                        updateScene(content: content, rootEntity: rootEntity)
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
                    },
                    onGestureStart: {
                        viewModel.startGesture()
                    },
                    onGestureEnd: {
                        viewModel.endGesture()
                        viewModel.updateAttachmentScales()
                    }
                )
            }
        }
    }
    
    // MARK: - Setup Scene
    
    private func setupScene(content: RealityViewContent, rootEntity: Entity) async {
        guard let floor = await viewModel.getFloorEntity() else {
            return
        }
        // Volume Window일 때
        if appStateManager.appState.isVolumeOpen {
            rootEntity.addChild(floor)
            floor.transform.translation = [0, Float(Self.defaultVolumeSize.height / 2) * -1, 0]

            // Volume에서 설정된 회전 각도 적용
            let rotation = simd_quatf(angle: viewModel.rotationAngle, axis: [0, 1, 0])
            rootEntity.transform.rotation = rotation

            // Immersive일 때
        } else if appStateManager.appState.isImmersiveOpen {
            rootEntity.transform.translation = config.rootEntityPosition
            floor.transform.translation = viewModel.getFloorPosition(windowHeight: Float(Self.defaultVolumeSize.height))
            rootEntity.scale = config.rootEntityscale
            let humanScaleEntity = floor.findEntity(named: "humanScaleEntity")
            floor.removeChild(humanScaleEntity!)
            rootEntity.addChild(floor)
            
            // Immersive 전용: RealityKit Content
            if let immersiveContent = try? await Entity(named: "Immersive", in: RealityKitContent.realityKitContentBundle) {
                rootEntity.addChild(immersiveContent)
                immersiveContent.position = [0, -0.6, 0]
            }
            
            // Volume에서 설정된 회전 각도를 Immersive에도 적용
            let rotation = simd_quatf(angle: viewModel.rotationAngle, axis: [0, 1, 0])
            rootEntity.transform.rotation = rotation
        }
    }
    
    // MARK: - Update Scene
    
    private func updateScene(content: RealityViewContent, rootEntity: Entity) {
        let sceneObjects = viewModel.sceneObjects
        
        viewModel.updateEntities(
            sceneObjects: sceneObjects,
            rootEntity: rootEntity
        )
        updateFloorMaterial(content: content, rootEntity: rootEntity)
    }

    private func updateFloorMaterial(content: RealityViewContent, rootEntity: Entity) {
        let currentFloorURL = viewModel.floorImageURL
        if currentFloorURL != viewModel.appliedFloorImageURL,
        let floor = rootEntity.findEntity(named: "floorRoot") as? ModelEntity {
            Task {
                await viewModel.updateFloorMaterial(on: floor, with: currentFloorURL)
            }
        }
    }

    // MARK: - Update Attachment Scales
    
    private func updateAttachments() {
        // Head Anchor 위치 추적 및 동기화
        guard let headAnchor = headAnchor else { return }
        
        // Volume과 Immersive 모드에 따라 다른 기준점 사용
        let headPosition: SIMD3<Float>
        
        if appStateManager.appState.isVolumeOpen {
            // Volume 모드: rootEntity 기준 (로컬 좌표계)
            headPosition = headAnchor.position(relativeTo: rootEntity)
        } else {
            // Immersive 모드: 월드 좌표계
            headPosition = headAnchor.position(relativeTo: nil)
        }
        
        viewModel.updateUserPosition(headPosition)
        
        // Attachment 스케일 실시간 업데이트
        if viewModel.selectedEntity != nil {
            viewModel.updateAttachmentScales()
        }
    }
}
