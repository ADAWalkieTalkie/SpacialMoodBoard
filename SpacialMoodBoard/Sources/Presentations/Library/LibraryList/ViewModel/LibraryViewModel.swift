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
    
    private let appModel: AppModel
    @ObservationIgnored
    private let assetRepository: AssetRepositoryInterface
    private let renameAssetUseCase: RenameAssetUseCase
    private let deleteAssetUseCase: DeleteAssetUseCase
    
    @ObservationIgnored
    private var token: UUID?
    var projectName: String { assetRepository.project }
    var assets: [Asset] = []
    
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
    
    // MARK: - Init
    
    /// Init
    /// - Parameter projectName: 작업할 프로젝트 이름 (프로젝트 루트 디렉터리 식별에 사용)
    /// - Parameter assetRepository: AssetRepositoryInterface
    init(
        appModel: AppModel,
        assetRepository: AssetRepositoryInterface,
        renameAssetUseCase: RenameAssetUseCase,
        deleteAssetUseCase: DeleteAssetUseCase
    ) {
        self.appModel = appModel
        self.assetRepository = assetRepository
        self.renameAssetUseCase = renameAssetUseCase
        self.deleteAssetUseCase = deleteAssetUseCase

        self.token = assetRepository.addChangeHandler { [weak self] in
            guard let self else { return }
            self.assets = assetRepository.assets
        }
    }
//    deinit { if let token { assetRepository.removeChangeHandler(token) } }
    
    // MARK: - Methods
    
    func loadAssets() async {
        await assetRepository.reload()
        syncFromRepo()
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
    
    func appendItem(with url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            _ = try await assetRepository.addImageData(data, filename: url.lastPathComponent)
            syncFromRepo()
        } catch {
            print("⚠️ appendItem failed: \(error)")
        }
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
                _ = try await assetRepository.addSoundData(data, filename: url.lastPathComponent)
            } catch {
                print("사운드 임포트 실패(\(url.lastPathComponent)): \(error)")
            }
        }
        syncFromRepo()
    }
    
    private func syncFromRepo() {
        let all = assetRepository.assets
        self.assets = all.sorted { $0.createdAt > $1.createdAt }
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
        let filtered = assets
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
    /// 에셋 이름을 변경하고(필요 시 assetId 변경 포함), 씬 내 참조를 일괄 리맵하는 액션
    /// 내부적으로 `RenameAssetUseCase`를 호출해
    /// 1) `AssetRepository.renameAsset`로 에셋 이름을 변경하고
    /// 2) id가 바뀐 경우 `SceneObjectRepository.remapAssetId`로 씬의 참조를 원자적으로 갱신
    /// 완료 후 `syncFromRepo()`로 에셋 패널 등 UI를 동기화
    /// - Parameters:
    ///   - id: 이름을 변경할 에셋의 식별자
    ///   - newTitle: 변경할 새 기본 파일명(확장자는 서비스가 유지/결정)
    /// - Note: `appModel.selectedScene`이 존재할 때만 동작
    @MainActor
    func renameAsset(id: String, to newTitle: String) {
        guard var scene = appModel.selectedScene else { return }
        do {
            _ = try renameAssetUseCase.execute(
                assetId: id,
                newBaseName: newTitle,
                scene: &scene
            )
            syncFromRepo()
        } catch {
            print("❌ rename failed:", error)
        }
    }
    
    /// 에셋을 목록과 디스크에서 함께 삭제
    /// - Parameter id: 삭제할 에셋의 식별자(UUID)
    func deleteAsset(id: String) {
        guard var scene = appModel.selectedScene else {
            do {
                _ = try assetRepository.deleteAsset(id: id)
                syncFromRepo()
            } catch {
                print("❌ Failed to delete asset:", error)
            }
            return
        }
        
        do {
            _ = try deleteAssetUseCase.execute(assetId: id, scene: &scene)
            appModel.selectedScene = scene
            syncFromRepo()
        } catch {
            print("❌ Failed to delete asset:", error)
        }
    }
}
