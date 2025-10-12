//
//  LibraryView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/9/25.
//

import SwiftUI
import PhotosUI

struct LibraryView: View {
    @State private var vm = LibraryViewModel() 
    @State private var photoSelection: [PhotosPickerItem] = []

    var body: some View {
        VStack(spacing: 8) {
            headerView

            if vm.showSearch {
                CenteredVisionSearchBar(text: $vm.searchText)
            }

            ScrollView {
                switch vm.layout {
                case .card:
                    let columns = [GridItem(.adaptive(minimum: 220, maximum: 272), spacing: 32)]
                    LazyVGrid(columns: columns, spacing: 36) {
                        ForEach(filteredItems) { asset in
                            LibraryItemView(
                                imageURL: asset.type == .image ? asset.url : nil,
                                title: asset.filename,
                                description: LibraryView.format(asset.createdAt),
                                layout: .card
                            )
                            .frame(width: 220, height: 272)
                        }
                    }

                case .row:
                    LazyVStack(spacing: 12) {
                        ForEach(filteredItems) { asset in
                            LibraryItemView(
                                imageURL: asset.type == .image ? asset.url : nil,
                                title: asset.filename,
                                description: LibraryView.format(asset.createdAt),
                                layout: .row
                            )
                            .frame(height: 90)
                        }
                    }
                }
            }
            .padding(.horizontal, 26)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            if vm.showDropDock {
                DropDockOverlayView(
                    isPresented: $vm.showDropDock,
                    onDropProviders: vm.handleDrop(providers:)
                )
                .transition(.topRightSlide(260))
            }
        }
        .photosPicker(isPresented: .constant(false), selection: $photoSelection, maxSelectionCount: 20, matching: .images)
        .onChange(of: photoSelection) { _, newValue in
            Task { await vm.importFromPhotos(newValue); photoSelection.removeAll() }
        }
        .fullScreenCover(isPresented: $vm.showEditor) {
            ImageImportEditor(images: vm.editorImages) { urls in
                for u in urls { vm.appendItem(with: u) }
            }
        }
        .padding(.bottom, 20)
        .glassBackgroundEffect()
        .task { loadSeedDataIfNeeded() }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center) {
            HStack(spacing: 16) {
                toolButton(system: "square.grid.2x2") { vm.layout = .card }
                    .opacity(vm.layout == .card ? 1 : 0.5)
                toolButton(system: "line.3.horizontal") { vm.layout = .row }
                    .opacity(vm.layout == .row ? 1 : 0.5)
            }
            Spacer()
            Text("라이브러리").font(.system(size: 29, weight: .bold))
            Spacer()
            HStack(spacing: 16) {
                toolButton(system: "arrow.down.to.line") { vm.showDropDock.toggle() }
                PhotosPicker(selection: $photoSelection, maxSelectionCount: 20, matching: .images) {
                    Image(systemName: "plus").font(.system(size: 19, weight: .medium))
                        .frame(width: 44, height: 44)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)

                toolButton(system: "magnifyingglass") { vm.showSearch.toggle() }
            }
        }
        .padding(24)
    }

    @ViewBuilder
    private func toolButton(system name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 19, weight: .medium))
                .frame(width: 44, height: 44)
                .background(.thinMaterial, in: Circle())
                .hoverEffect(.highlight)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filter
    private var filteredItems: [Asset] {
        let key = vm.searchText.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return vm.items }
        return vm.items.filter {
            $0.filename.localizedCaseInsensitiveContains(key) ||
            ($0.mime ?? "").localizedCaseInsensitiveContains(key)
        }
    }

    // 더미 데이터 채우기
    private func loadSeedDataIfNeeded() {
        guard vm.items.isEmpty else { return }
        let now = Date()
        let imgURL = URL(string: "https://i.ibb.co/0yhHJbfK/image-23.png")!
        vm.items = [
            Asset(id: UUID(), type: .image, filename: "astronaut.png",
                  mime: "image/png", filesize: 512_000, url: imgURL,
                  createdAt: now, image: ImageAsset(width: 1024, height: 1267)),
            Asset(id: UUID(), type: .image, filename: "astronaut-2.png",
                  mime: "image/png", filesize: 490_000, url: imgURL,
                  createdAt: now.addingTimeInterval(-3600), image: ImageAsset(width: 1024, height: 1267)),
            Asset(id: UUID(), type: .sound, filename: "background-music.mp3",
                  mime: "audio/mpeg", filesize: 3_100_000,
                  url: URL(string: "https://example.com/audio/background-music.mp3")!,
                  createdAt: now.addingTimeInterval(-7200), image: nil)
        ]
    }

    private static func format(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = .autoupdatingCurrent
        df.amSymbol = "AM"; df.pmSymbol = "PM"
        df.dateFormat = "yyyy.M.d a h:mm"
        return df.string(from: date)
    }
}


// MARK: - Preview

#Preview(windowStyle: .plain) {
    LibraryView()
}
