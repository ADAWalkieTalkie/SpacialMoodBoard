// FilePathProvider.swift
import Foundation

/// 앱의 모든 파일 경로를 관리하는 Provider
struct FilePathProvider {
    
    // MARK: - 기본 경로
    
    /// Documents 디렉토리
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// glayer/projects 루트 폴더(향후 projects 폴더 이외의 폴더가 생성될 경우 수정 필요)
    static var projectsDirectory: URL {
        documentsDirectory
            .appendingPathComponent("projects")
    }
    
    // MARK: - 프로젝트별 경로
    static func projectDirectory(projectName: String) -> URL {
        projectsDirectory.appendingPathComponent(projectName)
    }
    
    // MARK: - 프로젝트 메타데이터 JSON 파일
    // SceneModel 저장용 - Project 객체는 인메모리 DB에 저장
    static func projectMetadataFile(projectName: String) -> URL {
        projectDirectory(projectName: projectName)
            .appendingPathComponent("\(projectName)_project.json")
    }
    
    // MARK: - 프로젝트의 이미지
    static func imagesDirectory(projectName: String) -> URL {
        projectDirectory(projectName: projectName)
            .appendingPathComponent("images")
    }

    static func imageFile(projectName: String, filename: String) -> URL {
        imagesDirectory(projectName: projectName)
            .appendingPathComponent(filename)
    }
    

    // MARK: - 프로젝트의 사운드
    static func soundsDirectory(projectName: String) -> URL {
        projectDirectory(projectName: projectName)
            .appendingPathComponent("sounds")
    }
    static func soundFile(projectName: String, filename: String) -> URL {
        soundsDirectory(projectName: projectName)
            .appendingPathComponent(filename)
    }
}
