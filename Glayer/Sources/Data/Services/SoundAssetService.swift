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
        let bundle = Bundle.main
        let fm = FileManager.default
        
        if let dirURL = bundle.url(forResource: subdirectory, withExtension: nil),
           let urls = try? fm.contentsOfDirectory(
            at: dirURL,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
            options: [.skipsHiddenFiles]
           ) {
            return urls.compactMap { makeBuiltinAsset(from: $0) }
        }
        
        let all = bundle.urls(forResourcesWithExtension: nil, subdirectory: nil) ?? []
        let filtered = all.filter { $0.path.contains("/\(subdirectory)/") || $0.path.hasSuffix("/\(subdirectory)") }
        if !filtered.isEmpty { return filtered.compactMap { makeBuiltinAsset(from: $0) } }
        
        let fallback = all.filter {
            let n = $0.deletingPathExtension().lastPathComponent.lowercased()
            return n.hasPrefix("ambient_") || n.hasPrefix("foley_") || n.hasPrefix("amb_") || n.hasPrefix("fol_")
        }
        return fallback.compactMap { makeBuiltinAsset(from: $0) }
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
    
    private func makeBuiltinAsset(from src: URL) -> Asset? {
        let ok = ["", "mp3","m4a","wav","aac","caf","aiff","aif","flac"]
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
        
        let baseName = src.deletingPathExtension().lastPathComponent
        let channel = inferChannel(from: baseName)
        
        let h = (try? sha256Hex(url: src)) ?? UUID().uuidString
        
        return Asset(
            id: h,
            type: .sound,
            filename: stripBuiltinPrefix(from: src.lastPathComponent),
            filesize: fileSize,
            url: src,
            createdAt: createdAt,
            image: nil,
            sound: SoundAsset(origin: .basic, channel: channel, duration: duration, waveform: [])
        )
    }
    
    private func inferChannel(from baseName: String) -> SoundChannel {
        let prefix = baseName.split(whereSeparator: { $0 == "_" || $0 == "-" || $0 == " " })
            .first?.lowercased() ?? ""
        switch prefix {
        case "ambient", "amb", "bgm": return .ambient
        case "foley", "fol", "sfx":  return .foley
        default:                      return .ambient
        }
    }
    
    private func stripBuiltinPrefix(from base: String) -> String {
        let seps = CharacterSet(charactersIn: "_- ")
        let prefixes: Set<String> = ["ambient","amb","foley","fol","sfx","bgm"]
        let tokens = base.split(whereSeparator: { ch in
            guard let u = ch.unicodeScalars.first else { return false }
            return seps.contains(u)
        })
        guard let first = tokens.first?.lowercased(),
              prefixes.contains(first)
        else { return base }

        if let rng = base.rangeOfCharacter(from: seps) {
            let trimmed = base[rng.upperBound...].trimmingCharacters(in: seps)
            return trimmed.isEmpty ? base : String(trimmed)
        }
        return base
    }
}
