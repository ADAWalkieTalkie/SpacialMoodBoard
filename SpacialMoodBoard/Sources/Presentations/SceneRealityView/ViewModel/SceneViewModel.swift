import Foundation
import RealityKit
import Observation
import SwiftUI

@MainActor
@Observable
final class SceneViewModel {
    
    // MARK: - Dependencies
    let appModel: AppModel
    let sceneModelFileStorage: SceneModelFileStorage
    let sceneObjectRepository: SceneObjectRepositoryInterface
    let assetRepository: AssetRepositoryInterface
    let entityRepository: EntityRepositoryInterface
    let createObjectUseCase: CreateObjectUseCase
    private var needsEntitySync: Bool = false

    // MARK: - Initialization
    init(appModel: AppModel,
         sceneObjectRepository: SceneObjectRepositoryInterface,
         assetRepository: AssetRepositoryInterface,
         entityRepository: EntityRepositoryInterface,
         projectRepository: ProjectServiceInterface? = nil
    ) {
        self.appModel = appModel
        self.sceneModelFileStorage = SceneModelFileStorage(projectRepository: projectRepository)
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

    // MARK: - Entity Management
    /// 현재 선택된 엔티티 (UI 상태 관리용)
    /// Note: entityMap과 floor 캐시는 entityRepository가 관리
    var selectedEntity: ModelEntity?
    
    // 회전 각도 (Volume용)
    var rotationAngle: Float = 0
    
    // Floor 이미지 선택 모드
    var isSelectingFloorImage: Bool = false
    
    // SceneObjects (computed property)
    var sceneObjects: [SceneObject] {
        guard let scene = appModel.selectedScene else { return [] }
        return sceneObjectRepository.getAllObjects(from: scene)
    }
    
    // UserSpatialState (computed property)
    var userSpatialState: UserSpatialState {
        get {
            appModel.selectedScene?.userSpatialState ?? UserSpatialState()
        }
        set {
            appModel.selectedScene?.userSpatialState = newValue
        }
    }
    
    // SpacialEnvironment (computed property)
    var spacialEnvironment: SpacialEnvironment {
        get {
            appModel.selectedScene?.spacialEnvironment ?? SpacialEnvironment()
        }
        set {
            appModel.selectedScene?.spacialEnvironment = newValue
        }
    }
    
    // 자동 저장을 디바운스하기 위한 예약 작업 핸들러
    private var autosaveWorkItem: DispatchWorkItem?

    // 5초 타이머를 관리하기 위한 Task 저장
    var attachmentTimerTask: Task<Void, Never>?
    
    
    // MARK: - Cleanup

    func reset() {
        entityRepository.clearAllCaches()
        selectedEntity = nil
        rotationAngle = 0
        attachmentTimerTask?.cancel()
        attachmentTimerTask = nil
    }
    
    // MARK: - Floor Material Management
    
    func applyFloorImage(from asset: Asset) {
        guard asset.type == .image else {
            return
        }
        
        // Documents 디렉토리로부터의 상대 경로 계산
        let relativePath: String?
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let documentsPathWithSlash = documentsURL.path + "/"
            if asset.url.path.hasPrefix(documentsPathWithSlash) {
                relativePath = String(asset.url.path.dropFirst(documentsPathWithSlash.count))
            } else {
                print("⚠️ Asset이 Documents 디렉토리 내에 없음: \(asset.url.path)")
                relativePath = nil
            }
        } else {
            print("⚠️ Documents 디렉토리를 찾을 수 없음")
            relativePath = nil
        }
        
        // SpacialEnvironment에 floor material URL과 상대 경로 저장
        var updatedEnvironment = spacialEnvironment
        updatedEnvironment.floorMaterialImageURL = asset.url
        updatedEnvironment.floorImageRelativePath = relativePath
        spacialEnvironment = updatedEnvironment

        // Floor entity 캐시 초기화 (다음 호출 시 새 material로 재생성됨)
        entityRepository.clearFloorCache()

        // 선택 모드 해제
        isSelectingFloorImage = false
        
        // 변경사항 저장
        saveScene()
    }
    
    // MARK: - Scene Persistence
    
    /// SceneModel을 디스크에 저장
    func saveScene() {
        guard let scene = appModel.selectedScene,
              let projectName = appModel.selectedProject?.title else {
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
