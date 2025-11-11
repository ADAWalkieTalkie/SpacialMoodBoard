//
//  ImageEditorViewModel.swift
//  Glayer
//
//  Created by jeongminji on 10/12/25.
//

import SwiftUI
import UniformTypeIdentifiers
import Observation

@Observable
final class ImageEditorViewModel {
    
    // MARK: - Properties
    private let assetRepository: AssetRepositoryInterface
    
    var images: [UIImage]
    private var preferredNames: [String?]
    private var onAddToLibrary: (_ exported: [URL]) -> Void
    
    // 사이드바 상태/폭
    var showSidebar: Bool = true
    var sidebarWidth: CGFloat = 320
    let sidebarMinWidth: CGFloat = 0
    let sidebarMaxWidth: CGFloat = 540
    let sidebarFallbackWidth: CGFloat = 320
    
    // 선택 상태/알림 등
    var selectedIndex: Int = 0
    var showSavedAlert: Bool = false
    var showSaveFailedAlert: Bool = false
    var isAddTargeted: Bool = false
    var showAddedPopover: Bool = false
    private(set) var addedURLs: [URL] = []
    
    var dropTypes: [UTType] { [.image, .png, .jpeg, .heic] }
    var isFirst: Bool { selectedIndex <= 0 }
    var isLast:  Bool { selectedIndex >= max(0, images.count - 1) }
    var selectedImage: UIImage? {
        guard images.indices.contains(selectedIndex) else { return nil }
        return images[selectedIndex]
    }
    
    // MARK: - Init
    init(
        images: [UIImage],
        preferredNames: [String?],
        assetRepository: AssetRepositoryInterface,
        onAddToLibrary: @escaping ([URL]) -> Void
    ) {
        self.images = images
        self.preferredNames = preferredNames
        self.assetRepository = assetRepository
        self.onAddToLibrary = onAddToLibrary
        if !images.isEmpty { selectedIndex = 0 }
    }
    
    // MARK: - Methods
    func prevImage() {
        guard !isFirst else { return }
        withAnimation(.snappy) { selectedIndex -= 1 }
    }
    
    func nextImage() {
        guard !isLast else { return }
        withAnimation(.snappy) { selectedIndex += 1 }
    }
    
    /// 사이드바 열기 시, 폭이 0이면 기본 폭으로 복원
    func willOpenSidebarIfNeeded() {
        if sidebarWidth <= sidebarMinWidth {
            sidebarWidth = sidebarFallbackWidth
        }
    }
    
    /// 사이드바를 즉시 접는다 (폭=0, 표시=false)
    func collapseSidebar() {
        sidebarWidth = 0
        showSidebar = false
    }
    
    /// 현재 선택 이미지를 PNG로 캐시 저장 후 라이브러리에 등록
    func addCurrentToLibrary() {
        guard let img = selectedImage else { return }
        Task { @MainActor in
            if let url = await saveToProject(image: img) {
                onAddToLibrary([url])
                addedURLs.append(url)
                showSavedAlert = true
            } else {
                showSaveFailedAlert = true
            }
        }
    }
    
    /// 드롭된 아이템 처리
    func handleDropToAdd(providers: [NSItemProvider]) -> Bool {
        var handled = false
        let imageUTIs = [UTType.png.identifier, UTType.jpeg.identifier,
                         UTType.heic.identifier, UTType.image.identifier]
        
        for provider in providers {
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { obj, _ in
                    guard let img = obj as? UIImage else { return }
                    Task { @MainActor in
                        if let url = await self.saveToProject(image: img) {
                            self.onAddToLibrary([url])
                            self.addedURLs.append(url)
                            self.showSavedAlert = true
                        }
                    }
                }
                handled = true
                continue
            }
            
            if let t = imageUTIs.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) {
                provider.loadDataRepresentation(forTypeIdentifier: t) { data, _ in
                    guard let data, let img = UIImage(data: data) else { return }
                    Task { @MainActor in
                        if let url = await self.saveToProject(image: img) {
                            self.onAddToLibrary([url])
                            self.addedURLs.append(url)
                            self.showSavedAlert = true
                        }
                    }
                }
                handled = true
            }
        }
        return handled
    }
    
    /// 편집 중인 이미지를 현재 프로젝트의 `/images` 폴더에 png로 저장하고, 저장된 파일의 URL을 반환합니다.
    /// - Parameter image: 저장할 `UIImage`.
    /// - Returns: 저장에 성공하면 `Documents/projects/<projectName>/images/<uuid>.jpg`의 파일 URL, 실패 시 `nil`
    private func saveToProject(image: UIImage) async -> URL? {
        do {
            let raw = (preferredNames.indices.contains(selectedIndex) ? preferredNames[selectedIndex] : nil)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let base = (raw?.isEmpty == false ? raw! : "Image")
            let filename = URL(fileURLWithPath: base).deletingPathExtension().lastPathComponent
            
            let asset = try await assetRepository.addImage(image, filename: filename)
            return asset.url
        } catch {
            print("🖼️ 이미지 저장 실패: \(error)")
            return nil
        }
    }
}
