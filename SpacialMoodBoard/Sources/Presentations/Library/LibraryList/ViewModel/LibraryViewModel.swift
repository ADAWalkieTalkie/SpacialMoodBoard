//
//  LibraryViewModel.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/12/25.
//

import SwiftUI
import Observation
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

@MainActor
@Observable
final class LibraryViewModel {
    
    // MARK: - Properties
    
    let projectName: String
    
    var items: [Asset] = []
    var searchText = ""
    var assetType: AssetType = .image
    var sort: SortOrder = .recent
    var showSearch: Bool = false {
        didSet {
            if showSearch == false, !searchText.isEmpty {
                searchText = ""
            }
        }
    }
    var showDropDock = false
    var showSoundImporter = false
    
    var editorImages: [UIImage] = []
    var showEditor = false
    
    private let imageStore = ImageFileStorage()
    private let soundStore = SoundFileStorage()
    
    // MARK: - Init
    
    /// Init
    /// - Parameter projectName: 작업할 프로젝트 이름 (프로젝트 루트 디렉터리 식별에 사용)
    init(projectName: String) {
        self.projectName = projectName
    }
    
    // MARK: - Methods
    
    /// 프로젝트 디렉터리에서 이미지/사운드 파일을 불러와 `items`를 구성
    /// - Note: 파일 메타데이터(생성일, 파일크기)를 읽어 `Asset`을 만들고, 사운드는 길이/파형도 생성
    func loadAssets() async {
        let imgs = (try? imageStore.listImages(projectName: projectName)) ?? []
        let snds = (try? soundStore.listSounds(projectName: projectName)) ?? []
        
        var loaded: [Asset] = []
        loaded.reserveCapacity(imgs.count + snds.count)
        
        for name in imgs {
            let url = FilePathProvider.imageFile(projectName: projectName, filename: name)
            let meta = (try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey, .contentTypeKey])) ?? .init()
            
