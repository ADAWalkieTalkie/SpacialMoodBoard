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
    
    let toolbarPosition: SIMD3<Float> = SIMD3<Float>(0, -0.2, -0.65)
    
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
                    
                    // 테스트: RealityView attachments를 통해 EditBar 부착
                    if let testEntity = viewModel.testSampleEntity,
                    let info = viewModel.testAttachmentInfo,
                    let editBarAttachment = attachments.entity(for: "testEditBar") {
                        
                        // 기존에 부착된 테스트 attachment 제거
                        testEntity.children
                            .filter { $0.name == "testEditBarAttachment" }
                            .forEach { $0.removeFromParent() }
                        
                        // wrapper entity는 사용하지 않고 직접 부착
                        editBarAttachment.name = "testEditBarAttachment"
                        
                        // BillboardComponent 추가
                        editBarAttachment.components.set(BillboardComponent())
                        
                        // 스케일 설정 (고정값으로 테스트)
                        editBarAttachment.scale = SIMD3<Float>(repeating: 0.4)
                        
                        // Entity에 부착
                        testEntity.addChild(editBarAttachment)
                        
                        // 위치 설정 (박스 위에 배치)
                        editBarAttachment.position = SIMD3<Float>(0, 0.2, 0)
                    }
                    
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
                
                // 테스트용 EditBar Attachment
                if let info = viewModel.testAttachmentInfo {
                    Attachment(id: "testEditBar") {
                        EditBarAttachment(
                            objectId: info.objectId,
                            objectType: info.objectType,
                            initialVolume: info.initialVolume,
                            onLock: {
                                print("🔒 Lock 버튼 클릭")
                            },
                            onDuplicate: {
                                print("📋 Duplicate 버튼 클릭")
                            },
                            onCrop: { isOn in
                                print("✂️ Crop 버튼 클릭: \(isOn)")
                            },
                            onDelete: {
                                print("🗑️ Delete 버튼 클릭")
                            }
                        )
                    }
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
                    },
                    onBoundaryCollision: { entity in
                        viewModel.checkBoundaryCollision(for: entity)
                    },
                    movementBounds: config.movementBounds
                )
            }
        }
    }

    // MARK: - Setup Scene
    
    private func setupScene(content: RealityViewContent, rootEntity: Entity) async {
        guard let floor = await viewModel.getFloorEntity() else {
            return
        }

        await viewModel.loadEntities(
            sceneObjects: viewModel.sceneObjects,
            rootEntity: rootEntity
        )

        // Volume Window일 때
        if appStateManager.appState.isVolumeOpen {
            
            let humanScaleEntity = await HumanScaleEntity.create()
            floor.addChild(humanScaleEntity)
            
            rootEntity.addChild(floor)
            floor.transform.translation = [0, SceneConstants.floorYOffset, 0]

            // Volume에서 설정된 회전 각도 적용
            let rotation = simd_quatf(angle: viewModel.rotationAngle, axis: [0, 1, 0])
            rootEntity.transform.rotation = rotation
            
            // 경계 벽면 설정 (제스처가 활성화된 경우)
            if config.enableGestures {
                viewModel.setupBoundaryWalls(in: rootEntity)
            }

        // Immersive일 때
        } else if appStateManager.appState.isImmersiveOpen {
            rootEntity.transform.translation = config.rootEntityPosition
            floor.transform.translation = [0, SceneConstants.floorYOffset, 0]
            rootEntity.scale = config.rootEntityscale
            rootEntity.addChild(floor)

            // humanScaleEntity 제거
            if let existingHuman = floor.findEntity(named: "humanScaleEntity") {
                existingHuman.removeFromParent()
            }

            // Immersive 전용: RealityKit Content (낮/밤 시간대에 따라 선택적 로드)
            await viewModel.loadImmersiveBackground(on: floor)

            // Volume에서 설정된 회전 각도를 Immersive에도 적용
            let rotation = simd_quatf(angle: viewModel.rotationAngle, axis: [0, 1, 0])
            rootEntity.transform.rotation = rotation

            // 경계 벽면 설정 (제스처가 활성화된 모드: Immersive 및 Volume)
            if config.enableGestures {
                viewModel.setupBoundaryWalls(in: rootEntity)
            }
        }


        // 테스트용: Sample ModelEntity 생성 (빨간 박스)
        let testEntity = ModelEntity(
            mesh: .generateBox(width: 0.3, height: 0.3, depth: 0.01),
            materials: [SimpleMaterial(color: .red, isMetallic: false)]
        )
        testEntity.name = "testSampleEntity"
        
        // 위치 설정 (floor 위에 배치)
        if appStateManager.appState.isVolumeOpen {
            testEntity.position = SIMD3<Float>(0.5, 0.2, 0) // Volume 모드
        } else {
            testEntity.position = SIMD3<Float>(0.5, 0.2, -0.5) // Immersive 모드
        }
        
        // 충돌 및 입력 처리
        testEntity.collision = CollisionComponent(
            shapes: [.generateBox(width: 0.3, height: 0.3, depth: 0.01)]
        )
        testEntity.components.set(InputTargetComponent())
        testEntity.components.set(HoverEffectComponent())
        
        rootEntity.addChild(testEntity)
        viewModel.testSampleEntity = testEntity
        
        // 테스트용 attachment 정보 설정
        let testId = UUID()
        viewModel.testAttachmentInfo = (
            objectId: testId,
            objectType: .image, // 이미지 타입으로 테스트
            initialVolume: 1.0
        )
    }
    
    // MARK: - Update Scene
    
    private func updateScene(content: RealityViewContent, rootEntity: Entity) {
        let sceneObjects = viewModel.sceneObjects
        
        viewModel.updateEntities(
            sceneObjects: sceneObjects,
            rootEntity: rootEntity
        )

        // 잠금 상태 적용: lock == true 이고 아직 lock 아이콘이 없으면 lockObject 호출
        if !viewModel.userSpatialState.viewMode {
            for obj in sceneObjects {
                if case .image(let img) = obj.attributes, img.lock {
                    if let entity = viewModel.getEntity(for: obj.id) {
                        let hasLockIcon = entity.children.contains { $0.name == "lockIconAttachment" }
                        if !hasLockIcon {
                            viewModel.lockObject(id: obj.id)
                        }
                    }
                }
            }
        }
        
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
        let headRotation: SIMD4<Float>
        
        if appStateManager.appState.isVolumeOpen {
            // Volume 모드: rootEntity 기준 (로컬 좌표계)
            headPosition = headAnchor.position(relativeTo: rootEntity)
            headRotation = SIMD4<Float>(headAnchor.orientation(relativeTo: rootEntity).vector)
        } else {
            // Immersive 모드: 월드 좌표계
            headPosition = headAnchor.position(relativeTo: nil)
            headRotation = SIMD4<Float>(headAnchor.orientation(relativeTo: nil).vector)
        }
        
        // headAnchor 정보를 UserSpatialState에 동기화
        viewModel.updateHeadAnchorState(position: headPosition, rotation: headRotation)
        
        // Attachment 스케일 실시간 업데이트
        if viewModel.selectedEntity != nil {
            viewModel.updateAttachmentScales()
        }
    }
}

