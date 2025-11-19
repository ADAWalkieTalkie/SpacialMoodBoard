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
    
    // MARK: 번들 내 기본 이미지 에셋 조회
    
    func listBuiltins(subdirectory: String) -> [Asset] {
        let fm = FileManager.default
        let exts = ["jpg", "jpeg", "png", "heic"]
        var assets: [Asset] = []
        
        guard let root = Bundle.main.resourceURL?
            .appendingPathComponent(subdirectory, isDirectory: true) else {
            return []
        }
        
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            guard exts.contains(ext) else { continue }
            
            if let asset = makeBuiltinImageAsset(
                from: fileURL,
                rootDirectoryName: subdirectory
            ) {
                assets.append(asset)
            }
        }
        return assets
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
    
    /// 번들 내부의 이미지 파일 URL을 읽어 `Asset` 모델로 변환
    /// - Parameters:
    ///   - src: 번들 내 이미지 파일의 절대 URL
    ///   - rootDirectoryName: 최상위 이미지 에셋 폴더 이름 (예: "BasicImageAssets")
    /// - Returns: 변환된 `Asset` 객체. 이미지가 아닌 경우 또는 메타 정보 추출 실패 시 `nil`
    private func makeBuiltinImageAsset(from src: URL, rootDirectoryName: String) -> Asset? {
        var fileSize = 0
        var createdAt = Date()
        if let rv = try? src.resourceValues(forKeys: [.fileSizeKey, .creationDateKey]) {
            fileSize = rv.fileSize ?? 0
            createdAt = rv.creationDate ?? Date()
        }
        
        let (_, _, pixelW, pixelH) = meta(for: src)
        
        let channel = inferImageChannel(from: src, rootDirectoryName: rootDirectoryName)
        let h = (try? sha256Hex(url: src)) ?? UUID().uuidString
        let displayName = src.deletingPathExtension().lastPathComponent
        let imageInfo = ImageAsset(
            origin: .basic,
            channel: channel,
            width: pixelW,
            height: pixelH
        )
        
        return Asset(
            id: h,
            type: .image,
            filename: displayName,
            filesize: fileSize,
            url: src,
            createdAt: createdAt,
            image: imageInfo,
            sound: nil
        )
    }
    
    /// 이미지 파일 URL의 경로에서, 상위 폴더명을 기반으로 `ImageChannel`(카테고리)을 추론
    /// - Parameters:
    ///   - url: 이미지 파일의 절대 URL
    ///   - rootDirectoryName: 에셋의 루트 폴더 이름 (예: "BasicImageAssets")
    /// - Returns: 해당 이미지의 카테고리를 나타내는 `ImageChannel`
    private func inferImageChannel(from url: URL, rootDirectoryName: String) -> ImageChannel? {
        let components = url.pathComponents
        
        guard let rootIndex = components.firstIndex(of: rootDirectoryName),
              components.count > rootIndex + 1
        else {
            return nil
        }
        
        let folderName = components[rootIndex + 1].lowercased()
        
        switch folderName {
        case "backgrounds":
            return .background
        case "dogs&cats":
            return .animal
        case "electronics":
            return .electronic
        case "floors":
            return .floor
        case "furniture":
            return .furniture
        case "lights":
            return .light
        case "plants":
            return .plant
        default:
            return nil
        }
    }
}
