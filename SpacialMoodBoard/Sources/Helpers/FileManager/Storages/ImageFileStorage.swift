// ImageFileStorage.swift
import Foundation
import UIKit

/// 이미지 파일 관리
struct ImageFileStorage {
    
    private let fileManager = FileManager.default
    
    /// 이미지 저장 (Data 기반)
    func save(_ imageData: Data, projectName: String, filename: String) throws {
        let imageDir = FilePathProvider.imagesDirectory(projectName: projectName)
        try createDirectoryIfNeeded(at: imageDir)
        
        let fileURL = FilePathProvider.imageFile(projectName: projectName, filename: filename)
        try imageData.write(to: fileURL, options: [.atomic, .completeFileProtection])
        
        print("🖼️ 이미지 저장 완료: \(fileURL.path)")
    }
    
    /// 이미지 저장 (UIImage 기반) - iOS/visionOS
    #if canImport(UIKit)
    func save(_ image: UIImage, projectName: String, filename: String) throws {
        guard let imageData = image.pngData() else {
            throw FileStorageError.invalidData
        }
        try save(imageData, projectName: projectName, filename: filename)
    }
    #endif
    
    /// 이미지 로드
    func load(projectName: String, filename: String) throws -> Data {
        let fileURL = FilePathProvider.imageFile(projectName: projectName, filename: filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileStorageError.fileNotFound
        }
        
        return try Data(contentsOf: fileURL)
    }
    
    /// 특정 이미지 삭제
    func delete(projectName: String, filename: String) throws {
        let fileURL = FilePathProvider.imageFile(projectName: projectName, filename: filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("🗑️ 삭제할 이미지 없음: \(filename)")
            return
        }
        
        try fileManager.removeItem(at: fileURL)
        print("🗑️ 이미지 삭제 완료: \(filename)")
    }
    
    /// 프로젝트의 모든 이미지 목록
    func listImages(projectName: String) throws -> [String] {
        let imageDir = FilePathProvider.imagesDirectory(projectName: projectName)
        
        guard fileManager.fileExists(atPath: imageDir.path) else {
            return []
        }
        
        return try fileManager.contentsOfDirectory(atPath: imageDir.path)
            .filter { $0.hasSuffix(".jpg") || $0.hasSuffix(".png") || $0.hasSuffix(".jpeg") }
    }
    
    /// 이미지 존재 확인
    func exists(projectName: String, filename: String) -> Bool {
        let fileURL = FilePathProvider.imageFile(projectName: projectName, filename: filename)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - Helper
    
    private func createDirectoryIfNeeded(at url: URL) throws {
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
