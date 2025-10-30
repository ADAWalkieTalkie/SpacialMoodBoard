//
//  ImageAssetServiceInterface.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/30/25.
//

import Foundation
import CryptoKit
import ImageIO // 픽셀 크기 메타 읽기
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Service Protocol

protocol ImageAssetServiceProtocol {
    // 목록/경로/메타
    func list(project: String) throws -> [String]
    func url(project: String, filename: String) -> URL
    func meta(for url: URL) -> (fileSize: Int, createdAt: Date, pixelWidth: Int, pixelHeight: Int)
    
    // 존재/읽기/쓰기/삭제
    func exists(project: String, filename: String) -> Bool
    func load(project: String, filename: String) throws -> Data
    func save(_ data: Data, project: String, filename: String) throws
    func delete(project: String, filename: String) throws
    
    // 편의 작업
    func rename(project: String, from oldName: String, to newName: String) throws
    func copy(project: String, from srcName: String, to dstName: String) throws
    func uniqueFilename(project: String, base: String, ext: String) -> String
    
    // 해시
    func sha256Hex(url: URL) throws -> String
    
#if canImport(UIKit)
    func save(_ image: UIImage, project: String, filename: String) throws
#endif
}
