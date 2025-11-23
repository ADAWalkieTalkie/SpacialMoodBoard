import Foundation
import RealityKit
import Observation
import SwiftUI

@MainActor
@Observable
final class SceneViewModel {
    
    // MARK: - Dependencies
    let appStateManager: AppStateManager
    let sceneModelFileStorage: SceneModelFileStorage
    let sceneObjectRepository: SceneObjectRepositoryInterface
    let assetRepository: AssetRepositoryInterface
    let entityRepository: EntityRepositoryInterface
    let createObjectUseCase: CreateObjectUseCase
    private var needsEntitySync: Bool = false

    // MARK: - Initialization
    init(appStateManager: AppStateManager,
         sceneModelFileStorage: SceneModelFileStorage,
         sceneObjectRepository: SceneObjectRepositoryInterface,
         assetRepository: AssetRepositoryInterface,
         entityRepository: EntityRepositoryInterface
    ) {
        self.appStateManager = appStateManager
        self.sceneModelFileStorage = sceneModelFileStorage
        self.sceneObjectRepository = sceneObjectRepository
        self.assetRepository = assetRepository
        self.entityRepository = entityRepository
        self.createObjectUseCase = CreateObjectUseCase(
            assetRepository: assetRepository,
            sceneObjectRepository: sceneObjectRepository,
            entityRepository: entityRepository
        )
    }
    
    
    // MARK: - State
    var selectedSceneModel: SceneModel?

    // MARK: - Gesture State Management
    // Gesture 진행 중인지 추적하는 플래그
    var isGestureActive: Bool = false
    func startGesture() {
        isGestureActive = true
    }
    func endGesture() {
        isGestureActive = false
    }

    // MARK: - Entity Management

    /// Attachment 관련 상태 관리
    var selectedEntity: ModelEntity? {
        didSet {
            handleSelectedEntityChange(oldValue: oldValue, newValue: selectedEntity)
        }
    }
    var attachmentTimer: FunctionTimer?

    /// Root Entity 참조 (회전 등의 작업에 사용)
    weak var rootEntity: Entity?

    // 조이스틱 속도 (rootEntity 이동용)
    var joystickVelocity: SIMD3<Float> = SIMD3<Float>(0, 0, 0)

    // 조이스틱 활성화 상태 (Timer 제어용)
    var isJoystickActive: Bool = false {
        didSet {
            if isJoystickActive {
                startJoystickMovement()
            } else {
                stopJoystickMovement()
            }
        }
    }

    // Toast 표시 상태
    var showLoadingEntityToast: Bool = true  

    // 조이스틱 업데이트용 Timer
    var joystickUpdateTimer: Timer?

    // 시간 추적 (deltaTime 계산용)
    let timeTracker = TimeTracker()

    // 회전 각도 (Volume용)
    var rotationAngle: Float = 0

    // Floor에 적용된 이미지 URL
    var appliedFloorImageURL: URL?

    // 현재 표시 중인 Immersive 배경 Entity (낮/밤 전환용)
    var currentImmersiveBackground: Entity?

    // SceneObjects (computed property)
    var sceneObjects: [SceneObject] {
        guard let scene = appStateManager.selectedScene else { return [] }
        return sceneObjectRepository.getAllObjects(from: scene)
    }
    
    // UserSpatialState (computed property)
    var userSpatialState: UserSpatialState {
        get {
            appStateManager.selectedScene?.userSpatialState ?? UserSpatialState()
        }
        set {
            appStateManager.updateUserSpatialState(newValue)

        }
    }
    
    // SpacialEnvironment (computed property)
    var spacialEnvironment: SpacialEnvironment {
        get {
            appStateManager.selectedScene?.spacialEnvironment ?? SpacialEnvironment()
        }
        set {
            appStateManager.updateSpacialEnvironment(newValue)
        }
    }
    
    // 자동 저장을 디바운스하기 위한 예약 작업 핸들러
    private var autosaveWorkItem: DispatchWorkItem?

    // 볼륨에서 생성하는 위치(immersive의 경우 headAnchor 기반이서 초기 위치 설정 필요 x)
    let defaultRespawnPositionVolume: SIMD3<Float> = SIMD3<Float>(0, -SceneConstants.floorHalfSize + 0.2, -0.3)
    
    
    // MARK: - Cleanup

    func reset() {
        entityRepository.clearAllCaches()
        selectedEntity = nil
        stopJoystickMovement()
    }

    // MARK: - Scene Persistence
    
    /// SceneModel을 디스크에 저장
    func saveScene() {
        guard let scene = appStateManager.selectedScene,
              let projectName = appStateManager.appState.selectedProject?.title else {
            print("⚠️ SceneModel 저장 실패: 프로젝트 또는 씬이 없음")
            return
        }
        
        do {
            try sceneModelFileStorage.save(scene, projectName: projectName)
            print("자동 저장")
        } catch {
            print("❌ SceneModel 저장 실패: \(error)")
        }
    }
    
    /// 일정 시간동안 추가 변경이 없을 때만 저장
    /// - Parameter delay: 저장될때까지 변경이 없어야하는 시간
    func scheduleSceneAutosaveDebounced(_ delay: TimeInterval = 0.6) {
        autosaveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.saveScene()
        }
        autosaveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
}
