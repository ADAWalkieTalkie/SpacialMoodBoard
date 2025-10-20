//
//  ImageEditorViewModel.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/12/25.
//

import SwiftUI
import UniformTypeIdentifiers
import Observation

@Observable
final class ImageEditorViewModel {

    // MARK: - Properties
    var images: [UIImage]
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
    init(images: [UIImage], onAddToLibrary: @escaping ([URL]) -> Void) {
        self.images = images
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
        guard let img = selectedImage,
              let url = exportPNG(img) else { return }
        onAddToLibrary([url])
        addedURLs.append(url)
        showSavedAlert = true
    }

    /// 드롭된 아이템 처리
    func handleDropToAdd(providers: [NSItemProvider]) -> Bool {
        var handled = false
        let imageUTIs = [UTType.png.identifier, UTType.jpeg.identifier,
                         UTType.heic.identifier, UTType.image.identifier]

        for provider in providers {
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { obj, _ in
                    if let img = obj as? UIImage, let url = self.exportPNG(img) {
                        DispatchQueue.main.async {
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
                    guard let data, let img = UIImage(data: data),
                          let url = self.exportPNG(img) else { return }
                    DispatchQueue.main.async {
                        self.onAddToLibrary([url])
                        self.addedURLs.append(url)
                        self.showSavedAlert = true
                    }
                }
                handled = true
            }
        }
        return handled
    }

    // MARK: - Helpers
    private func exportPNG(_ image: UIImage) -> URL? {
        let filename = UUID().uuidString + ".png"
        do {
            let dir = try FileManager.default.url(for: .cachesDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
            let url = dir.appendingPathComponent(filename)
            if let data = image.pngData() {
                try data.write(to: url, options: .atomic)
                return url
            }
        } catch { }
        return nil
    }
}
