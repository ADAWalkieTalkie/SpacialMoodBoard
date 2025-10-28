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
    let sceneRepository: SceneRepositoryInterface
    let assetRepository: AssetRepositoryInterface
    let entityBuilder: RoomEntityBuilder
    
    // MARK: - Initialization
    init(appModel: AppModel,
         sceneRepository: SceneRepositoryInterface,
         assetRepository: AssetRepositoryInterface,
         projectRepository: ProjectRepository? = nil
    ) {
        self.appModel = appModel
        self.sceneModelFileStorage = SceneModelFileStorage(projectRepository: projectRepository)
        self.sceneRepository = sceneRepository
        self.assetRepository = assetRepository
        self.entityBuilder = RoomEntityBuilder()
    }
    
    
    // MARK: - State
    var selectedSceneModel: SceneModel?
    
    // MARK: - Entity Management
    /// Environment, sceneObjects를 분리해서 관리.
    /// 향후 보기모드에서 Entity에 component를 추가 삭제 하기 편한게 하기 위해서.
    /// Room Entity 캐시
    var roomEntities: [UUID: Entity] = [:]
    /// SceneObject의 RealityKit 내 Entity 맵
    var entityMap: [UUID: ModelEntity] = [:]
    var selectedEntity: ModelEntity?
    
    // 회전 각도 (Volume용)
    var rotationAngle: Float = 0
    
    // Floor 이미지 선택 모드
    var isSelectingFloorImage: Bool = false
    
    // SceneObjects (computed property)
    var sceneObjects: [SceneObject] {
        get {
            appModel.selectedScene?.sceneObjects ?? []
        }
        set {
            // 1) 이전/이후 id 집합 비교
            let oldIDs = Set((appModel.selectedScene?.sceneObjects ?? []).map(\.id))
            let newIDs = Set(newValue.map(\.id))
            let added = newIDs.subtracting(oldIDs)
            let removed = oldIDs.subtracting(newIDs)
            
            if !added.isEmpty {
                print("🆕 Added SceneObject id(s):", added.map(\.uuidString).joined(separator: ", "))
            }
            if !removed.isEmpty {
                print("🗑️ Removed SceneObject id(s):", removed.map(\.uuidString).joined(separator: ", "))
            }
            
            // 2) 값 타입일 때 변화 전파를 위해 통째로 재대입
            if var s = appModel.selectedScene {
                s.sceneObjects = newValue
                appModel.selectedScene = s
            } else {
                // nil-safe fallback
                appModel.selectedScene?.sceneObjects = newValue
            }
            
            saveScene()
        }
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
    
    
    // MARK: - Cleanup
    
    func reset() {
        entityMap.removeAll()
        selectedEntity = nil
        roomEntities.removeAll()
        rotationAngle = 0
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
        
        // Room entity 캐시 무효화 (다음 getRoomEntity 호출 시 새 material로 재생성됨)
        if let projectId = appModel.selectedProject?.id {
            roomEntities.removeValue(forKey: projectId)
        }
        
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
    
    /// 오디오 볼륨 조절의 경우 일정 시간동안 추가 변경이 없을 때만 저장
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
