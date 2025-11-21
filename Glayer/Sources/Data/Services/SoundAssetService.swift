//
//  SoundAssetService.swift
//  Glayer
//
//  Created by jeongminji on 10/23/25.
//

import Foundation
import CryptoKit
import AVFoundation

// MARK: - Service

struct SoundAssetService: SoundAssetServiceProtocol {
    private let fm = FileManager.default
    private let allowedExts = ["mp3","m4a","wav","aac","caf","aiff","aif","flac"]
    
    // MARK: 목록/경로/메타
    
    func list(project: String) throws -> [String] {
        let dir = FilePathProvider.soundsDirectory(projectName: project)
        guard fm.fileExists(atPath: dir.path) else { return [] }
        let all = try fm.contentsOfDirectory(atPath: dir.path)
        return all.filter { allowedExts.contains(URL(fileURLWithPath: $0).pathExtension.lowercased()) }
    }
    
    func url(project: String, filename: String) -> URL {
        FilePathProvider.soundFile(projectName: project, filename: filename)
    }
    
    func meta(for url: URL) -> (fileSize: Int, createdAt: Date, duration: Double, sampleRate: Double, channels: Int, format: String) {
        var fileSize = 0
        var createdAt = Date()
        if let rv = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey]) {
            fileSize = rv.fileSize ?? 0
            createdAt = rv.creationDate ?? Date()
        }
        
        var duration: Double = 0
        var sampleRate: Double = 0
        var channels: Int = 0
        var formatName = url.pathExtension.uppercased()
        
        if let audioFile = try? AVAudioFile(forReading: url) {
            let format = audioFile.processingFormat
            sampleRate = Double(format.sampleRate)
            channels   = Int(format.channelCount)
            duration   = sampleRate > 0 ? Double(audioFile.length) / sampleRate : 0
            
            switch url.pathExtension.lowercased() {
            case "m4a", "aac": formatName = "AAC"
            case "mp3":        formatName = "MP3"
            case "wav", "aiff","aif","caf": formatName = "PCM"
            case "flac":       formatName = "FLAC"
            default: break
            }
        }
        
        return (fileSize, createdAt, duration, sampleRate, channels, formatName)
    }
    
    // MARK: 존재/읽기/쓰기
    
    func exists(project: String, filename: String) -> Bool {
        fm.fileExists(atPath: url(project: project, filename: filename).path)
    }
    
    func load(project: String, filename: String) throws -> Data {
        let fileURL = url(project: project, filename: filename)
        guard fm.fileExists(atPath: fileURL.path) else {
            throw NSError(domain: "SoundAssetService", code: 404, userInfo: [NSLocalizedDescriptionKey: "file not found"])
        }
        return try Data(contentsOf: fileURL)
    }
    
    func save(_ data: Data, project: String, filename: String) throws {
        let dir = FilePathProvider.soundsDirectory(projectName: project)
        try createDirIfNeeded(dir)
        let dst = url(project: project, filename: filename)
        try data.write(to: dst, options: [.atomic, .completeFileProtection])
#if DEBUG
        print("🔊 저장: \(dst.lastPathComponent)")
#endif
    }
    
    func delete(project: String, filename: String) throws {
        let fileURL = url(project: project, filename: filename)
        if fm.fileExists(atPath: fileURL.path) {
            try fm.removeItem(at: fileURL)
#if DEBUG
            print("🔊 삭제: \(fileURL.lastPathComponent)")
#endif
        }
    }
    
    // MARK: 편의 작업
    
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
        let dir = FilePathProvider.soundsDirectory(projectName: project)
        var candidate = "\(base).\(ext)"
        var n = 1
        while fm.fileExists(atPath: dir.appendingPathComponent(candidate).path) {
            candidate = "\(base)-\(n).\(ext)"
            n += 1
        }
        return candidate
    }

    // MARK: 번들 내 기본 사운드 에셋 조회
    func listBuiltins(subdirectory: String) -> [Asset] {
        let fm = FileManager.default
        let exts = ["wav", "m4a", "mp3", "caf"]
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

            if let asset = makeBuiltinSoundAsset(
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
        let buf = 1 << 20
        guard let stream = InputStream(url: url) else {
            throw NSError(domain: "SoundAssetService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "InputStream open failed"])
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
                throw stream.streamError ?? NSError(domain: "SoundAssetService", code: -2)
            } else { break }
        }
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: Helpers
    
    private func createDirIfNeeded(_ url: URL) throws {
        if !fm.fileExists(atPath: url.path) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    /// 번들 내부의 사운드 파일 URL을 읽어 `Asset` 모델로 변환
    /// - Parameters:
    ///   - src: 번들 내 사운드 파일의 절대 URL
    ///   - rootDirectoryName: 최상위 이미지 에셋 폴더 이름 (예: "BasicSoundAssets")
    /// - Returns: 변환된 `Asset` 객체. 사운드가 아닌 경우 또는 메타 정보 추출 실패 시 `nil`
    private func makeBuiltinSoundAsset(
        from src: URL,
        rootDirectoryName: String
    ) -> Asset? {
        let ok = ["mp3","m4a","wav","aac","caf","aiff","aif","flac"]
        guard ok.contains(src.pathExtension.lowercased()) else { return nil }

        var fileSize = 0
        var createdAt = Date()
        if let rv = try? src.resourceValues(forKeys: [.fileSizeKey, .creationDateKey]) {
            fileSize = rv.fileSize ?? 0
            createdAt = rv.creationDate ?? Date()
        }

        var duration: Double = 0
        if let f = try? AVAudioFile(forReading: src) {
            let sr = f.processingFormat.sampleRate
            duration = sr > 0 ? Double(f.length) / sr : 0
        }

        let channel = inferSoundChannel(from: src, rootDirectoryName: rootDirectoryName)
        let h = (try? sha256Hex(url: src)) ?? UUID().uuidString
        let displayName = src.deletingPathExtension().lastPathComponent

        return Asset(
            id: h,
            type: .sound,
            filename: displayName,
            filesize: fileSize,
            url: src,
            createdAt: createdAt,
            image: nil,
            sound: SoundAsset(
                origin: .basic,
                channel: channel,
                duration: duration,
                waveform: []
            )
        )
    }
    
    /// 번들 기본 사운드의 폴더 구조를 기반으로 사운드 채널(SoundChannel)을 추론
    /// `rootDirectoryName` 이후의 첫 번째 하위 폴더명을 읽어 ambient / foley 등을 자동으로 매핑
    /// 폴더 구조 예:
    /// - BasicSoundAssets/Ambient/xxx.m4a  → .ambient
    /// - BasicSoundAssets/Foley/yyy.wav    → .foley
    ///
    /// - Parameters:
    ///   - url: 사운드 파일의 절대 URL
    ///   - rootDirectoryName: 에셋의 루트 폴더 이름 (예: "BasicSoundAssets")
    /// - Returns: 추론된 `SoundChannel` 값 (예: `.ambient`, `.foley`)
    private func inferSoundChannel(
        from url: URL,
        rootDirectoryName: String
    ) -> SoundChannel {
        let components = url.pathComponents

        guard let rootIndex = components.firstIndex(of: rootDirectoryName),
              components.count > rootIndex + 1 else {
            return .ambient
        }

        let folderName = components[rootIndex + 1].lowercased()

        switch folderName {
        case "ambient", "bgm", "backgrounds":
            return .ambient
        case "foley", "sfx", "effects":
            return .foley
        default:
            return .ambient
        }
    }
}
