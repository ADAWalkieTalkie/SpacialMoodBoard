//
//  ImageAssetService.swift
//  Glayer
//
//  Created by jeongminji on 10/23/25.
//

//
//  ImageAssetService.swift
//  Glayer
//

import Foundation
import CryptoKit
import ImageIO // 픽셀 크기 메타 읽기
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Service

struct ImageAssetService: ImageAssetServiceProtocol {
    private let fm = FileManager.default
    
    // MARK: 목록/경로/메타
    
    func list(project: String) throws -> [String] {
        let dir = FilePathProvider.imagesDirectory(projectName: project)
        guard fm.fileExists(atPath: dir.path) else { return [] }
        let all = try fm.contentsOfDirectory(atPath: dir.path)
        let exts = ["jpg","jpeg","png","heic"]
        return all.filter { exts.contains(URL(fileURLWithPath: $0).pathExtension.lowercased()) }
    }
    
    func url(project: String, filename: String) -> URL {
        FilePathProvider.imageFile(projectName: project, filename: filename)
    }
    
    func meta(for url: URL) -> (fileSize: Int, createdAt: Date, pixelWidth: Int, pixelHeight: Int) {
        var fileSize = 0
        var createdAt = Date()
        if let rv = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey]) {
            fileSize = rv.fileSize ?? 0
            createdAt = rv.creationDate ?? Date()
        }
        
        var w = 0, h = 0
        if let src = CGImageSourceCreateWithURL(url as CFURL, nil),
           let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any] {
            w = (props[kCGImagePropertyPixelWidth]  as? Int) ?? 0
            h = (props[kCGImagePropertyPixelHeight] as? Int) ?? 0
        }
        return (fileSize, createdAt, w, h)
    }
    
    // MARK: 존재/읽기/쓰기
    
    func exists(project: String, filename: String) -> Bool {
        fm.fileExists(atPath: url(project: project, filename: filename).path)
    }
    
    func load(project: String, filename: String) throws -> Data {
        let fileURL = url(project: project, filename: filename)
        guard fm.fileExists(atPath: fileURL.path) else {
            throw NSError(domain: "ImageAssetService", code: 404, userInfo: [NSLocalizedDescriptionKey: "file not found"])
        }
        return try Data(contentsOf: fileURL)
    }
    
    func save(_ data: Data, project: String, filename: String) throws {
        let dir = FilePathProvider.imagesDirectory(projectName: project)
        try createDirIfNeeded(dir)
        let dst = url(project: project, filename: filename)
        try data.write(to: dst, options: [.atomic, .completeFileProtection])
#if DEBUG
        print("🖼️ 저장: \(dst.lastPathComponent)")
#endif
    }
    
    func delete(project: String, filename: String) throws {
        let fileURL = url(project: project, filename: filename)
        if fm.fileExists(atPath: fileURL.path) {
            try fm.removeItem(at: fileURL)
            #if DEBUG
            print("🖼️ 삭제: \(fileURL.lastPathComponent)")
            #endif
        }
    }
    
    // MARK: 편의 작업 (이름 변경/복사/유니크명)
    
    func rename(project: String, from oldName: String, to newName: String) throws {
        let src = url(project: project, filename: oldName)
        let dst = url(project: project, filename: newName)
        guard src != dst else { return }
        try fm.moveItem(at: src, to: dst)
    }
    
    func copy(project: String, from srcName: String, to dstName: String) throws {
        let src = url(project: project, filename: srcName)
        let dst = url(project: project, filename: dstName)
        try fm.copyItem(at: src, to: dst)
    }
    
    func uniqueFilename(project: String, base: String, ext: String) -> String {
        let dir = FilePathProvider.imagesDirectory(projectName: project)
        var candidate = "\(base).\(ext)"
        var n = 1
        while fm.fileExists(atPath: dir.appendingPathComponent(candidate).path) {
            candidate = "\(base)-\(n).\(ext)"
            n += 1
        }
        return candidate
    }
    
    // MARK: 해시
    
    func sha256Hex(url: URL) throws -> String {
        let buf = 1 << 20 // 1MB
        guard let stream = InputStream(url: url) else {
            throw NSError(domain: "ImageAssetService", code: -1, userInfo: [NSLocalizedDescriptionKey: "InputStream open failed"])
        }
        stream.open(); defer { stream.close() }
        
        var hasher = SHA256()
        let scratch = UnsafeMutablePointer<UInt8>.allocate(capacity: buf)
        defer { scratch.deallocate() }
        
        while stream.hasBytesAvailable {
            let r = stream.read(scratch, maxLength: buf)
            if r > 0 {
                hasher.update(data: Data(bytesNoCopy: scratch, count: r, deallocator: .none))
            } else if r < 0 {
                throw stream.streamError ?? NSError(domain: "ImageAssetService", code: -2)
            } else { break }
        }
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
#if canImport(UIKit)
    func save(_ image: UIImage, project: String, filename: String) throws {
        let data: Data?
        data = image.pngData()
        guard let data else { throw NSError(domain: "ImageAssetService", code: -3, userInfo: [NSLocalizedDescriptionKey: "image encode failed"]) }
        try save(data, project: project, filename: filename)
    }
#endif
    
    // MARK: Helpers
    
    private func createDirIfNeeded(_ url: URL) throws {
        if !fm.fileExists(atPath: url.path) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