            loaded.append(
                Asset(id: UUID(),
                      type: .image,
                      filename: name,
                      filesize: meta.fileSize ?? 0,
                      url: url,
                      createdAt: meta.creationDate ?? Date(),
                      image: ImageAsset(width: 0, height: 0))
            )
        }
        
        for name in snds {
            let url = FilePathProvider.soundFile(projectName: projectName, filename: name)
            let meta = (try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey, .contentTypeKey])) ?? .init()
            
            let f = try? AVAudioFile(forReading: url)
            let duration = f.map { Double($0.length) / $0.processingFormat.sampleRate } ?? 0
            let waveform = (try? makeWaveform(url: url, targetSamples: 120, method: .peak)) ?? []
            
            loaded.append(
                Asset(id: UUID(),
                      type: .sound,
                      filename: name,
                      filesize: meta.fileSize ?? 0,
                      url: url,
                      createdAt: meta.creationDate ?? Date(),
                      image: nil,
                      sound: SoundAsset(channel: .ambient, duration: duration, waveform: waveform))
            )
        }
        
        loaded.sort { $0.createdAt > $1.createdAt }
        items = loaded
    }
    
    /// 드래그 앤 드롭으로 전달된 아이템들을 처리한다. 즉시 `true`를 반환하고 내부에서 비동기로 로딩
    /// - Parameter providers: 드롭된 `NSItemProvider`들
    /// - Returns: 항상 `true`(드롭 수락). 실제 로딩은 비동기로 진행
    @discardableResult
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        Task { await importFromProviders(providers) }
        return true
    }
    
    /// 여러 Provider에서 이미지들을 배열로 모아 한 번에 에디터로 전달한다.
    /// - Parameter providers: 최대 10개까지 처리할 `NSItemProvider` 배열
    private func importFromProviders(_ providers: [NSItemProvider]) async {
        let limited = Array(providers.prefix(10))
        var images: [UIImage] = []
        images.reserveCapacity(limited.count)
        
        for p in limited {
            if p.canLoadObject(ofClass: UIImage.self) {
                if let img = await loadUIImage(provider: p) {
                    images.append(img); continue
                }
            }
            
            let imageUTIs: [String] = [
                UTType.image.identifier,
                UTType.png.identifier,
                UTType.jpeg.identifier,
                UTType.heic.identifier
            ]
            if let t = imageUTIs.first(where: { p.hasItemConformingToTypeIdentifier($0) }),
               let data = await loadData(provider: p, typeIdentifier: t),
               let img = UIImage(data: data) {
                images.append(img); continue
            }
            
            let urlUTIs: [String] = [UTType.fileURL.identifier, UTType.url.identifier]
            if let t = urlUTIs.first(where: { p.hasItemConformingToTypeIdentifier($0) }),
               let any = await loadItem(provider: p, typeIdentifier: t),
               let url = any as? URL,
               let data = try? Data(contentsOf: url),
               let img = UIImage(data: data) {
                images.append(img); continue
            }
        }
        
        guard !images.isEmpty else { return }
        await presentEditor(with: images)
    }
    
    // MARK: - Editor
    
    /// 수집된 이미지들을 에디터에 전달하고 에디터를 표시.
    /// - Parameter images: 에디터에서 편집할 이미지 배열
    func presentEditor(with images: [UIImage]) async {
        editorImages = images
        showDropDock = false
        showEditor = true
    }
    
    /// 에디터 저장 결과(생성된 파일 URL)를 라이브러리 목록 맨 앞에 추가
    /// - Parameter url: 저장된 이미지 파일 URL
    func appendItem(with url: URL) {
        let now = Date()
        items.insert(
            Asset(id: UUID(),
                  type: .image,
                  filename: url.lastPathComponent,
                  filesize: 0,
                  url: url,
                  createdAt: now,
                  image: ImageAsset(width: 0, height: 0)),
            at: 0
        )
    }
    
    // MARK: - Provider loaders (async helpers)
    
    /// `NSItemProvider`에서 `UIImage`를 비동기로 로드
    /// - Parameter provider: 로드할 프로바이더
    /// - Returns: 로드 성공 시 이미지, 실패 시 `nil`
    private func loadUIImage(provider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { cont in
            provider.loadObject(ofClass: UIImage.self) { obj, _ in
                cont.resume(returning: obj as? UIImage)
            }
        }
    }
    
    /// `NSItemProvider`에서 특정 UTI 타입의 `Data`를 비동기로 로드
    /// - Parameters:
    ///   - provider: 로드할 프로바이더
    ///   - typeIdentifier: 예) `UTType.png.identifier`
    /// - Returns: 데이터 로드 성공 시 `Data`, 실패 시 `nil`
    private func loadData(provider: NSItemProvider, typeIdentifier: String) async -> Data? {
        await withCheckedContinuation { cont in
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, _ in
                cont.resume(returning: data)
            }
        }
    }
    
    /// `NSItemProvider`에서 특정 UTI 타입의 아이템을 비동기로 로드
    /// - Parameters:
    ///   - provider: 로드할 프로바이더
    ///   - typeIdentifier: 예) `UTType.fileURL.identifier`
    /// - Returns: 로드된 아이템(`NSSecureCoding`), 실패 시 `nil`
    private func loadItem(provider: NSItemProvider, typeIdentifier: String) async -> NSSecureCoding? {
        await withCheckedContinuation { cont in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                cont.resume(returning: item)
            }
        }
    }
    
    /// 파일 피커에서 고른 사운드 파일들을 프로젝트 /sounds 에 **원본 그대로** 저장하고, 목록에 추가
    /// - Parameter urls: [URL]
    func importSoundFiles(urls: [URL]) async {
        guard !urls.isEmpty else { return }
        
        for url in urls {
            let needsSecurity = url.startAccessingSecurityScopedResource()
            defer { if needsSecurity { url.stopAccessingSecurityScopedResource() } }
            
            do {
                let data = try Data(contentsOf: url)
                let filename = url.lastPathComponent
                
                try soundStore.save(data, projectName: projectName, filename: filename)

                let dest = FilePathProvider.soundFile(projectName: projectName, filename: filename)

                let meta = try? dest.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
                let avf  = try? AVAudioFile(forReading: dest)
                let duration = avf.map { Double($0.length) / $0.processingFormat.sampleRate } ?? 0
                let waveform = (try? makeWaveform(url: dest, targetSamples: 120, method: .peak)) ?? []
                
                let asset = Asset(
                    id: UUID(),
                    type: .sound,
                    filename: filename,
                    filesize: meta?.fileSize ?? 0,
                    url: dest,
                    createdAt: meta?.creationDate ?? Date(),
                    image: nil,
                    sound: SoundAsset(channel: .ambient, duration: duration, waveform: waveform)
                )
                items.insert(asset, at: 0)
            } catch {
                print("사운드 임포트 실패(\(url.lastPathComponent)): \(error)")
            }
        }
    }
}

// MARK: - Extension sort

extension LibraryViewModel {
    /// 검색어와 타입으로 목록을 필터링한 뒤, 현재 정렬 옵션(`sort`)에 따라 정렬된 배열을 반환
    /// - Parameters:
    ///   - type: 필터링할 에셋 타입(.image / .sound)
    ///   - key: 파일명에 대해 부분 일치 검색에 사용할 키워드(공백/빈 문자열이면 전체)
    /// - Returns: 필터링 + 정렬이 적용된 `Asset` 배열
    func filteredAndSorted(type: AssetType, key: String) -> [Asset] {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = items
            .filter { $0.type == type }
            .filter { trimmed.isEmpty ? true : $0.filename.localizedCaseInsensitiveContains(trimmed) }
        return sortAssets(filtered)
    }
    
    /// 주어진 에셋 배열을 뷰모델의 정렬 상태(`sort`)에 맞춰 정렬
    /// - Parameter assets: 정렬 대상 에셋 배열
    /// - Returns: 정렬 결과 배열
    /// - Note:
    ///   - `.recent`: 생성일 내림차순(최신 우선), 동일한 생성일은 파일명 오름차순으로 타이브레이크
    ///   - `.nameAZ`: 파일명 오름차순(`localizedStandardCompare`) 정렬
    func sortAssets(_ assets: [Asset]) -> [Asset] {
        switch sort {
        case .recent:
            return assets.sorted {
                if $0.createdAt == $1.createdAt { return $0.filename < $1.filename }
                return $0.createdAt > $1.createdAt
            }
        case .nameAZ:
            return assets.sorted {
                $0.filename.localizedStandardCompare($1.filename) == .orderedAscending
            }
        }
    }
}

