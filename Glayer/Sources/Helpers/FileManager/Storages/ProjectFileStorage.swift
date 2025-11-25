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
        
        print("📁 프로젝트 저장 완료: \(projectDir.path)")
    }
    
    func load(projectName: String) throws -> Project {
        throw FileStorageError.fileNotFound
    }

    func rename(from oldProjectName: String, to newProjectName: String) throws {
        let oldProjectDir = FilePathProvider.projectDirectory(projectName: oldProjectName)
        let newProjectDir = FilePathProvider.projectDirectory(projectName: newProjectName)

        guard fileManager.fileExists(atPath: oldProjectDir.path) else {
            throw FileStorageError.fileNotFound
        }
        guard !fileManager.fileExists(atPath: newProjectDir.path) else {
            throw FileStorageError.fileAlreadyExists
        }

        // 프로젝트 디렉토리 이름 변경
        try fileManager.moveItem(at: oldProjectDir, to: newProjectDir)
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
