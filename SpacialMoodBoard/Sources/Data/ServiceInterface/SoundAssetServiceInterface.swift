//
//  SoundAssetServiceInterface.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/30/25.
//

import Foundation
import CryptoKit
import AVFoundation

// MARK: - Service Protocol

protocol SoundAssetServiceProtocol {
    // 목록/경로/메타
    func list(project: String) throws -> [String]
    func url(project: String, filename: String) -> URL
    /// 파일 메타데이터: (파일크기, 생성일, 재생길이(sec), 샘플레이트, 채널수, 포맷명)
    func meta(for url: URL) -> (fileSize: Int, createdAt: Date, duration: Double, sampleRate: Double, channels: Int, format: String)

    // 존재/읽기/쓰기/삭제
    func exists(project: String, filename: String) -> Bool
    func load(project: String, filename: String) throws -> Data
    func save(_ data: Data, project: String, filename: String) throws
    func delete(project: String, filename: String) throws

    // 편의 작업
    func rename(project: String, from oldName: String, to newName: String) throws
    func copy(project: String, from srcName: String, to dstName: String) throws
    func uniqueFilename(project: String, base: String, ext: String) -> String

    // 기본 사운드 조회
    func listBuiltins(subdirectory: String) -> [Asset]
    
    // 해시
    func sha256Hex(url: URL) throws -> String
}