// MARK: - Extension RenamePopover

extension LibraryViewModel {
    /// 에셋 파일명을 변경하고, 디스크 상의 실제 파일도 함께 rename
    /// - Parameters:
    ///   - id: 이름을 바꿀 에셋의 식별자(UUID)
    ///   - newTitle: 확장자를 제외한 새 파일명(사용자 입력). 불법 문자는 `sanitizedFilename(_:)`로 정제
    func renameAsset(id: UUID, to newTitle: String) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        let asset = items[i]
        
        let ext = asset.url.pathExtension.isEmpty
        ? (asset.type == .image ? "jpg" : "m4a")
        : asset.url.pathExtension
        
        let base = sanitizedFilename(newTitle)
        let newFilename = base + "." + ext
        
        do {
            let srcURL = asset.url
            let dstURL = (asset.type == .image)
            ? FilePathProvider.imageFile(projectName: projectName, filename: newFilename)
            : FilePathProvider.soundFile(projectName: projectName, filename: newFilename)
            
            if srcURL == dstURL { return }
            
            let finalURL = try uniqueURLIfNeeded(dstURL)
            try FileManager.default.moveItem(at: srcURL, to: finalURL)
            
            items[i].filename = finalURL.lastPathComponent
            items[i].url = finalURL
            
        } catch {
            print("⚠️ rename failed:", error)
        }
    }
    
    /// 에셋을 목록과 디스크에서 함께 삭제
    /// - Parameter id: 삭제할 에셋의 식별자(UUID)
    func deleteAsset(id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        let asset = items.remove(at: i)
        
        do {
            switch asset.type {
            case .image:
                try imageStore.delete(projectName: projectName, filename: asset.filename)
            case .sound:
                try soundStore.delete(projectName: projectName, filename: asset.filename)
            }
        } catch {
            print("⚠️ delete failed:", error)
        }
    }
    
    /// 에셋을 복제하여 새 파일명으로 저장하고, 목록에 추가
    /// - Parameters:
    ///   - id: 복제할 원본 에셋의 식별자(UUID)
    ///   - newTitle: 새 파일명(확장자 제외). 비어 있으면 "Copy"를 기본 사용
    func duplicateAsset(id: UUID, as newTitle: String) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        let src = items[i]
        
        let ext = src.url.pathExtension
        let base = sanitizedFilename(newTitle)
        var dstFilename = base.isEmpty ? "Copy" : base
        if !ext.isEmpty { dstFilename += ".\(ext)" }
        
        do {
            let dstURL = (src.type == .image)
            ? FilePathProvider.imageFile(projectName: projectName, filename: dstFilename)
            : FilePathProvider.soundFile(projectName: projectName, filename: dstFilename)
            
            let finalURL = try uniqueURLIfNeeded(dstURL)
            try FileManager.default.copyItem(at: src.url, to: finalURL)
            
            var dup = src
            dup.id = UUID()
            dup.filename = finalURL.lastPathComponent
            dup.url = finalURL
            dup.createdAt = Date()
            
            if dup.type == .sound {
                if let f = try? AVAudioFile(forReading: finalURL) {
                    dup.sound?.duration = Double(f.length) / f.processingFormat.sampleRate
                }
                dup.sound?.waveform = (try? makeWaveform(url: finalURL, targetSamples: 120, method: .peak)) ?? []
            }
            
            items.insert(dup, at: 0)
            
        } catch {
            print("⚠️ duplicate failed:", error)
        }
    }
    
    /// 사용자 입력 파일명에서 파일 시스템에 부적합한 문자를 제거/치환하고 앞뒤 공백 정리
    /// - Parameter s: 원본 파일명 텍스트
    /// - Returns: 정제된 파일명(비어 있으면 `"Untitled"` 반환)
    private func sanitizedFilename(_ s: String) -> String {
        let bad = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let cleaned = s.components(separatedBy: bad).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Untitled" : cleaned
    }
    
    /// 지정한 URL 경로가 이미 존재할 경우, 뒤에 번호를 붙여 고유한 URL을 만들어 반환
    /// - Parameter url: 희망하는 대상 경로
    /// - Returns: 충돌이 없으면 원본 `url`, 충돌이 있으면 `-1`, `-2`…가 붙은 새 URL
    /// - Throws: 내부 반복 한도를 초과하거나 파일 시스템 오류가 발생하면 에러
    private func uniqueURLIfNeeded(_ url: URL) throws -> URL {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return url }
        
        let noExt = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        let dir = url.deletingLastPathComponent()
        
        var n = 1
        while true {
            let candidate = dir.appendingPathComponent("\(noExt)-\(n)\(ext.isEmpty ? "" : ".\(ext)")")
            if !fm.fileExists(atPath: candidate.path) { return candidate }
            n += 1
            if n > 10_000 { throw NSError(domain: "UniqueURL", code: -1) }
        }
    }
}
