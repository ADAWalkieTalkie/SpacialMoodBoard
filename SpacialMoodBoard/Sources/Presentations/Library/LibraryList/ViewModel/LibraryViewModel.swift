//
//  LibraryViewModel.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/12/25.
//

import SwiftUI
import PhotosUI

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
    private let importUseCase: ImportUseCase
    
    @ObservationIgnored
    private var token: UUID?
    var projectName: String { assetRepository.project }
    var assets: [Asset] = []
    
    var searchText = ""
    var assetType: AssetType = .image {
        didSet {
            if assetType != .image, showDropDock {
                showDropDock = false
            }
        }
    }
    var sort: SortOrder = .recent
    var showSearch: Bool = false {
        didSet {
            if showSearch == false, !searchText.isEmpty {
                searchText = ""
            }
        }
    }

    var showDropDock = false
    var showFileImporter = false
    var editorImages: [UIImage] = []
    var editorPreferredNames: [String?] = []
    var showEditor = false
    
    // MARK: - Init
    
    /// Init
    /// - Parameters:
    ///   - appModel: 전역 앱 상태를 보유하는 `AppModel`
    ///   - assetRepository: 에셋(이미지/사운드)의 영속화를 담당하는 저장소
    ///   - renameAssetUseCase: 에셋 이름 변경(및 참조 리맵)을 수행하는 유즈케이스
    ///   - deleteAssetUseCase: 에셋 삭제(및 참조 정리)를 수행하는 유즈케이스

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
        self.importUseCase = ImportUseCase(assetRepository: assetRepository)
        
        self.token = assetRepository.addChangeHandler { [weak self] in
            guard let self else { return }
            self.assets = assetRepository.assets
        }
    }
    
    // MARK: - Methods
    
    func loadAssets() async {
        await assetRepository.reload()
        syncFromRepo()
    }
    
    private func syncFromRepo() {
        let all = assetRepository.assets
        self.assets = all.sorted { $0.createdAt > $1.createdAt }
    }
}

// MARK: - 정렬, 검색어 관련

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
                $0.filename.localizedCompare($1.filename) == .orderedAscending
            }
        }
    }
}

// MARK: - DropDockOverlayView 관련

extension LibraryViewModel {
    /// 드래그&드롭으로 전달된 아이템들을 임포트 요청으로 실행
    /// - Parameter providers: 드롭된 `NSItemProvider` 배열
    /// - Returns: 드롭 제스처 수락 여부. 항상 `true`를 반환합니다(비동기 임포트 시작 의미)
    @discardableResult
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        Task {
            editorPreferredNames = await collectNamesForProviders(providers)
            await runImport(kind: assetType, source: .dragDrop(providers: providers))
        }
        return true
    }
    
    /// PhotosPicker에서 선택된 항목들을 임포트 요청으로 실행
    /// - Parameter items: 사용자가 선택한 `PhotosPickerItem` 목록(최대 10개로 잘라 처리)
    func importFromPhotos(_ items: [PhotosPickerItem]) {
        editorPreferredNames = collectNamesForPhotos(items)
        Task { await runImport(kind: .image, source: .photosPicker(items: items, limit: 10)) }
    }
    
    /// 클립보드의 현재 내용을 임포트 요청으로 실행
    /// 이미지/사운드는 현재 탭(`assetType`)에 따라 분기
    func importFromClipboard() {
        editorPreferredNames = collectNamesForClipboard()
        Task { await runImport(kind: assetType, source: .clipboard) }
    }
    
    /// 파일 선택기로 고른 파일 URL들을 임포트 요청으로 실행
    /// - Parameter urls: 사용자가 선택한 파일 URL 배열
    func importFromFileUrls(_ urls: [URL]) {
        editorPreferredNames = collectNamesForFileURLs(urls)
        Task { await runImport(kind: assetType, source: .fileUrls(urls)) }
    }
    
    /// 임포트 요청을 생성하고 유즈케이스를 호출한 뒤, 결과에 따라 후처리
    /// - Parameters:
    ///   - kind: 임포트 대상 종류(.image / .sound). 보통 현재 탭 상태를 반영
    ///   - source: 임포트 소스(드래그드롭/포토피커/클립보드/파일URL)
    private func runImport(kind: AssetType, source: ImportRequest.Source) async {
        let request = ImportRequest(
            kind: kind,
            source: source,
            projectName: projectName,
            limit: 10
        )
        do {
            let result = try await importUseCase.execute(request)
            switch result {
            case .images(let images):
                let names = Array(editorPreferredNames.prefix(images.count))
                let padded = names + Array(repeating: nil, count: max(0, images.count - names.count))
                
                await presentEditor(with: images, preferredNames: padded)
            case .soundsSaved:
                syncFromRepo()
            }
        } catch {
            print("Import failed:", error)
        }
    }
}

// MARK: - RenamePopoverView 관련

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

// MARK: - ImageEditorView 관련

extension LibraryViewModel {
    /// 수집된 이미지들을 에디터에 전달하고 에디터를 표시
    /// - Parameter images: 에디터에서 편집할 `UIImage` 배열
    /// - Parameter preferredNames: 저장할때 사용할 원본 파일 이름 `String?` 배경
    func presentEditor(with images: [UIImage], preferredNames: [String?]) async {
        editorImages = images
        editorPreferredNames = preferredNames
        showDropDock = false
        showEditor = true
    }
}

// MARK: - 파일이름 관련

extension LibraryViewModel {
    // 드래그&드롭: provider별 원본 파일명 추출
    func collectNamesForProviders(_ providers: [NSItemProvider]) async -> [String?] {
        var out: [String?] = []
        out.reserveCapacity(providers.count)

        for p in providers {
            // 1) suggestedName
            if let n = p.suggestedName, !n.isEmpty { out.append(n); continue }

            // 2) loadFileRepresentation로 실제 tmp 파일명 확보
            if let id = p.registeredTypeIdentifiers.first {
                let name: String? = await withCheckedContinuation { cont in
                    p.loadFileRepresentation(forTypeIdentifier: id) { url, _ in
                        cont.resume(returning: url?.lastPathComponent)
                    }
                }
                out.append(name)
                continue
            }

            out.append(nil)
        }
        return out
    }

    // PhotosPicker: PHAssetResource로 원본 파일명
    func collectNamesForPhotos(_ items: [PhotosPickerItem]) -> [String?] {
        var names: [String?] = Array(repeating: nil, count: items.count)
        for (i, it) in items.enumerated() {
            if let id = it.itemIdentifier,
               let a = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject,
               let res = PHAssetResource.assetResources(for: a).first {
                names[i] = res.originalFilename   // 예: IMG_1234.HEIC
            }
        }
        return names
    }

    // 파일 URL들: 그대로 파일명
    func collectNamesForFileURLs(_ urls: [URL]) -> [String?] {
        urls.map { $0.lastPathComponent }
    }

    // 클립보드: URL이면 파일명, 아니면 nil
    func collectNamesForClipboard() -> [String?] {
        if let u = UIPasteboard.general.url { return [u.lastPathComponent] }
        return [nil]
    }
}
