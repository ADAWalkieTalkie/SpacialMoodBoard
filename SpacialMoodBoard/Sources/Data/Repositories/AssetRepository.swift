//
//  AssetRepository.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/24/25.
//

//
//  AssetRepository.swift
//  SpacialMoodBoard
//
//  Created by you on 2025/10/23.
//

import Foundation
import UIKit
import AVFoundation



// MARK: - Implementation

@MainActor
final class AssetRepository: AssetRepositoryInterface {
    private(set) var project: String
    private let imageService: ImageAssetServiceProtocol
    private let soundService: SoundAssetServiceProtocol
    private let waveformProvider: WaveformProviderProtocol
    
    // 인메모리 캐시
    private(set) var assets: [Asset] = []
    
    /// assetId → Set<SceneObject.id>
    private var references: [String: Set<UUID>] = [:]
    
    private var observers: [UUID: () -> Void] = [:]
    @discardableResult
    func addChangeHandler(_ f: @escaping () -> Void) -> UUID { let id = UUID(); observers[id] = f; return id }
    func removeChangeHandler(_ id: UUID) { observers[id] = nil }
    private func notify() { observers.values.forEach { $0() } }
    
    init(project: String,
         imageService: ImageAssetServiceProtocol,
         soundService: SoundAssetServiceProtocol,
         waveformProvider: WaveformProviderProtocol)
    {
        self.project = project
        self.imageService = imageService
        self.soundService = soundService
        self.waveformProvider = waveformProvider
    }
    
    convenience init(project: String,
                     imageService: ImageAssetServiceProtocol,
                     soundService: SoundAssetServiceProtocol)
    {
        self.init(project: project,
                  imageService: imageService,
                  soundService: soundService,
                  waveformProvider: WaveformProvider())
    }
    
    func switchProject(to new: String) async {
        guard project != new else { return }
        project = new
        assets = []
        notify()
        await reload()
    }
    
    // MARK: - Load
    
    func reload() async {
        var loaded: [Asset] = []
        
        // 1) 이미지
        let imageNames = (try? imageService.list(project: project)) ?? []
        for name in imageNames {
            let url = imageService.url(project: project, filename: name)
            let meta = imageService.meta(for: url)
            let contentHash = (try? imageService.sha256Hex(url: url)) ?? UUID().uuidString
            let id = Self.composeId(contentHash: contentHash, filename: name)
            loaded.append(
                Asset(id: id, type: .image, filename: name, filesize: meta.fileSize,
                      url: url, createdAt: meta.createdAt,
                      image: ImageAsset(width: meta.pixelWidth, height: meta.pixelHeight),
                      sound: nil)
            )
        }
        
        // 2) 사운드(일단 파형 비움)
        let soundNames = (try? soundService.list(project: project)) ?? []
        for name in soundNames {
            let url = soundService.url(project: project, filename: name)
            let meta = soundService.meta(for: url)
            let contentHash = (try? soundService.sha256Hex(url: url)) ?? UUID().uuidString
            let id = Self.composeId(contentHash: contentHash, filename: name)
            loaded.append(
                Asset(id: id, type: .sound, filename: name, filesize: meta.fileSize,
                      url: url, createdAt: meta.createdAt,
                      image: nil,
                      sound: SoundAsset(channel: .ambient, duration: meta.duration, waveform: []))
            )
        }
        
        loaded.sort { $0.createdAt > $1.createdAt }
        self.assets = loaded
        await fillWaveformsIfNeeded()
        notify()
    }
    
    // MARK: - Query
    
    func asset(withId id: String) -> Asset? { assets.first { $0.id == id } }
    func assets(of type: AssetType) -> [Asset] { assets.filter { $0.type == type } }
    
    // MARK: - Create / Add
    
#if canImport(UIKit)
    func addImage(_ image: UIImage, filename: String) async throws -> Asset {
        let (base, _) = Self.splitFilename(filename, defaultExt: "png")
        let newFilename = imageService.uniqueFilename(project: project, base: base, ext: "png")
        try imageService.save(image, project: project, filename: newFilename)
        notify()
        return try addImageByURL(filename: newFilename)
    }
#endif
    
