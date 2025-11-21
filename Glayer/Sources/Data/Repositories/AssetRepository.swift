//
//  AssetRepository.swift
//  Glayer
//
//  Created by jeongminji on 10/24/25.
//

//
//  AssetRepository.swift
//  Glayer
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
    
    /// BasicSoundAssets/BasicSoundWaveforms.json 에서 [파일명: [Float]] 형태로 미리 계산된 파형을 불러옴
    private lazy var builtinWaveforms: [String: [Float]] = {
        guard let url = Bundle.main.url(
            forResource: "BasicSoundWaveforms",
            withExtension: "json",
            subdirectory: "BasicSoundAssets"
        ) else { return [:] }
        
        do {
            let data = try Data(contentsOf: url)
            let dict = try JSONDecoder().decode([String: [Float]].self, from: data)
            return dict
        } catch { return [:] }
    }()
    
    /// 기본 내장 이미지
    private lazy var builtinImageAssets: [Asset] = {
        var result: [Asset] = []
        let imageBuiltins = imageService.listBuiltins(subdirectory: "BasicImageAssets")
        for a in imageBuiltins {
            result.append(
                Asset(id: a.id, type: .image, filename: a.filename, filesize: a.filesize,
                      url: a.url, createdAt: a.createdAt,
                      image: a.image,
                      sound: nil)
            )
        }
        return result
    }()
    
    /// 기본 내장 사운드 (JSON 안에 미리 계산된 파형이 있으면 그걸 우선 사용, 없으면 원래 a.sound.waveform (보통 빈 배열) )
    private lazy var builtinSoundAssets: [Asset] = {
        var result: [Asset] = []
        let soundBuiltins = soundService.listBuiltins(subdirectory: "BasicSoundAssets")
        
        for a in soundBuiltins {
            var sound = a.sound
            let filename = a.filename
            
                    var candidates: [String] = []
                    candidates.append(filename)
                    candidates.append(a.url.lastPathComponent)
                    
                    if !filename.contains(".") {
                        candidates.append(filename + ".wav")
                        candidates.append(filename + ".m4a")
                    }

                    var applied = false
            for key in candidates {
                if let precomputed = builtinWaveforms[key] {
                    sound?.waveform = precomputed
                    applied = true
                    break
                }
            }

            result.append(
                Asset(
                    id: a.id,
                    type: .sound,
                    filename: filename,
                    filesize: a.filesize,
                    url: a.url,
                    createdAt: a.createdAt,
                    image: nil,
                    sound: sound
                )
            )
        }
        return result
    }()
    
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
        try? await reload()
    }
    
    // MARK: - Load
    
    /// 전체 에셋  로드
    ///
    /// 동작 순서:
    /// 1) 기본 에셋(이미지/사운드)을 점진적으로 로드 시작 (비동기)
    ///    - builtinImageAssets / builtinSoundAssets 배열을 chunk 단위로 assets에 추가하고 즉시 UI 업데이트
    /// 2) 유저 에셋을 디스크에서 모두 읽어와 메모리에 구성
    ///    2-1) 유저 이미지 파일들 로드
    ///    2-2) 유저 사운드 파일들 로드 (waveform은 비워둠 → 나중에 fillWaveformsIfNeeded에서 계산)
    /// 3) 유저 에셋을 한 번에 assets에 추가하고 정렬 후 notify()
    /// 4) (비동기) 유저 에셋 + 이미 로딩된 일부 기본 에셋에 대해 빈 파형을 채우기 시작
    ///    - 기본 사운드는 loadBuiltinSoundsIncrementallyIfNeeded() 완료 후 다시 fillWaveformsIfNeeded()가 호출됨
    func reload() async throws {
        self.assets = []
        notify()
        loadBuiltinImagesIncrementallyIfNeeded()
        loadBuiltinSoundsIncrementallyIfNeeded()
        
        var loadedUser: [Asset] = []
        
        let imageNames = try imageService.list(project: project)
        for name in imageNames {
            let url = imageService.url(project: project, filename: name)
            let meta = imageService.meta(for: url)
            let contentHash = try imageService.sha256Hex(url: url)
            let id = Self.composeId(contentHash: contentHash, filename: name)
            
            loadedUser.append(
                Asset(
                    id: id,
                    type: .image,
                    filename: name,
                    filesize: meta.fileSize,
                    url: url,
                    createdAt: meta.createdAt,
                    image: ImageAsset(
                        origin: .user,
                        channel: nil,
                        width: meta.pixelWidth,
                        height: meta.pixelHeight
                    ),
                    sound: nil
                )
            )
        }
        
        let soundNames = try soundService.list(project: project)
        for name in soundNames {
            let url = soundService.url(project: project, filename: name)
            let meta = soundService.meta(for: url)
            let contentHash = try soundService.sha256Hex(url: url)
            let id = Self.composeId(contentHash: contentHash, filename: name)
            
            loadedUser.append(
                Asset(
                    id: id,
                    type: .sound,
                    filename: name,
                    filesize: meta.fileSize,
                    url: url,
                    createdAt: meta.createdAt,
                    image: nil,
                    sound: SoundAsset(
                        origin: .user,
                        channel: .ambient,
                        duration: meta.duration,
                        waveform: []
                    )
                )
            )
        }
        
        self.assets.append(contentsOf: loadedUser)
        self.assets.sort { $0.createdAt > $1.createdAt }
        notify()

        Task { [weak self] in
            await self?.fillWaveformsIfNeeded()
        }
    }
    
    /// 기본 이미지 에셋을 chunk 단위로 점진적으로 assets에 추가
    ///
    /// 동작:
    /// - builtinImageAssets는 lazy 생성되어 한 번만 디스크 스캔됨
    /// - reload()가 호출될 때마다, 기본 이미지들을 다시 chunk 단위로 붙여서 UI 즉시 업데이트
    /// - 이미지에는 별도의 추가 후처리(파형 등)가 필요 없으므로 append만 수행
    private func loadBuiltinImagesIncrementallyIfNeeded() {
        guard !builtinImageAssets.isEmpty else { return }
        
        Task { [weak self] in
            guard let self else { return }
            
            let chunkSize = 8
            var index = 0
            
            while index < self.builtinImageAssets.count {
                let end = min(index + chunkSize, self.builtinImageAssets.count)
                let chunk = Array(self.builtinImageAssets[index..<end])
                
                await MainActor.run {
                    let existingIds = Set(self.assets.map { $0.id })
                    let filtered = chunk.filter { !existingIds.contains($0.id) }

                    self.assets.append(contentsOf: filtered)
                    self.assets.sort { $0.createdAt > $1.createdAt }
                    self.notify()
                }
                
                index = end
            }
        }
    }
    
    /// 기본 사운드 에셋을 chunk 단위로 점진적으로 assets에 추가
    ///
    /// 동작:
    /// - builtinSoundAssets는 lazy 생성되어 앱 실행 중 단 한 번만 파일 스캔 수행
    /// - preload된 JSON 파형이 있으면 이미 sound.waveform이 채워져 있음
    /// - JSON에 없는 기본 사운드는 waveform == [] 상태로 들어옴
    /// - 모든 기본 사운드 chunk 로딩이 끝난 뒤, 아직 waveform == [] 인 기본 사운드들에 대해 fillWaveformsIfNeeded()를 한 번 더 수행
    private func loadBuiltinSoundsIncrementallyIfNeeded() {
        guard !builtinSoundAssets.isEmpty else { return }
        
        Task { [weak self] in
            guard let self else { return }
            
            let chunkSize = 4
            var index = 0
            
            while index < self.builtinSoundAssets.count {
                let end = min(index + chunkSize, self.builtinSoundAssets.count)
                let chunk = Array(self.builtinSoundAssets[index..<end])
                
                await MainActor.run {
                    let existingIds = Set(self.assets.map { $0.id })
                    let filtered = chunk.filter { !existingIds.contains($0.id) }

                    self.assets.append(contentsOf: filtered)
                    self.assets.sort { $0.createdAt > $1.createdAt }
                    self.notify()
                }
                
                index = end
            }
            await self.fillWaveformsIfNeeded()
        }
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
            sound: SoundAsset(origin: .user, channel: .ambient, duration: meta.duration, waveform: wf)
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
            image: ImageAsset(origin: .user, channel: nil, width: meta.pixelWidth, height: meta.pixelHeight),
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
                            image: ImageAsset(origin: .user, channel: nil, width: meta.pixelWidth, height: meta.pixelHeight),
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
                sound: SoundAsset(origin: .user, channel: .ambient, duration: meta.duration, waveform: wf)
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
    
    // MARK: - Waveform Filling
    
    /// 주어진 사운드 에셋들에 대해 파형을 계산하고, assets에 반영
    private func fillWaveformsIfNeeded() async {
        let targets = assets.filter { asset in
            guard asset.type == .sound, let sound = asset.sound else { return false }
            return sound.waveform.isEmpty
        }
        
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
        notify()
    }
}
