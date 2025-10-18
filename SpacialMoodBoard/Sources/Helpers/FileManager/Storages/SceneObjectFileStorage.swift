// SceneObjectFileStorage.swift
import Foundation

/// SceneObject 목록 JSON 관리
struct SceneObjectFileStorage: FileStorageProtocol {
    typealias DataType = [SceneObject]
    
    private let fileManager = FileManager.default
    
    func save(_ data: [SceneObject], projectName: String) throws {
        let projectDir = FilePathProvider.projectDirectory(projectName: projectName)
        
        // ✅ 디렉토리가 없으면 생성
        try createDirectoryIfNeeded(at: projectDir)
        
        let fileURL = FilePathProvider.projectMetadataFile(projectName: projectName)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: fileURL, options: [.atomic, .completeFileProtection])
        
        print("📁 SceneObjects 저장 완료: \(fileURL.path)")
    }
    
    func load(projectName: String) throws -> [SceneObject] {
        let fileURL = FilePathProvider.projectMetadataFile(projectName: projectName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("📂 저장된 SceneObjects 없음 - 빈 배열 반환")
            return []
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let sceneObjects = try decoder.decode([SceneObject].self, from: data)
        print("📂 SceneObjects 로드 완료: \(sceneObjects.count)개")
        
        return sceneObjects
    }
    
    func delete(projectName: String) throws {
        let fileURL = FilePathProvider.projectMetadataFile(projectName: projectName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("🗑️ 삭제할 SceneObjects 파일 없음")
            return
        }
        
        try fileManager.removeItem(at: fileURL)
        print("🗑️ SceneObjects 파일 삭제 완료")
    }
    
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