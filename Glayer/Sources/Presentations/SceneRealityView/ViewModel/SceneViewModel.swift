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
    let attachmentSizeDeterminator = EntityAttachmentSizeDeterminator()
    let entityBoundBoxApplier = EntityBoundBoxApplier()
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

    // 회전 각도 (Volume용)
    var rotationAngle: Float = 0

    // Floor에 적용된 이미지 URL
    var appliedFloorImageURL: URL?
    
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
            appStateManager.selectedScene?.userSpatialState = newValue
        }
    }
    
    // SpacialEnvironment (computed property)
    var spacialEnvironment: SpacialEnvironment {
        get {
            appStateManager.selectedScene?.spacialEnvironment ?? SpacialEnvironment()
        }
        set {
            appStateManager.selectedScene?.spacialEnvironment = newValue
        }
    }
    
    // 자동 저장을 디바운스하기 위한 예약 작업 핸들러
    private var autosaveWorkItem: DispatchWorkItem?
    
    
    // MARK: - Cleanup

    func reset() {
        entityRepository.clearAllCaches()
        selectedEntity = nil
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
