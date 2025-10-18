// ProjectFileStorage.swift
import Foundation

/// 프로젝트 메타데이터 JSON 관리
struct ProjectFileStorage: FileStorageProtocol {
    typealias DataType = Project
    
    private let fileManager = FileManager.default
    
    func save(_ data: Project, projectName: String) throws {
        // 프로젝트 디렉토리 생성
        let projectDir = FilePathProvider.projectDirectory(projectName: projectName)
        try createDirectoryIfNeeded(at: projectDir)
        
        // images, sounds 폴더도 미리 생성
        try createDirectoryIfNeeded(at: FilePathProvider.imagesDirectory(projectName: projectName))
        try createDirectoryIfNeeded(at: FilePathProvider.soundsDirectory(projectName: projectName))
        
        // JSON 저장
        let fileURL = FilePathProvider.projectMetadataFile(projectName: projectName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: fileURL, options: [.atomic, .completeFileProtection])
        
        print("📁 프로젝트 저장 완료: \(fileURL.path)")
    }
    
    func load(projectName: String) throws -> Project {
        let fileURL = FilePathProvider.projectMetadataFile(projectName: projectName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileStorageError.fileNotFound
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let project = try decoder.decode(Project.self, from: data)
        print("📂 프로젝트 로드 완료: \(projectName)")
        
        return project
    }
    
    func delete(projectName: String) throws {
        let projectDir = FilePathProvider.projectDirectory(projectName: projectName)
        
        guard fileManager.fileExists(atPath: projectDir.path) else {
            print("🗑️ 삭제할 프로젝트 없음: \(projectName)")
            return
        }
        
        try fileManager.removeItem(at: projectDir)
        print("🗑️ 프로젝트 삭제 완료: \(projectName)")
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