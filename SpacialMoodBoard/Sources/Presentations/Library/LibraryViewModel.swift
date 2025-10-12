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

@MainActor
@Observable
final class LibraryViewModel {
    var items: [Asset] = []
        var searchText = ""
        var layout: LibraryItemLayout = .card
        var showSearch = false
        var showDropDock = false

        var editorImages: [UIImage] = []
        var showEditor = false

    // MARK: - Intents

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        // 1) UIImage 직접
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
                guard let self, let img = obj as? UIImage else { return }
                Task { await self.presentEditor(with: [img]) }
            }
            return true
        }

        // 2) 바이너리
        let types = [UTType.image.identifier, UTType.png.identifier, UTType.jpeg.identifier, UTType.heic.identifier]
        if let t = types.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) {
            provider.loadDataRepresentation(forTypeIdentifier: t) { [weak self] data, _ in
                guard let self, let data, let img = UIImage(data: data) else { return }
                Task { await self.presentEditor(with: [img]) }
            }
            return true
        }

        // 3) URL(file/http)
        let urlTypes = [UTType.fileURL.identifier, UTType.url.identifier]
        if let t = urlTypes.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) {
            provider.loadItem(forTypeIdentifier: t, options: nil) { [weak self] item, _ in
                guard let self else { return }
                if let url = item as? URL,
                   let data = try? Data(contentsOf: url),
                   let img = UIImage(data: data) {
                    Task { await self.presentEditor(with: [img]) }
                }
            }
            return true
        }
        return false
    }

    func importFromPhotos(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        var imgs: [UIImage] = []
        for it in items {
            if let data = try? await it.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                imgs.append(img)
            }
        }
        if !imgs.isEmpty { await presentEditor(with: imgs) }
    }

    func presentEditor(with images: [UIImage]) async {
        editorImages = images
        showDropDock = false
        showEditor = true
    }
    
    func appendItem(with url: URL) {
        let now = Date()
        items.insert(
            Asset(id: UUID(), type: .image, filename: url.lastPathComponent,
                  mime: "image/png", filesize: 0, url: url, createdAt: now,
                  image: ImageAsset(width: 0, height: 0)),
            at: 0
        )
    }
}
