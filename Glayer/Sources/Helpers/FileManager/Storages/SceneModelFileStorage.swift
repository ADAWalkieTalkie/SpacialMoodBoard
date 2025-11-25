// SceneModelFileStorage.swift
import Foundation

// MARK: - SceneModel File Storage (SceneModel JSON 관리)
/// func load에서 유일한게 UUID를 받아야 해서 FileStorageProtocol을 사용하지 않음

struct SceneModelFileStorage {
    typealias DataType = SceneModel

    private let fileManager = FileManager.default
    private let projectRepository: ProjectServiceInterface?

    init(projectRepository: ProjectServiceInterface? = nil) {
        self.projectRepository = projectRepository
    }

    // MARK: - 저장용 구조체 (userSpatialState 제외, SceneObject의 id 제외)
    
    private struct SavedSceneModel: Codable {
        let projectId: UUID
        let spacialEnvironment: SpacialEnvironment
        let sceneObjects: [SavedSceneObject]
    }

    private struct SavedSceneObject: Codable {
        let assetId: String
        let position: SIMD3<Float>
        let isEditable: Bool
        let attributes: ObjectAttributes
        
        /// SceneObject에서 변환 (id 제외)
        init(from sceneObject: SceneObject) {
            self.assetId = sceneObject.assetId
            self.position = sceneObject.position
            self.isEditable = sceneObject.isEditable
            self.attributes = sceneObject.attributes
        }
        
        /// json에서 SceneObject로 변환 시 새 id 생성
        func toSceneObject() -> SceneObject {
            return SceneObject(
                id: UUID(),
                assetId: assetId,
                position: position,
                isEditable: isEditable,
                attributes: attributes
            )
        }
    }
    
    // MARK: - Save

    @MainActor
    func save(_ sceneModel: SceneModel, projectName: String) throws {
        let projectDir = FilePathProvider.projectDirectory(projectName: projectName)

        // 디렉토리가 없으면 생성
        try createDirectoryIfNeeded(at: projectDir)

        let fileURL = FilePathProvider.projectMetadataFile(projectName: projectName)

        // userSpatialState와 projectId 제외하고 저장
        let savedModel = SavedSceneModel(
            projectId: sceneModel.projectId,
            spacialEnvironment: sceneModel.spacialEnvironment,
            sceneObjects: sceneModel.sceneObjects.map { SavedSceneObject(from: $0) }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let jsonData = try encoder.encode(savedModel)
        try jsonData.write(to: fileURL, options: [.atomic, .completeFileProtection])

        print("📁 SceneModel 저장 완료: \(fileURL.path)")

        // Project의 updatedAt 갱신
        if let repository = projectRepository {
            // sceneModel.projectId로 Project 조회 후 updateProject 호출
            let tempProject = Project(id: sceneModel.projectId, title: "")
            if let existingProject = repository.fetchProject(tempProject) {
                repository.updateProject(existingProject)
            }
        }
    }
    
    // MARK: - Load
    
    /// SceneModel 로드
    /// - Parameters:
    ///   - projectName: 프로젝트 이름
    ///   - projectId: 프로젝트 ID (복원 시 필요)
    func load(projectName: String, projectId: UUID) throws -> SceneModel {
        let fileURL = FilePathProvider.projectMetadataFile(projectName: projectName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileStorageError.fileNotFound
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let savedModel = try decoder.decode(SavedSceneModel.self, from: data)

        let sceneModel = SceneModel(
            projectId: savedModel.projectId,
            spacialEnvironment: savedModel.spacialEnvironment,
            userSpatialState: UserSpatialState(),
            sceneObjects: savedModel.sceneObjects.map { $0.toSceneObject() }
        )
        
        print("📂 SceneModel 로드 완료: \(savedModel.sceneObjects.count)개 객체")
        
        return sceneModel
    }
    
    // MARK: - Delete
    
    func delete(projectName: String) throws {
        let fileURL = FilePathProvider.projectMetadataFile(projectName: projectName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("🗑️ 삭제할 SceneModel 파일 없음")
            return
        }
        
        try fileManager.removeItem(at: fileURL)
        print("🗑️ SceneModel 파일 삭제 완료")
    }
    
    // MARK: - Exists
    
    func exists(projectName: String) -> Bool {
        let fileURL = FilePathProvider.projectMetadataFile(projectName: projectName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - Helper
    
    private func createDirectoryIfNeeded(at url: URL) throws {
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