    func addImageData(_ data: Data, filename: String) async throws -> Asset {
        let (base, _) = Self.splitFilename(filename, defaultExt: "png")
        let newFilename = imageService.uniqueFilename(project: project, base: base, ext: "png")
        try imageService.save(data, project: project, filename: newFilename)
        notify()
        return try addImageByURL(filename: newFilename)
    }
    
    func addSoundData(_ data: Data, filename: String) async throws -> Asset {
        let (base, _) = Self.splitFilename(filename, defaultExt: "m4a")
        let newFilename = soundService.uniqueFilename(project: project, base: base, ext: "m4a")
        try soundService.save(data, project: project, filename: newFilename)

        let url = soundService.url(project: project, filename: newFilename)
        let meta = soundService.meta(for: url)
        let h = try soundService.sha256Hex(url: url)
        let id = Self.composeId(contentHash: h, filename: newFilename)
        
        let wf = await waveformProvider.waveform(url: url, targetSamples: 120, method: .peak)

        let asset = Asset(
            id: id, type: .sound, filename: newFilename, filesize: meta.fileSize,
            url: url, createdAt: meta.createdAt,
            image: nil,
            sound: SoundAsset(channel: .ambient, duration: meta.duration, waveform: wf)
        )

        assets.insert(asset, at: 0)
        notify()
        return asset
    }

    private func addImageByURL(filename: String) throws -> Asset {
        let url = imageService.url(project: project, filename: filename)
        let meta = imageService.meta(for: url)
        let h = try imageService.sha256Hex(url: url)
        let id = Self.composeId(contentHash: h, filename: filename)
        let asset = Asset(
            id: id, type: .image, filename: filename, filesize: meta.fileSize,
            url: url, createdAt: meta.createdAt,
            image: ImageAsset(width: meta.pixelWidth, height: meta.pixelHeight),
            sound: nil
        )
        assets.insert(asset, at: 0)
        notify()
        return asset
    }
    
    // MARK: - Rename / Duplicate / Delete
    
