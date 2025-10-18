// SoundFileStorage.swift
import Foundation

/// 사운드 파일 관리
struct SoundFileStorage {
    
    private let fileManager = FileManager.default
    
    /// 사운드 저장
    func save(_ audioData: Data, projectName: String, filename: String) throws {
        let soundDir = FilePathProvider.soundsDirectory(projectName: projectName)
        try createDirectoryIfNeeded(at: soundDir)
        
        let fileURL = FilePathProvider.soundFile(projectName: projectName, filename: filename)
        try audioData.write(to: fileURL, options: [.atomic, .completeFileProtection])
        
        print("🔊 사운드 저장 완료: \(fileURL.path)")
    }
    
    /// 사운드 로드
    func load(projectName: String, filename: String) throws -> Data {
        let fileURL = FilePathProvider.soundFile(projectName: projectName, filename: filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileStorageError.fileNotFound
        }
        
        return try Data(contentsOf: fileURL)
    }
    
    /// 특정 사운드 삭제
    func delete(projectName: String, filename: String) throws {
        let fileURL = FilePathProvider.soundFile(projectName: projectName, filename: filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("🗑️ 삭제할 사운드 없음: \(filename)")
            return
        }
        
        try fileManager.removeItem(at: fileURL)
        print("🗑️ 사운드 삭제 완료: \(filename)")
    }
    
    /// 프로젝트의 모든 사운드 목록
    func listSounds(projectName: String) throws -> [String] {
        let soundDir = FilePathProvider.soundsDirectory(projectName: projectName)
        
        guard fileManager.fileExists(atPath: soundDir.path) else {
            return []
        }
        
        return try fileManager.contentsOfDirectory(atPath: soundDir.path)
            .filter { $0.hasSuffix(".mp3") || $0.hasSuffix(".wav") || $0.hasSuffix(".m4a") }
    }
    
    /// 사운드 존재 확인
    func exists(projectName: String, filename: String) -> Bool {
        let fileURL = FilePathProvider.soundFile(projectName: projectName, filename: filename)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - Helper
    
    private func createDirectoryIfNeeded(at url: URL) throws {
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}