    func renameAsset(id: String, to newBaseName: String) throws -> Asset {
        guard let idx = assets.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "AssetRepo", code: 404, userInfo: [NSLocalizedDescriptionKey: "Asset not found"])
        }
        let old = assets[idx]

        let ext = old.url.pathExtension.isEmpty
            ? (old.type == .image ? "png" : "m4a")
            : old.url.pathExtension

        let base = Self.sanitizedBase(newBaseName)
        let newFilename: String
        switch old.type {
        case .image:
            newFilename = imageService.uniqueFilename(project: project, base: base, ext: ext)
            try imageService.rename(project: project, from: old.filename, to: newFilename)
            let newURL = imageService.url(project: project, filename: newFilename)
            let h = try imageService.sha256Hex(url: newURL)
            assets[idx].filename = newFilename
            assets[idx].url = newURL
            assets[idx].id = Self.composeId(contentHash: h, filename: newFilename)

        case .sound:
            newFilename = soundService.uniqueFilename(project: project, base: base, ext: ext)
            try soundService.rename(project: project, from: old.filename, to: newFilename)
            let newURL = soundService.url(project: project, filename: newFilename)
            let h = try soundService.sha256Hex(url: newURL)
            assets[idx].filename = newFilename
            assets[idx].url = newURL
            assets[idx].id = Self.composeId(contentHash: h, filename: newFilename)
        }

        notify()
        return assets[idx]
    }
    
    func duplicateAsset(id: String, as newBaseName: String?) async throws -> Asset {
        guard let src = asset(withId: id) else { throw NSError(domain: "AssetRepo", code: -10) }
        let ext = src.url.pathExtension.isEmpty
        ? (src.type == .image ? "png" : "m4a")
        : src.url.pathExtension
        
        let base = Self.sanitizedBase(newBaseName?.isEmpty == false ? newBaseName! : "Copy")
        let newFilename: String
        switch src.type {
        case .image:
            newFilename = imageService.uniqueFilename(project: project, base: base, ext: ext)
            try imageService.copy(project: project, from: src.filename, to: newFilename)
            let url = imageService.url(project: project, filename: newFilename)
            let meta = imageService.meta(for: url)
            let h = try imageService.sha256Hex(url: url)
            let id = Self.composeId(contentHash: h, filename: newFilename)
            let dup = Asset(id: id, type: .image, filename: newFilename, filesize: meta.fileSize,
                            url: url, createdAt: Date(),
                            image: ImageAsset(width: meta.pixelWidth, height: meta.pixelHeight),
                            sound: nil)
            assets.insert(dup, at: 0)
            notify()
            return dup
            
        case .sound:
            newFilename = soundService.uniqueFilename(project: project, base: base, ext: ext)
            try soundService.copy(project: project, from: src.filename, to: newFilename)
            let url = soundService.url(project: project, filename: newFilename)
            let meta = soundService.meta(for: url)
            let h = try soundService.sha256Hex(url: url)
            let id = Self.composeId(contentHash: h, filename: newFilename)
            
            let wf = await waveformProvider.waveform(url: url, targetSamples: 120, method: .peak)
            
            let dup = Asset(
                id: id, type: .sound, filename: newFilename, filesize: meta.fileSize,
                url: url, createdAt: Date(),
                image: nil,
                sound: SoundAsset(channel: .ambient, duration: meta.duration, waveform: wf)
            )
            assets.insert(dup, at: 0)
            notify()
            return dup
        }
    }
    
    func deleteAsset(id: String) {
        guard let idx = assets.firstIndex(where: { $0.id == id }) else { return }
        do {
            let target = assets[idx]
            
            switch target.type {
            case .image:
                try imageService.delete(project: project, filename: target.filename)
            case .sound:
                try soundService.delete(project: project, filename: target.filename)
            }
            assets.remove(at: idx)
            notify()
        } catch {
            print("⚠️ disk delete failed:", error)
        }
    }
    
    // MARK: - Helpers
    
    /// "콘텐츠해시@파일명" 형태의 안정적 식별자
    private static func composeId(contentHash: String, filename: String) -> String {
        "\(contentHash)@\(filename)"
    }
    
    static func splitFilename(_ filename: String, defaultExt: String) -> (base: String, ext: String) {
        let url = URL(fileURLWithPath: filename)
        let rawBase = url.deletingPathExtension().lastPathComponent
        let rawExt  = url.pathExtension
        let base = Self.sanitizedBase(rawBase)
        let ext  = (rawExt.isEmpty ? defaultExt : rawExt).lowercased()
        return (base, ext)
    }
    
    private static func sanitizedBase(_ base: String) -> String {
        sanitizedFilename(base).replacingOccurrences(of: ".", with: "_")
    }
    
    private static func sanitizedFilename(_ name: String) -> String {
        let bad = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let cleaned = name.components(separatedBy: bad).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Untitled" : cleaned
    }
    
    private func fillWaveformsIfNeeded() async {
        let targets = assets.filter { $0.type == .sound && ($0.sound?.waveform.isEmpty ?? true) }
        
        await withTaskGroup(of: (String, [Float])?.self) { group in
            for a in targets {
                let id = a.id
                let url = a.url
                group.addTask(priority: .utility) { [waveformProvider] in
                    let wf = await waveformProvider.waveform(url: url, targetSamples: 120, method: .peak)
                    return (id, wf)
                }
            }
            
            for await pair in group {
                guard let (id, wf) = pair else { continue }
                await MainActor.run {
                    if let idx = self.assets.firstIndex(where: { $0.id == id }) {
                        var item = self.assets[idx]
                        if var sound = item.sound {
                            sound.waveform = wf
                            item.sound = sound
                        }
                        self.assets[idx] = item
                    }
                }
            }
        }
    }}
